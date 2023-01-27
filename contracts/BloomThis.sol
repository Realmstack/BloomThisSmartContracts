// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";


contract BloomThis is ERC721, Ownable, ERC2981 {

    mapping(address=> uint8) public _admins;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenCounter;
    bool public _transferable;
    address[] public _adminList;

    uint256 public _maxTokens;
    mapping(uint256 => string) public _tokenURIs;
    mapping(address => uint256[]) private _userTokens;
    mapping(uint256=> uint256) private _tokenIndex;
    mapping(uint256=> uint8) private _kind;
    mapping(uint8 => string[]) private _tokenUrlReserve;
    mapping(uint8 => uint8[]) _rules;

    mapping(address => uint256) public _perTokenCumulativeRewardForUser;
    uint256 public _perTokenCumulativeReward;
    uint256 public _pendingReward;
    uint256 public _ethBalance;

    function receiveETH() payable public {
        require(msg.value > 0, "Cannot receive 0 ETH.");
        _ethBalance += msg.value;
        _pendingReward += msg.value;
    }

    receive() payable external {
        receiveETH();
    }


    constructor (string memory name, string memory symbol, bool transferable, uint256 maxTokens) ERC721 (name, symbol) payable {
        _admins[msg.sender] = 1;
        _maxTokens = maxTokens;
        _transferable = transferable;
        _adminList.push(msg.sender);
    }

    function contractURI() public pure returns (string memory) {
        return "https://to-be-provided-later.com";
    }

    modifier validAdmin() {
        require(_admins[msg.sender] == 1, "You are not authorized.");
        _;
    }

    // Add or remove admin from admin list
    function modifyAdmin(address adminAddress, bool add) validAdmin public {
        if(add) {
            _admins[adminAddress] = 1;
            _adminList.push(adminAddress);
        } else {
            require(adminAddress != msg.sender, "Cant remove self as admin");
            delete _admins[adminAddress];
            for(uint256 i = 0; i < _adminList.length; i++) {
                if(_adminList[i] == adminAddress) {
                    _adminList[i] = _adminList[_adminList.length - 1];
                    _adminList.pop();
                    break;
                }
            }
        }
    }

    // total supply of tokens
    function totalSupply() public view returns (uint256) {
        return _tokenCounter.current();
    }

    //only admin can mint NFT for a receiver. he has to provice token url and kind
    function mint(address receiver, string memory tokenURL, uint8 kind) validAdmin public returns (uint256) {
        return mintTo(receiver, tokenURL, kind);
    }

    //Used to mint NFT for a receiver. he has to provice token url and kind
    function mintTo(address receiver, string memory tokenURL, uint8 kind) private returns (uint256) {
        if(_maxTokens > 0) {
            require(_maxTokens > _tokenCounter.current(), "Tokens exhausted");
        }

        _tokenCounter.increment();
        uint256 newItemId = _tokenCounter.current();
        _safeMint(receiver, newItemId);
        _tokenURIs[newItemId] = tokenURL;
        _kind[newItemId] = kind;

        _userTokens[receiver].push(newItemId);
        _tokenIndex[newItemId] = _userTokens[receiver].length - 1;
        return newItemId;
    }

    //burns a token, called by internal functions
    function burn(uint _tokenId, address owner) private {
        super._burn(_tokenId);

        _userTokens[owner][_tokenIndex[_tokenId]] = _userTokens[owner][_userTokens[owner].length -1];
        _tokenIndex[_userTokens[owner][_tokenIndex[_tokenId]]] = _tokenIndex[_tokenId];
        _userTokens[owner].pop();
    }

    // returns token uri
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId > 0 && tokenId <= _tokenCounter.current(), "Invalid token id");
        return _tokenURIs[tokenId];
    }

    function getKind(uint256 tokenId) public view returns (uint8) {
        require(tokenId > 0 && tokenId <= _tokenCounter.current(), "Invalid token id");
        return _kind[tokenId];
    }

    // internal function handles user token list, when it is transferred to another user.
    function transferToken(address _from, address _to, uint256 _tokenId) private {
        require(_transferable, "Transfer not allowed");
        issueRewards(_from);
        issueRewards(_to);

        //delete token entry from previous user 
        _userTokens[_from][_tokenIndex[_tokenId]] = _userTokens[_from][_userTokens[_from].length -1];
        _tokenIndex[_userTokens[_from][_tokenIndex[_tokenId]]] = _tokenIndex[_tokenId];
        _userTokens[_from].pop();

        //add token to index of new user
        _userTokens[_to].push(_tokenId);
        _tokenIndex[_tokenId] = _userTokens[_to].length - 1;
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) override public {
        super.transferFrom(_from, _to, _tokenId);

        transferToken(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) override public {
        super.safeTransferFrom(_from, _to, _tokenId);
        transferToken(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) override public {
        super.safeTransferFrom(_from, _to, _tokenId, data);
        transferToken(_from, _to, _tokenId);
    }

    //utility function provide all the tokens owned by an user
    function userTokens(address user) public view returns(uint256[] memory) {
        return _userTokens[user];
    }

    //utitily function for admin to check if he has add enough fusion token uri(s) added or not
    function getFusionUrisBalance(uint8 kind) public validAdmin view returns(uint256) {
        return _tokenUrlReserve[kind].length;
    }

    //utitily function for admin to add fusion token uri
    function addFusionUris(uint8 kind, string[] memory uris) public validAdmin {
        for(uint8 i = 1; i < uris.length ; i++) {
            _tokenUrlReserve[kind].push(uris[i]);
        }
    }

    //utility function for admin to add fusion rule. where user may provide multiple token to smart contract and its burned by the contract and issues a new fusion token.
    function addFusionRule(uint8 ruleNo, uint8[] memory rule) public validAdmin {
        require(ruleNo > 0, "Invalid rule No");
        if(rule.length > 0) {
            _rules[ruleNo] = rule;
        } else {
            delete _rules[ruleNo];
        }
    }

    // function called by user with token ids he owns, this will burn those provided tokens and issue a new fusion token
    function doFusion(uint8 ruleNo, uint8[] memory ids) public {
        require(_rules[ruleNo].length > 0, "Invalid rule No");

        for(uint8 kind = 1; kind < _rules[ruleNo].length ; kind++) {
            uint8 total = 0;
            for(uint8 idx = 0; idx < ids.length ; idx++) {
                if(kind == _kind[ids[idx]]) {
                    total++;
                }
            }
            require(total == _rules[ruleNo][kind], "Invalid no of tokens provided.");
        }

        for(uint8 i = 0; i < ids.length ; i++) {
            require(ownerOf(ids[i]) == msg.sender, "Invalid owner");
            burn(ids[i], msg.sender);
        }

        require(_tokenUrlReserve[_rules[ruleNo][0]].length > 0, "Fusion Token data not available");
        string memory uri = _tokenUrlReserve[_rules[ruleNo][0]][_tokenUrlReserve[_rules[ruleNo][0]].length - 1];
        _tokenUrlReserve[_rules[ruleNo][0]].pop();
        mintTo(msg.sender, uri, _rules[ruleNo][0]);
    }


    



    // every time a token is sold in secendary market, some royalty fee is collected in this same contract. It is then equally distributed amoung existing token owners.
    function claimRewards() public {
        issueRewards(msg.sender);
    }

    // every time a token is sold in secendary market, some royalty fee is collected in this same contract. It is then equally distributed amoung existing token owners.
    function issueRewards(address user) private {
        if(_pendingReward > 0) {
            _perTokenCumulativeReward += _pendingReward / totalSupply();
            _pendingReward = 0;
        }

        if(_perTokenCumulativeRewardForUser[user] < _perTokenCumulativeReward) {
            uint256 reward = (_perTokenCumulativeReward - _perTokenCumulativeRewardForUser[user]) * _userTokens[user].length ;
            if(reward <= address(this).balance) {
                payable(user).transfer(reward);
            }
            _perTokenCumulativeRewardForUser[user] = _perTokenCumulativeReward;
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public validAdmin {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }
}