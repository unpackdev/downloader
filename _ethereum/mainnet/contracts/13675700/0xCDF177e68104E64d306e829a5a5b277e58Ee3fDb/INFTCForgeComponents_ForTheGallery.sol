// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title INFTCForgeComponents_ForTheGallery
 * @author @NiftyMike, NFT Culture
 * @dev Interface definition for contracts providing forge component lookup capabilities.
 */
interface INFTCForgeComponents_ForTheGallery {
    function getYieldFromMapping(string calldata tokenUri) external view returns (uint256);
}