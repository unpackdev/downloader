// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title Interface for the Hunab Revolution contract.
 */
interface IHunabRevolution {
    /**
     * @dev Mint token to the specified recipient for Hunab.
     * @param to The recipient address
     * @param hunabTokenId The id of the original Hunab token
     * @return tokenId The id of the minted token
     */
    function hunabMint(
        address to,
        uint256 hunabTokenId
    ) external returns (uint256 tokenId);
}
