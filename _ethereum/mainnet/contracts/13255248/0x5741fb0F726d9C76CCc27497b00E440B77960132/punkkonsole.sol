// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
 
import "./ERC721.sol";
 
contract SimpleCollectible is ERC721 {
    uint256 public tokenCounter;
    address public owner;
    constructor () public ERC721 ("PunkKonsole", "PKS"){
        tokenCounter = 0;
        owner = 0x9Df9289E3f08A07e6903290aD96898743ABF8e43;
    }
 
    function createCollectible(string memory tokenURI) public returns (uint256) {
        require(msg.sender == owner, "you are not ownner");
        uint256 newItemId = tokenCounter;
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        tokenCounter = tokenCounter + 1;
        return newItemId;
    }
 
}