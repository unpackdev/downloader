// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;
pragma abicoder v2;

/// @title IUnifarmNFTDescriptorUpgradeable Interface
/// @author UNIFARM
/// @notice All External functions of Unifarm NFT Manager Descriptor

interface IUnifarmNFTDescriptorUpgradeable {
    /**
     * @notice construct the Token Metadata
     * @param cohortId cohort address
     * @param tokenId NFT Token Id
     * @return base64 encoded Token Metadata
     */
    function generateTokenURI(address cohortId, uint256 tokenId) external view returns (string memory);
}
