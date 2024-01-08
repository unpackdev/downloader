// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract MenschMachine is ERC721, Ownable {
    
    struct Drop {
        uint256 blockNumber;
        uint256 limit;
        uint256 priceInWei;
    }

    Drop drop;

    constructor (string memory name, string memory symbol) ERC721(name, symbol) { 

    }
    
    // View drop
    function getDrop() external view returns (uint256, uint256, uint256) {
        return (drop.blockNumber, drop.limit, drop.priceInWei);
    }

    // Sets the drop
    function setDrop(uint256 blockNumber, uint256 limit, uint256 priceInWei) public onlyOwner {
        drop = Drop(blockNumber, limit, priceInWei);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    // Buys a MesnchMachine NFT at the specified block number
    function buy(uint256 blockNumber) public payable {
        require(msg.value >= drop.priceInWei);
        require(blockNumber < drop.blockNumber + drop.limit, "Invalid Blocknumber");
        require(blockNumber >= drop.blockNumber, "Invalid Blocknumber");

        _safeMint(msg.sender, blockNumber);
    }

    /// @dev Withdraw function to withdraw the earnings 
    function withdrawBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal view override virtual returns (string memory) {
        return "https://www.menschmaschine.io/api/track/";
    }
}