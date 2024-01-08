// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/// @notice A library with functions to generate VampireGame NFT metadata
library TraitMetadata {
    /// @notice Generate an NFT metadata
    /// @param name a string with the NFT name
    /// @param description a string with the NFT description,
    /// @param image a string with the NFT encoded image
    /// @param attributes a JSON string with the NFT attributes
    /// @return a JSON string with the NFT metadata
    function makeMetadata(
        bytes memory name,
        string memory description,
        bytes memory image,
        string memory attributes
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"name":"',
                    name,
                    '","description":"',
                    description,
                    '","image":"',
                    image,
                    '","attributes":',
                    attributes,
                    "}"
                )
            );
    }

    /// @notice Generates a JSON string for an NFT metadata attribute
    /// @param traitType the attribute trait type
    /// @param value the attribute value
    /// @return a JSON string for the attribute
    function makeAttributeJSON(string memory traitType, string memory value)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    traitType,
                    '","value":"',
                    value,
                    '"}'
                )
            );
    }

    /// @notice Generates a string with a JSON array containing all the attributes
    /// @param attributes a list of JSON strings of each attribute
    /// @return the JSON string with the attribute list
    function makeAttributeListJSON(string[] memory attributes)
        internal
        pure
        returns (string memory)
    {
        bytes memory attributeListBytes = "[";

        for (uint256 i = 0; i < attributes.length; i++) {
            attributeListBytes = abi.encodePacked(
                attributeListBytes,
                attributes[i],
                i != attributes.length - 1 ? "," : "]"
            );
        }

        return string(attributeListBytes);
    }
}
