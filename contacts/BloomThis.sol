// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BloomThis is ERC721 {

    mapping(address=> uint8) public _admins;
    address[] public _adminList;

    uint256 public tokenCounter;
    uint256 public _maxTokens;
    mapping(uint256 => string) public baseUris;

    constructor () public ERC721 ("Bloom This", "BLUM"){
        tokenCounter = 0;
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

    function createCollectible(address receiver, string memory tokenURI) public returns (uint256) {
        require(_maxTokens > tokenCounter, "Tokens exhausted");
        uint256 newItemId = tokenCounter + 1;
        _safeMint(receiver, newItemId);
        // _setTokenURI(newItemId, tokenURI);
        baseUris[newItemId] = tokenURI;
        tokenCounter = tokenCounter + 1;
        return newItemId;
    }


    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId > 0 && tokenId <= tokenCounter, "Invalid token id");
        return baseUris[tokenId];
    }
}
