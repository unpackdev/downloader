// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.17;

import "./Base64.sol";
import "./IMetadataEncoder.sol";

contract MetadataEncoder is IMetadataEncoder {
    using Base64 for bytes;

    /// @notice Encode the name, description, and image as a Base64-JSON blob
    /// @param name The name of the item
    /// @param description A human readable description of the item
    /// @param image The raw SVG image data
    function encode(
        string calldata name,
        string calldata description,
        bytes calldata image
    ) external pure returns (string memory) {
        // prettier-ignore
        return string.concat(
            'data:application/json;base64,',
            abi.encodePacked(
                '{',
                    '"name": "', name, '",',
                    '"description": "', description, '",',
                    '"image": "data:image/svg+xml;base64,', image.encode(), '"'
                '}'
            )
            .encode()
        );
    }

    /// @notice Encode the name, description, and image URL
    /// @param name The name of the item
    /// @param description A human readable description of the item
    /// @param imageURL The image url
    function encodeWithImageURL(
        string calldata name,
        string calldata description,
        bytes calldata imageURL
    ) external pure returns (string memory) {
        // prettier-ignore
        return string.concat(
            'data:application/json;base64,',
            abi.encodePacked(
                '{',
                    '"name": "', name, '",',
                    '"description": "', description, '",',
                    '"image": "', imageURL, '"',
                '}'
            )
            .encode()
        );
    }

    /// @notice Encode the provided data as a Base64 blob
    /// @param mediaType The mediatype is a MIME type string, such as 'application/json'
    /// @param data The data that will be Base64 encoded
    function encode(string calldata mediaType, bytes calldata data) external pure returns (string memory) {
        return string.concat('data:', mediaType, ';base64,', data.encode());
    }
}
