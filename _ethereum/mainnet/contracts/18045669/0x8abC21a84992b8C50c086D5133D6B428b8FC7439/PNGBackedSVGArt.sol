// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// OZ Libraries
import "./Base64.sol";

// Local References
import "./ArtDatastoreManager.sol";
import "./ISVGConstructor.sol";

/**
 * @title PNGBackedSVGArt
 * @author @NiftyMike | @NFTCulture
 * @dev An on-chain contract that constructs a PNG backed SVG object.
 */
abstract contract PNGBackedSVGArt is ArtDatastoreManager {
    function _getSvgConstructor(uint256 tokenType) internal view virtual returns (ISVGConstructor svgConstructor);

    function _getSvgDataURI(uint256 tokenType) internal view returns (string memory) {
        DynamicArtV1 memory artObject = _getArtObject(tokenType);
        bool hasBackground = bytes(artObject.backgroundColor).length > 0;
        string memory onChainEncodedArt = _getArtObject(tokenType).encodedArt;
        string memory svg = _constructSvg(
            tokenType,
            hasBackground,
            artObject.backgroundColor,
            _convertBase64PngToDataURI(onChainEncodedArt)
        );

        return _convertSvgToDataURI(svg);
    }

    function _getPngDataUri(uint256 tokenType) internal view returns (string memory) {
        string memory onChainEncodedArt = _getArtObject(tokenType).encodedArt;
        return _convertBase64PngToDataURI(onChainEncodedArt);
    }

    function _convertBase64PngToDataURI(string memory base64Png) internal pure returns (string memory) {
        return string.concat('data:image/png;base64,', base64Png);
    }

    function _convertSvgToDataURI(string memory svg) internal pure returns (string memory) {
        return string.concat('data:image/svg+xml;base64,', Base64.encode(bytes(svg)));
    }

    function _convertBytesToDataURI(
        bytes memory artBytes,
        string memory mimeType
    ) internal pure returns (string memory) {
        return string.concat('data:', mimeType, ';base64,', Base64.encode(artBytes));
    }

    function _constructSvg(
        uint256 tokenType,
        bool hasBackground,
        string memory backgroundColor,
        string memory pngDataURI
    ) internal view virtual returns (string memory) {
        return _getSvgConstructor(tokenType).constructFromPNG(hasBackground, backgroundColor, pngDataURI);
    }
}
