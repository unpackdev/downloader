// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev NFT registry interface
 */
interface INFTRegistry {

    /**
     * Get token data for a given tokenID
     */
    function getToken(uint tokenId) external view returns (address, string memory, uint256, uint);
}