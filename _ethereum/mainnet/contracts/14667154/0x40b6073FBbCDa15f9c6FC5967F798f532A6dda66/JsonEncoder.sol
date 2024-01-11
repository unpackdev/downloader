// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 divergence.xyz
pragma solidity >=0.8.0 <0.9.0;

import "./DynamicBuffer.sol";
import "./Strings.sol";

import "./Common.sol";
import "./Serializer.sol";
import "./IMetadataRenderer.sol";

/// @notice JSON encoding helper library to assemble data-uris
// solhint-disable quotes
library JSONEncoder {
    using DynamicBuffer for bytes;

    /// @notice The token description that will show up in the OS box.
    bytes private constant DESCRIPTION =
        "My Imaginary Friend is a collection of 3000 Imaginary Friend (IF) NFTs released by Kai, the internationally renowned artist who is known for his themes that include time, money and love. This collection combines Kai's passion for art and new mediums across the NFT community.";

    /// @notice Initializes the JSON uri buffer for a given token.
    /// @dev Adds mime type, token name and description.
    function init(uint256 tokenId) internal pure returns (bytes memory) {
        bytes memory uri = DynamicBuffer.allocate(1 << 12);

        uri.appendSafe('data:application/json;utf-8,{"name":"');
        uri.appendSafe(_tokenName(tokenId));
        uri.appendUnchecked('","description":"');
        uri.appendSafe(DESCRIPTION);
        uri.appendSafe('"');
        return uri;
    }

    /// @notice Parses token features and adds the respective attributes to
    /// the JSON uri.
    /// @param features The token features.
    /// @param numIdentical Number of tokens with the given set of features.
    function addAttributes(
        bytes memory uri,
        Features memory features,
        uint256 numIdentical
    ) internal pure {
        uri.appendSafe(', "attributes":[');
        uri.appendSafe(
            _traitStringNoComma(
                "Background",
                Strings.toString(features.background)
            )
        );
        uri.appendSafe(_traitString("Body", _getBodyTraitStr(features.body)));
        uri.appendSafe(
            _traitString("Mouth", _getMouthTraitStr(features.mouth))
        );
        uri.appendSafe(_traitString("Eyes", _getEyesTraitStr(features.eyes)));
        if (numIdentical > 1) {
            if (numIdentical == 2) {
                uri.appendSafe(_traitString("Twin"));
            }
            if (numIdentical == 3) {
                uri.appendSafe(_traitString("Triplet"));
            }
            if (numIdentical > 3) {
                uri.appendSafe(
                    _traitString("Multiplet", Strings.toString(numIdentical))
                );
            }
        }
        if (
            features.special == Special.Angel ||
            features.special == Special.Both
        ) {
            uri.appendSafe(_traitString("Angel"));
        }
        if (
            features.special == Special.Devil ||
            features.special == Special.Both
        ) {
            uri.appendSafe(_traitString("Devil"));
        }
        if (features.golden) {
            uri.appendSafe(_traitString("Golden"));
        }
        uri.appendSafe("]");
    }

    /// @notice Builds the token image attribute for a given token and adds it
    /// the JSON uri.
    function addImageUrl(
        bytes memory uri,
        string memory baseUrl,
        uint256 tokenId
    ) internal pure {
        uri.appendSafe(', "image": "');
        uri.appendSafe(bytes(baseUrl));
        uri.appendSafe("/");
        uri.appendSafe(bytes(Strings.toString(tokenId)));
        uri.appendSafe('"');
    }

    /// @notice Finalizes the json uri buffer
    function finalize(bytes memory uri) internal pure {
        uri.appendSafe("}");
    }

    /// @notice Builds the token name.
    /// @dev Uses uri compatible character encoding.
    function _tokenName(uint256 tokenId) private pure returns (bytes memory) {
        return
            abi.encodePacked("Imaginary Friend %23", Strings.toString(tokenId));
    }

    /// @notice Builds a named attribute string without leading comma.
    /// @dev The returned attribute string has to be added as the first element
    /// of the attributes array (no leading comma)/
    function _traitStringNoComma(bytes memory name, string memory value)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                '{"trait_type": "',
                name,
                '", "value":"',
                value,
                '"}'
            );
    }

    /// @notice Builds a named attribute string with leading comma.
    function _traitString(bytes memory name, string memory value)
        private
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(",", _traitStringNoComma(name, value));
    }

    /// @notice Builds an unnamed attribute string with leading comma.
    function _traitString(string memory value)
        private
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(',{"value":"', value, '"}');
    }

    /// @notice Computes the trait name for a given body.
    function _getBodyTraitStr(uint8 id) private pure returns (string memory) {
        return
            [
                "", // Skip 0, since we are 1 indexed
                "Special 1",
                "Special 2",
                "Special 3",
                "Big Heart",
                "Big Broken Heart",
                "Balloon",
                "Bunch of Hearts",
                "Winged Heart",
                "Brick of Bills",
                "Gold Brick",
                "Coins and Bills",
                "Diamond",
                "Pirates Treasure",
                "Bag of Money",
                "Cement Spreader",
                "Hammer",
                "Garden Shovel",
                "Welder",
                "Flower",
                "Earth",
                "Plant",
                "Watering Can",
                "Light Bulb",
                "Book",
                "Stacked Books",
                "Clock",
                "Hourglass",
                "Skull",
                "Pocket Watch",
                "Video Camera",
                "Film Camera",
                "Painter",
                "Guitar",
                "Camera",
                "Paper and Pencil",
                "Paint Roller and Can"
            ][id];
    }

    /// @notice Computes the trait name for a given mouth.
    function _getMouthTraitStr(uint8 id) private pure returns (string memory) {
        uint8[4] memory nums = [10, 10, 10, 5];
        string[4] memory names = ["Happy", "Sad", "Mad", "Special"];

        for (uint256 idx = 0; idx < 4; ++idx) {
            if (id <= nums[idx]) {
                return
                    string(
                        abi.encodePacked(names[idx], " ", Strings.toString(id))
                    );
            }
            id -= nums[idx];
        }
        return "";
    }

    /// @notice Computes the trait name for given eyes.
    function _getEyesTraitStr(uint8 id) private pure returns (string memory) {
        uint8[6] memory nums = [9, 8, 8, 8, 8, 4];
        string[6] memory names = [
            "Happy",
            "Sad",
            "Mad",
            "Annoyed",
            "Lost and Confused",
            "Special"
        ];

        for (uint256 idx = 0; idx < 6; ++idx) {
            if (id <= nums[idx]) {
                return
                    string(
                        abi.encodePacked(names[idx], " ", Strings.toString(id))
                    );
            }
            id -= nums[idx];
        }
        return "";
    }
}

// solhint-enable quotes
