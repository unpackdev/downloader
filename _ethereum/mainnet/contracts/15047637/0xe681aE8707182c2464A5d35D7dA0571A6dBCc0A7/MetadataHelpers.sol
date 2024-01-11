// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

// solhint-disable quotes
library MetadataHelpers {
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
