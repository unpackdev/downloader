// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract DreamNFT is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address[] public whitelists;
    mapping(address => bool) public whitelisted;

    constructor() ERC721("DreamNFT", "DNFT") {
        whitelisted[msg.sender] = true;
        whitelists.push(msg.sender);
    }

    struct Item {
        address minter;
        string uri;
    }

    mapping(uint256 => Item) public Items;

    function createItem(string memory uri) public returns (uint256) {
        require(whitelisted[msg.sender] == true, "Only whitelisted users can create items");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        Items[newItemId] = Item(msg.sender, uri);
        return newItemId;
    }

    function minter(uint256 tokenId)
        public
        view
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: minter query for nonexistent token"
        );
        return Items[tokenId].minter;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return Items[tokenId].uri;
    }
    // add user's address to whitelist
    function addWhitelistUser(address[] memory _user) public onlyOwner {
        for(uint256 idx = 0; idx < _user.length; idx++) {
            require(whitelisted[_user[idx]] == false, "already set");
            whitelisted[_user[idx]] = true;
            whitelists.push(_user[idx]);
        }
    }

    // remove user's address to whitelist
    function removeWhitelistUser(address[] memory _user) public onlyOwner {
        for(uint256 idx = 0; idx < _user.length; idx++) {
            require(whitelisted[_user[idx]] == true, "not exist");
            whitelisted[_user[idx]] = false;
            removeWhitelistByValue(_user[idx]);
        }
    }

    function removeWhitelistByValue(address value) internal{
        uint i = 0;
        while (whitelists[i] != value) {
            i++;
        }
        removeWhitelistByIndex(i);
    }    

    function removeWhitelistByIndex(uint i) internal{
        while (i<whitelists.length-1) {
            whitelists[i] = whitelists[i+1];
            i++;
        }
        whitelists.pop();        
    }

    function updateTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        Items[tokenId].uri = uri;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}