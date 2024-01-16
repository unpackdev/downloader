// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./Ownable.sol";
import "./console.sol";

import "./ERC721URIStorage.sol";
import "./Counters.sol";

contract MojoShop is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(string memory name, string memory symbol) ERC721(name,symbol) {
        console.log("name", name);
        console.log("symbol", symbol);
        console.log("msg.sender", msg.sender); //msg.sender is the address that initially deploys a contract

    }

    function mintFor(address receiver, string memory tokenURI)
        public
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(receiver, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function mint(address owner, string memory tokenURI) external onlyOwner returns (uint256) {
        _tokenIds.increment();

        uint256 newNftTokenId = _tokenIds.current();
        _mint(owner, newNftTokenId);
        _setTokenURI(newNftTokenId, tokenURI);
        return newNftTokenId;
    }
}


