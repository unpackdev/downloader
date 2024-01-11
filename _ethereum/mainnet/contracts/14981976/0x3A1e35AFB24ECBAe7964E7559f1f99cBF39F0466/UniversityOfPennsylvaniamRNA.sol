// SPDX-License-Identifier: UNLICENSED
// Creator: Cowboy Labs

pragma solidity ^0.8.9;

import "./ERC721A.sol";

error TokenDoesNotExist();

/**
 * @notice Implementation of the University of Pennsylvania mRNA NFT. 
 *
 * The NFT will be sold at auction through Christie's and transferred to the buyer.
 *
 * The contract can only mint one (1) NFT.
 *
 * There are no controls over the contract and no royalties on sale.
 */
contract UniversityOfPennsylvaniamRNA is ERC721A {
    constructor() ERC721A("UniversityOfPennsylvaniamRNA", "mRNA") {
        _mint(msg.sender, 1);
    }

    /**************************\
    *    OVERRIDES & EXTRAS    *
    \**************************/

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if(!_exists(tokenId)) revert TokenDoesNotExist();
        return "https://nft.upenn.edu/innovationinfinance/mrna/mrna_nft.json";
    }
}