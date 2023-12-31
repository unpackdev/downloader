// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC721Metadata {

    /**
        @notice Updates the base url for metadata.
        @dev Can be invoked only by the contract manager.
        @param _newBaseUrl The new base url.
    */
    function updateBaseUrl(string memory _newBaseUrl) external;

    /**
        @notice Returns a descriptive name for a collection of NFTs in this contract.
        @return _name Representing name.
    */
    function name() external view returns (string memory _name);

    /**
        @notice Returns a abbreviated name for a collection of NFTs in this contract.
        @return _symbol Representing symbol.
    */
    function symbol() external view returns (string memory _symbol);

    /**
        @notice Returns a distinct Uniform Resource Identifier (URI) for a given asset.
            It Throws if `_tokenId` is not a valid NFT.
            URIs are defined in RFC3986.
            The URI may point to a JSON file that conforms to the "ERC721 Metadata JSON Schema".
        @return URI of _tokenId.
    */
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    /*
        @notice Emitted when the base url is updated.
        @param _newBaseUrl The new base url.
    */
    event BaseUrlUpdate(string newBaseUrl);
}
