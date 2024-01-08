// SPDX-License-Identifier: CC-BY-NC-ND-4.0

pragma solidity ^0.8.10;
pragma abicoder v2;

import "./INANftStandard.sol";

// @dev This should be used for an exhibition contract where have multiple artists under a single contract.
interface INA721ExhibitionStandard is INANftStandard {

    // ---
    // Functions
    // ---

    function mint(address artistAddress, string memory metadataUri) external returns (uint256 tokenId);
    function artistMint(string memory metadataUri) external returns (uint256 tokenId);
    function updateMetadataUri(uint256 tokenId, string memory metadataUri) external;
}
