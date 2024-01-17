// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Strings.sol";

contract Avator is ERC721URIStorage {
    string baseURI;
    address public owner;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(string memory baseURI_) ERC721("Avator", "Avator") {
        owner = msg.sender;
        baseURI = baseURI_;
        _tokenIds.increment();
    }

    function mint(address player)
        public
        onlyOwner
    {
        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _tokenIds.increment();
    }

    function setBaseURI(string memory baseURI_) external onlyOwner  {
        baseURI = baseURI_;
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        return string.concat(baseURI, Strings.toString(tokenId), ".json");
    }

    function setOwner(address owner_) external onlyOwner {
        owner = owner_;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"NOT_OWNER");
        _;
    }
}