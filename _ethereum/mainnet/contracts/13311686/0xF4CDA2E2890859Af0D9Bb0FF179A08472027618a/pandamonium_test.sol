/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract PandamoniumTest is ERC721Enumerable, ReentrancyGuard, Ownable {
    
    uint256 public constant MINT_PRICE = 1000000000000000; //0.001 ETH
    
    uint256 public constant MAX_SUPPLY = 8848;
    uint256 public maxMintPerTransaction = 15;

    constructor() ERC721("PandaTest", "PANDA") {
    }

    // @dev Main sale mint
    // @param tokensCount The tokens a user wants to purchase
    function mint(uint256 tokenCount) external nonReentrant payable {
        require(totalSupply() + tokenCount <= MAX_SUPPLY);
        require(tokenCount > 0, "Must mint at least 1 token");
        require(tokenCount <= maxMintPerTransaction, "Token count exceeds limit");
        require((MINT_PRICE * tokenCount) == msg.value, "ETH sent does not match required payment");

        _premint(msg.sender, tokenCount);
    }

    function _premint(address recipient, uint256 tokenCount) private {
        uint256 totalSupply = totalSupply();
        for (uint256 i = 1; i <= tokenCount; i++) {
            uint256 tokenId = totalSupply + i;
            _safeMint(recipient, tokenId);
        }
    }

    function mintOwner(uint256 tokenCount) public nonReentrant onlyOwner {
        require(totalSupply() + tokenCount <= MAX_SUPPLY);
        require(tokenCount > 0, "Must mint at least 1 token");

        _premint(msg.sender, tokenCount);
    }
}