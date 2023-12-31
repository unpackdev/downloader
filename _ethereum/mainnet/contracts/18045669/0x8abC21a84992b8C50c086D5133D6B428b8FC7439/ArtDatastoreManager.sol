// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// Local References
import "./OwnableDeferral.sol";
import "./IDynamicArt.sol";

// Error Codes
error ArtPieceCountExceeded();
error ArtPieceDoesNotExist();
error ArtPieceAlreadyCreated();
error NullTokenType();

/**
 * @title ArtDatastoreManager
 * @author @NiftyMike | @NFTCulture
 * @dev A class for managing the datastore that holds Art pieces as either strings or bytes.
 */
abstract contract ArtDatastoreManager is IDynamicArtV1, OwnableDeferral {
    // Storage for Token Attribute Definitions
    mapping(uint256 => DynamicArtV1) private _artObjects;
    uint64[] private _artPieceTokenTypes;

    uint256 private immutable _maxNumberOfArtPieces;

    constructor(uint256 __maxNumberOfArtPieces) {
        _maxNumberOfArtPieces = __maxNumberOfArtPieces;
    }

    function createArtPieces(
        uint256[] calldata tokenTypes,
        string[] calldata stringAssets,
        string[] calldata backgrounds,
        bytes[] calldata bytesAssets
    ) external isOwner {
        require(
            tokenTypes.length == stringAssets.length &&
                tokenTypes.length == backgrounds.length &&
                tokenTypes.length == bytesAssets.length,
            'Invalid number of assets'
        );

        uint256 idx;
        for (idx = 0; idx < tokenTypes.length; idx++) {
            _createArtPiece(tokenTypes[idx], stringAssets[idx], backgrounds[idx], bytesAssets[idx]);
        }
    }

    function createArtPiece(
        uint256 tokenType,
        string calldata stringAsset,
        string calldata backgroundColor,
        bytes calldata bytesAsset
    ) external isOwner {
        _createArtPiece(tokenType, stringAsset, backgroundColor, bytesAsset);
    }

    function updateArtPiece(
        uint256 tokenType,
        string calldata stringAsset,
        string calldata backgroundColor,
        bytes calldata bytesAsset
    ) external isOwner {
        if (tokenType == 0) revert NullTokenType();
        DynamicArtV1 memory current = _artObjects[tokenType];
        if (current.tokenType == 0) revert ArtPieceDoesNotExist();

        current.tokenType = tokenType;

        if (bytes(stringAsset).length > 0) {
            current.encodedArt = stringAsset;
        }

        if (bytes(backgroundColor).length > 0) {
            current.backgroundColor = backgroundColor;
        }

        if (bytesAsset.length > 0) {
            current.encodedArtBytes = bytesAsset;
        }

        _artObjects[tokenType] = current;
    }

    function _createArtPiece(
        uint256 tokenType,
        string calldata stringAsset,
        string calldata backgroundColor,
        bytes calldata bytesAsset
    ) internal {
        if (tokenType == 0) revert NullTokenType();
        if (_maxNumberOfArtPieces > 0 && _artPieceTokenTypes.length + 1 > _maxNumberOfArtPieces)
            revert ArtPieceCountExceeded();
        if (_artObjects[tokenType].tokenType > 0) revert ArtPieceAlreadyCreated();

        DynamicArtV1 memory current;
        current.tokenType = tokenType;
        current.encodedArt = stringAsset;
        current.backgroundColor = backgroundColor;
        current.encodedArtBytes = bytesAsset;

        _artObjects[tokenType] = current;
        _artPieceTokenTypes.push(uint64(tokenType));
    }

    function getArtObject(uint256 tokenType) external view returns (DynamicArtV1 memory) {
        return _getArtObject(tokenType);
    }

    function _getArtObject(uint256 tokenType) internal view returns (DynamicArtV1 memory) {
        return _artObjects[tokenType];
    }

    function getArtPieceTokenTypes() external view returns (uint64[] memory) {
        return _getArtPieceTokenTypes();
    }

    function _getArtPieceTokenTypes() internal view returns (uint64[] memory) {
        return _artPieceTokenTypes;
    }
}
