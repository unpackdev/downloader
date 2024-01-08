// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./console.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract NFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    
    uint256 public iterationLimit = 50; // it prevents an error 'out of gas' due to tough transaction

    constructor(string memory name, string memory symbol)  ERC721(name, symbol) {}

    function issueTokens(address holder, uint256 count) external onlyOwner{   
        require(count <= iterationLimit, "NFT: There is a limit of tokens for each transaction, try to issue less");
        require(count > 0 , "NFT: Count of desired tokens should be more than 0");
        for(uint i = 0; i < count; i++){
            safeMint(holder);
        }
    }

    function safeMint(address holder) internal {
        _tokenIdTracker.increment();
        _safeMint(holder, getIdTracker());
    }

    function getIdTracker() public view returns (uint256) {
        return _tokenIdTracker.current();
    }
    
    function burn(uint256 tokenId) external onlyOwner {
        require(ownerOf(tokenId) == owner(), "NFT: to burn this token the owner of this token and the owner of the contract must be the same!");
        _burn(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) external onlyOwner {
        require(ownerOf(tokenId) == owner(), "Ownable: caller is not the owner of this token");
        _setTokenURI(tokenId, tokenURI);
    }
}
