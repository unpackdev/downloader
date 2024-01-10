//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base64.sol";
import "./IShellFramework.sol";
import "./IEngine.sol";

struct Attribute {
    string key;
    string value;
}

abstract contract OnChainMetadataEngine is IEngine {
    // Called by the collection to resolve a response for tokenURI
    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        string memory name = _computeName(collection, tokenId);
        string memory description = _computeDescription(collection, tokenId);
        string memory image = _computeImageUri(collection, tokenId);
        string memory externalUrl = _computeExternalUrl(collection, tokenId);
        Attribute[] memory attributes = _computeAttributes(collection, tokenId);

        string memory attributesInnerJson = "";
        for (uint256 i = 0; i < attributes.length; i++) {
            attributesInnerJson = string(
                bytes(
                    abi.encodePacked(
                        attributesInnerJson,
                        i > 0 ? ", " : "",
                        '{"trait_type": "',
                        attributes[i].key,
                        '", "value": "',
                        attributes[i].value,
                        '"}'
                    )
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                image,
                                '", "external_url": "',
                                externalUrl,
                                '", "attributes": [',
                                attributesInnerJson,
                                "]}"
                            )
                        )
                    )
                )
            );
    }

    // compute the metadata name for a given token
    function _computeName(IShellFramework collection, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    // compute the metadata description for a given token
    function _computeDescription(IShellFramework collection, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    // compute the metadata image field for a given token
    function _computeImageUri(IShellFramework collection, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    // compute the external_url field for a given token
    function _computeExternalUrl(IShellFramework collection, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    function _computeAttributes(IShellFramework collection, uint256 token)
        internal
        view
        virtual
        returns (Attribute[] memory);
}
