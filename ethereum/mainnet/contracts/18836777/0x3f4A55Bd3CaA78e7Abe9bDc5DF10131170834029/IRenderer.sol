// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title IRenderer
 * @author fx(hash)
 * @notice Interface for FxGenArt721 tokens to interact with renderers
 */
interface IRenderer {
    /*//////////////////////////////////////////////////////////////////////////
                                  FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns address of the FxContractRegistry contract
     */
    function contractRegistry() external view returns (address);

    /**
     * @notice Gets the contact-level metadata for the project
     * @return URI of the contract metadata
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Gets the metadata for a token
     * @param _tokenId ID of the token
     * @param _data Additional data used to construct metadata
     * @return URI of the token metadata
     */
    function tokenURI(uint256 _tokenId, bytes calldata _data) external view returns (string memory);
}
