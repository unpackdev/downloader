//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";
import "./Base64.sol";

/**
 * @dev Internal library encapsulating JSON / Token URI serialization
 */
library Serialize {
    /**
     * @dev Generates a ERC721 TokenURI for the given data
     * @param bitmapData The raw bytes of the drawing's bitmap
     * @param metadata The struct holding information about the drawing
     * @return a string application/json data URI containing the token information
     * 
     * We do _not_ base64 encode the JSON. This results in a slightly non-compliant
     * data URI, because of the commas (and potential non-URL-safe characters).
     * Empirically, this is fine: and re-base64-encoding everything would use
     * gas and time and is not worth it.
     * 
     * There's also a few ways we could encode the image in the metadata JSON:
     *  1. image/bmp data url in the `image` field (base64-encoded given binary data)
     *  2. raw svg data in the `image_data` field
     *  3. image/svg data url in the `image` field (containing a base64-encoded image, but not itself base64-encoded)
     *  4. (3), but with another layer of base64 encoding
     * Through some trial and error, (1) does not work with Rarible or OpenSea. The rest do. (4) would be yet another
     * layer of base64 (taking time, so is not desirable), (2) uses a potentially non-standard field, so we use (3).
     */
    function tokenURI(bytes memory bitmapData, Token.Metadata memory metadata) internal pure returns (string memory) {
        string memory imageKey = "image";
        bytes memory imageData = _svgDataURI(bitmapData);

        string memory fragment = _metadataJSONFragmentWithoutImage(metadata);
        return string(abi.encodePacked(
            'data:application/json,',
            fragment,
            // image data :)
            '","', imageKey, '":"', imageData, '"}'
        ));
    }

    /**
     * @dev Returns just the metadata of the image (no bitmap data) as a JSON string
     * @param metadata The struct holding information about the drawing
     */
    function metadataAsJSON(Token.Metadata memory metadata) internal pure returns (string memory) {
        string memory fragment = _metadataJSONFragmentWithoutImage(metadata);
        return string(abi.encodePacked(
            fragment,
            '"}'
        ));
    }

    /**
     * @dev Returns a partial JSON string with the metadata of the image.
     *      Used by both the full tokenURI and the plain-metadata serializers.
     * @param metadata The struct holding information about the drawing
     */
    function _metadataJSONFragmentWithoutImage(Token.Metadata memory metadata) internal pure returns (string memory) {
        return string(abi.encodePacked(
            // name
            '{"name":"',
                metadata.name,

            // description
            '","description":"',
                metadata.description,

            // external_url
            '","external_url":"',
                metadata.externalUrl,

            // code address
            '","drawing_address":"',
                metadata.drawingAddress
        ));
    }


   /**
     * @dev Generates a data URI of an SVG containing an <image> tag containing the given bitmapData
     * @param bitmapData The raw bytes of the drawing's bitmap
     */
    function _svgDataURI(bytes memory bitmapData) internal pure returns (bytes memory) {
        return abi.encodePacked(
            "data:image/svg+xml,",
            "<svg xmlns='http://www.w3.org/2000/svg' width='303' height='303'><image width='303' height='303' style='image-rendering: pixelated' href='",
            "data:image/bmp;base64,",
            Base64.encode(bitmapData),
            "'/></svg>"
        );
    }
}
