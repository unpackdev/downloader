// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibArtwork.sol";

/// @title Interface of TRLab NFT core contract
/// @author Joe
/// @notice This is the interface of TRLab NFT core contract
interface ITRLabCore {
    /// @notice This event emits when a new NFT token has been minted.
    /// @param id uint256 the id of the minted NFT token.
    /// @param owner address the address of the token owner.
    /// @param artworkId uint256 the id of the artwork of this token.
    /// @param printEdition uint32 the print edition of this token.
    /// @param tokenURI string the metadata ipfs URI.
    event ArtworkReleaseCreated(
        uint256 indexed id,
        address indexed owner,
        uint256 indexed artworkId,
        uint32 printEdition,
        string tokenURI
    );

    /// @notice This event emits when a batch of NFT tokens has been minted.
    /// @param artworkId uint256 the id of the artwork of this token.
    /// @param printEdition uint32 the new print edition of this artwork.
    event ArtworkPrintIndexUpdated(uint256 indexed artworkId, uint32 indexed printEdition);

    /// @notice This event emits when an artwork has been burned.
    /// @param artworkId uint256 the id of the burned artwork.
    event ArtworkBurned(uint256 indexed artworkId);

    /// @dev sets the artwork store address.
    /// @param _storeAddress address the address of the artwork store contract.
    function setStoreAddress(address _storeAddress) external;

    /// @dev set the royalty of a token.
    /// @param _tokenId uint256 the id of the token
    /// @param _receiver address the receiver address of the royalty
    /// @param _bps uint256 the royalty percentage in bps
    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint256 _bps
    ) external;

    /// @notice Retrieves the artwork object by id
    /// @param  _artworkId uint256 the address of the creator
    /// @return artwork the artwork object
    function getArtwork(uint256 _artworkId) external view returns (LibArtwork.Artwork memory artwork);

    /// @notice Creates a new artwork object, artwork creator is _msgSender()
    /// @param  _totalSupply uint32 the total allowable prints for this artwork
    /// @param  _metadataPath string the ipfs metadata path
    /// @param  _royaltyReceiver address the royalty receiver
    /// @param  _royaltyBps uint256 the royalty percentage in bps
    function createArtwork(
        uint32 _totalSupply,
        string calldata _metadataPath,
        address _royaltyReceiver,
        uint256 _royaltyBps
    ) external;

    /// @notice Creates a new artwork object and mints it's first release token.
    /// @dev No creations of any kind are allowed when the contract is paused.
    /// @param  _totalSupply uint32 the total allowable prints for this artwork
    /// @param  _metadataPath string the ipfs metadata path
    /// @param  _numReleases uint32 the number of tokens to be minted
    /// @param  _royaltyReceiver address the royalty receiver
    /// @param  _royaltyBps uint256 the royalty percentage in bps
    function createArtworkAndReleases(
        uint32 _totalSupply,
        string calldata _metadataPath,
        uint32 _numReleases,
        address _royaltyReceiver,
        uint256 _royaltyBps
    ) external;

    /// @notice mints tokens of artwork.
    /// @dev No creations of any kind are allowed when the contract is paused.
    /// @param  _artworkId uint256 the id of the artwork
    /// @param  _numReleases uint32 the number of tokens to be minted
    function releaseArtwork(uint256 _artworkId, uint32 _numReleases) external;

    /// @notice mints tokens of artwork in behave of receiver. Designed for buy-now contract.
    /// @dev No creations of any kind are allowed when the contract is paused.
    /// @param  _receiver address the owner of the new nft token.
    /// @param  _artworkId uint256 the id of the artwork.
    /// @param  _numReleases uint32 the number of tokens to be minted.
    function releaseArtworkForReceiver(
        address _receiver,
        uint256 _artworkId,
        uint32 _numReleases
    ) external;

    /// @dev getter function for approvedTokenCreators mapping. Check if caller is approved creator.
    /// @param  caller address the address of caller to check.
    /// @return true if caller is approved creator, otherwise false.
    function approvedTokenCreators(address caller) external returns (bool);
}
