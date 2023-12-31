// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Prerelease Contracts
import "./OwnableDeferralResolution.sol";
import "./IChainNativeArtProducer.sol";
import "./IScriptyStorageProvider.sol";
import "./PNGBackedSVGArt.sol";

// Error Codes
error UnrecognizedExtension();

/**
 * @title PixelPioneerArtworkBase
 * @author @NiftyMike | @NFTCulture
 * @dev This contract implements the NFTC IChainNativeArtProducer API, which means
 * it contains logic to return the contents of an NFT image / animation_url field
 * for a given NFT token type.
 *
 * In this particular implementation, the image approach is fully on-chain. The returned
 * value represents a SVG that is base64 encoded. The string representation can be copy
 * and pasted into a new browser tab to display the image.
 *
 * The SVGs constructed by this contract are backed by bitmaps stored as base64 encoded
 * PNG files. The PNG files are via transactions that are sent after the contract is
 * deployed. The maximum base64 string size is about 34KB, and is limited by the max block
 * size of the block chain, which is around 30M gas.
 *
 * In theory, this same exact approach could be used with larger backing PNGs (ignoring
 * cost implications), if the base64 string was chunked across multiple transactions, but
 * we have no need to do that with this project.
 */
abstract contract PixelPioneerArtworkBase is PNGBackedSVGArt, IChainNativeArtProducer, OwnableDeferralResolution {
    string private constant extension_iff = 'iff';
    string private constant extension_pict = 'pct';

    address private _svgRenderer;

    struct ArchivalMetadata {
        address scriptyStorageProvider;
        uint256 tokenType;
        string scriptName;
        string extension;
    }

    // File extension -> tokenType (but zero indexed)
    mapping(string => ArchivalMetadata[]) private _metadata;

    function getArtAsString(uint256 tokenType) external view returns (string memory) {
        // This project returns the SVG data as the art string.
        return _getSvgDataURI(tokenType);
    }

    function getAnimationAsString(uint256) external pure returns (string memory) {
        // This art is not animated.
        return '';
    }

    /**
     * @notice Get the Art Asset for a TokenType as an SVG encoded into a data URI.
     *
     * @param tokenType the token type of the art piece.
     */
    function getSvgArt(uint256 tokenType) external view returns (string memory) {
        return _getSvgDataURI(tokenType);
    }

    /**
     * @notice Get the Art Asset for a TokenType as a PNG encoded into a data URI.
     *
     * @param tokenType the token type of the art piece.
     */
    function getPngArt(uint256 tokenType) external view returns (string memory) {
        return _getPngDataUri(tokenType);
    }

    /**
     * @notice Get the Art Asset for a TokenType as a PICT data URI.
     *
     * Important: This will only function if the PICT files have been recovered.
     *
     * @param tokenType the token type of the art piece.
     */
    function getPICTArt(uint256 tokenType) external view returns (string memory) {
        return _getPICTDataUri(tokenType);
    }

    /**
     * @notice Get the Art Asset for a TokenType as an IFF data URI.
     *
     * Important: This will only function if the IFF files have been recovered.
     *
     * @param tokenType the token type of the art piece.
     */
    function getIFFArt(uint256 tokenType) external view returns (string memory) {
        return _getIFFDataUri(tokenType);
    }

    /**
     * @notice Get the closest source archival asset for a token.
     *
     * @param extension the file extension of the archival asset.
     * @param tokenType the token type of the art piece.
     */
    function getRawArchivalArt(string calldata extension, uint256 tokenType) external view returns (bytes memory) {
        if (keccak256(abi.encodePacked(extension)) == keccak256(abi.encodePacked(extension_iff))) {
            return _getIFFBytes(tokenType);
        }

        if (keccak256(abi.encodePacked(extension)) == keccak256(abi.encodePacked(extension_pict))) {
            return _getPICTBytes(tokenType);
        }

        revert UnrecognizedExtension();
    }

    /**
     * @notice Get the metadata of the source archival asset for a token.
     *
     * @param extension the file extension of the archival asset.
     * @param tokenType the token type of the art piece.
     */
    function getArchivalMetadata(
        string calldata extension,
        uint256 tokenType
    ) external view returns (ArchivalMetadata memory) {
        return _metadata[extension][tokenType - 1];
    }

    /**
     * @notice Admin function to configure the archival metadata for all tokens for a particular file extension.
     *
     * @param provider address of the archival data store.
     * @param scriptNames the filenames that will be saved in the data store.
     * @param extension the native os extension of the files that will be saved.
     */
    function setArchivalMetadata(
        address provider,
        string[] calldata scriptNames,
        string calldata extension
    ) external isOwner {
        uint256 idx; // note, zero indexed.
        for (idx; idx < scriptNames.length; idx++) {
            // this is implicitly assuming tokenTypes are 1-5.
            ArchivalMetadata memory metadata = ArchivalMetadata(provider, idx + 1, scriptNames[idx], extension);
            _metadata[extension].push(metadata);
        }
    }

    /**
     * @notice Admin function to update the archival metadata details for a single file.
     *
     * @param provider address of the archival data store.
     * @param tokenType the tokenType of the file.
     * @param scriptName the filename that will be saved in the data store.
     * @param extension the native os extension of the files that will be saved.
     */
    function updateArchivalMetadata(
        address provider,
        uint256 tokenType,
        string calldata scriptName,
        string calldata extension
    ) external isOwner {
        uint256 idx = tokenType - 1;
        ArchivalMetadata memory metadata = _metadata[extension][idx];
        require(metadata.tokenType == tokenType, 'invalid addressing');

        _metadata[extension][idx].scriptyStorageProvider = provider;
        _metadata[extension][idx].scriptName = scriptName;
        _metadata[extension][idx].extension = extension;
    }

    /**
     * @notice Admin function to clear out the entire Metadata Archive for a file extension.
     *
     * Important: This has no impact on the underlying datastore.
     *
     * @param extension the native os extension of the files that will be saved.
     */
    function clearArchivalMetadata(string calldata extension) external isOwner {
        ArchivalMetadata[] memory allMetadataForExtension = _metadata[extension];
        require(allMetadataForExtension.length > 0, 'array is empty');
        delete _metadata[extension];
    }

    function setSvgRenderer(address svgRenderer) external isOwner {
        _svgRenderer = svgRenderer;
    }

    function getSvgRenderer() external view returns (address) {
        return _svgRenderer;
    }

    function _getSvgConstructor(uint256) internal view override returns (ISVGConstructor svgConstructor) {
        return ISVGConstructor(_svgRenderer);
    }

    function _getIFFDataUri(uint256 tokenType) internal view returns (string memory) {
        bytes memory artBytes = _getIFFBytes(tokenType);

        return _convertBytesToDataURI(artBytes, 'image/x-iff');
    }

    function _getIFFBytes(uint256 tokenType) internal view returns (bytes memory) {
        uint256 idx = tokenType - 1;
        ArchivalMetadata memory metadata = _metadata[extension_iff][idx];
        require(metadata.tokenType == tokenType, 'IFF not configured');

        IScriptyStorageProvider provider = IScriptyStorageProvider(metadata.scriptyStorageProvider);
        return provider.getScript(metadata.scriptName, '');
    }

    function _getPICTDataUri(uint256 tokenType) internal view returns (string memory) {
        bytes memory artBytes = _getPICTBytes(tokenType);

        return _convertBytesToDataURI(artBytes, 'image/x-pict');
    }

    function _getPICTBytes(uint256 tokenType) internal view returns (bytes memory) {
        uint256 idx = tokenType - 1;
        ArchivalMetadata memory metadata = _metadata[extension_pict][idx];
        require(metadata.tokenType == tokenType, 'PICT not configured');

        IScriptyStorageProvider provider = IScriptyStorageProvider(metadata.scriptyStorageProvider);
        return provider.getScript(metadata.scriptName, '');
    }
}
