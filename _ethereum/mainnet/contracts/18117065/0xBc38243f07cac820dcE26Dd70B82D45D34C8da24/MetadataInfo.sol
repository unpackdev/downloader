// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

/**
 * @notice Struct used by MetadataGenerator when generating metadata for an NFT id
 */
struct MetadataInfo {
    string curve;
    address addressPool;
    address addressAdmin;
    string tokenString;
    string feeString;
    uint256 nftCount;
    string symbolNft;
    address addressNft;
    uint256 tokenId;
}


/**
 * @notice struct used by MetadataGenerator for holding external data
 */
struct ExternalCallData {
        address addressAdmin;
        address addressNft;
        uint256 decimals;
        uint256 poolFee;
        string bondingCurve;
        string symbolToken;
        string symbolNft;
}