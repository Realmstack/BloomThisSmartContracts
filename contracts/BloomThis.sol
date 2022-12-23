// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BloomThis is ERC721 {

    mapping(address=> uint8) public _admins;
    address[] public _adminList;

    uint256 public _tokenCounter;
    uint256 public _maxTokens;
    mapping(uint256 => string) public baseUris;
    mapping(address => uint256[]) private _userTokens;
    mapping(uint256=> uint256) private _tokenIndex;

    constructor () ERC721 ("Bloom This", "BLUM"){
        _tokenCounter = 0;
        _admins[msg.sender] = 1;
        _adminList.push(msg.sender);
        _maxTokens = 27;
    }

    modifier validAdmin() {
        require(_admins[msg.sender] == 1, "You are not authorized.");
        _;
    }

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

    function createCollectible(address receiver, string memory tokenURL) public returns (uint256) {
        require(_maxTokens > _tokenCounter, "Tokens exhausted");
        uint256 newItemId = _tokenCounter + 1;
        _safeMint(receiver, newItemId);
        // _setTokenURI(newItemId, tokenURI);
        baseUris[newItemId] = tokenURL;
        _tokenCounter = _tokenCounter + 1;
        _userTokens[receiver].push(newItemId);
        _tokenIndex[newItemId] = _userTokens[receiver].length - 1;
        return newItemId;
    }


    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId > 0 && tokenId <= _tokenCounter, "Invalid token id");
        return baseUris[tokenId];
    }


    function transferFrom(address _from, address _to, uint256 _tokenId) override public {
        super.transferFrom(_from, _to, _tokenId);
        
        //delete token entry from previous user 
        _userTokens[_from][_tokenIndex[_tokenId]] = _userTokens[_from][_userTokens[_from].length -1];
        _tokenIndex[_userTokens[_from][_tokenIndex[_tokenId]]] = _tokenIndex[_tokenId];
        _userTokens[_from].pop();

        //add token to index of new user
        _userTokens[_to].push(_tokenId);
        _tokenIndex[_tokenId] = _userTokens[_to].length - 1;
    }

    function userTokens(address user) public view returns(uint256[] memory) {
        return _userTokens[user];
    }
}
