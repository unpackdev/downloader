// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibArtwork.sol";

/// @title Interface for artwork data storage
/// @author Joe
/// @notice This is the interface for TRLab NFTs artwork data storage.
/// @dev Separating artwork storage from the TRLabCore contract decouples features.
interface IArtworkStore {
    /// @notice This event emits when a new artwork has been created.
    /// @param artworkId uint256 the id of the new artwork
    /// @param creator address the creator address of the artwork
    /// @param royaltyReceiver address the receiver address of the artwork second sale royalty
    /// @param royaltyBps uint256 the royalty percent in bps
    /// @param totalSupply uint256 the maximum tokens can be minted of this artwork
    /// @param metadataPath the ipfs path of the artwork metadata
    event ArtworkCreated(
        uint256 indexed artworkId,
        address indexed creator,
        address indexed royaltyReceiver,
        uint256 royaltyBps,
        uint256 totalSupply,
        string metadataPath
    );

    /// @notice This event emits when artwork print id increases.
    /// @param artworkId uint256 the id of the new artwork
    /// @param increment uint32 the increment of artwork print index
    /// @param newPrintIndex uint32 the new print index of this artwork
    event ArtworkPrintIndexIncrement(uint256 indexed artworkId, uint32 increment, uint32 newPrintIndex);

    /// @notice Creates a new digital artwork object in storage
    /// @param  _creator address the address of the creator
    /// @param  _totalSupply uint32 the total allowable prints for this artwork
    /// @param  _metadataPath string the ipfs metadata path
    /// @param  _royaltyReceiver address the royalty receiver
    /// @param  _royaltyBps uint256 the royalty percentage in bps
    function createArtwork(
        address _creator,
        uint32 _totalSupply,
        string calldata _metadataPath,
        address _royaltyReceiver,
        uint256 _royaltyBps
    ) external returns (uint256);

    /// @notice Update Artwork Royalty Info, can only be called by owner at emergency
    /// @param  _artworkId id of the artwork
    /// @param  _royaltyReceiver address the royalty receiver
    /// @param  _royaltyBps uint256 the royalty percentage in bps
    function updateArtworkRoyaltyInfo(
        uint256 _artworkId,
        address _royaltyReceiver,
        uint256 _royaltyBps
    ) external;

    /// @notice Update Artwork metadata path (base uri), can only be called by owner at emergency
    /// @param  _artworkId id of the artwork
    /// @param  _metadataPath metadata path (base uri)
    function updateArtworkMetadataPath(uint256 _artworkId, string memory _metadataPath) external;

    /// @notice Increments the current print index of the artwork object, can be triggered by mint or burn.
    /// @param  _artworkId uint256 the id of the artwork
    /// @param  _increment uint32 the amount to increment by
    function incrementArtworkPrintIndex(uint256 _artworkId, uint32 _increment) external;

    /// Retrieves the artwork object by id
    /// @param  _artworkId uint256 the address of the creator
    function getArtwork(uint256 _artworkId) external view returns (LibArtwork.Artwork memory artwork);
}
