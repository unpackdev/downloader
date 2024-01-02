/*
https://twitter.com/unyoncapital
https://www.unyon.capital/
*/
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC721.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./UnyToken.sol";

contract UnyNFT is ERC721, Ownable {
    uint256 public tokenCounter;
    UnyToken private unyToken;
    uint256 private constant burnAmount = 1000 * 10**18; 

    constructor(address _unyTokenAddress) ERC721("Unyon NFT", "Uny") Ownable(msg.sender) {
        tokenCounter = 0;
        unyToken = UnyToken(_unyTokenAddress);
    }

    function burnTokensForNFT() public {
        require(tokenCounter < 999, "All NFTs have been minted");
        require(unyToken.balanceOf(msg.sender) >= burnAmount, "Not enough UnyTokens to burn");

       
        unyToken.burnFrom(msg.sender, burnAmount);

        
        _safeMint(msg.sender, tokenCounter);
        tokenCounter++;
    }
}