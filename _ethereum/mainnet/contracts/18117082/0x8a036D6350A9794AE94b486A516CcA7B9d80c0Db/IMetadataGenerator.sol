// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./IDittoPool.sol";

/**
 * @title IMetadataGenerator
 * @notice Provides a standard interface for interacting with the MetadataGenerator contract 
 *   to return a base64 encoded tokenURI for a given tokenId.
 */
interface IMetadataGenerator {
    /**
     * @notice Called in the tokenURI() function of the LpNft contract.
     * @param lpId_ The identifier for a liquidity position NFT
     * @param pool_ The DittoPool address associated with this liquidity position NFT
     * @param countToken_ Count of all ERC20 tokens assigned to the owner of the liquidity position NFT in the DittoPool
     * @param countNft_ Count of all NFTs assigned to the owner of the liquidity position NFT in the DittoPool
     * @return tokenUri A distinct Uniform Resource Identifier (URI) for a given asset.
     */
    function payloadTokenUri(
        uint256 lpId_,
        IDittoPool pool_,
        uint256 countToken_,
        uint256 countNft_
    ) external view returns (string memory tokenUri);

    /**
     * @notice Called in the contractURI() function of the LpNft contract.
     * @return contractUri A distinct Uniform Resource Identifier (URI) for a given asset.
     */
    function payloadContractUri() external view returns (string memory contractUri);
}
