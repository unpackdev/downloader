// SPDX-License-Identifier: GPL-3.0
// original author: peri.eth / @peripheralist
// amended by degenwizards.eth /@degenwizards in the framework of forking Capsules (Skribbles)

pragma solidity ^0.8.8;

import "./Strings.sol";
import "./ICapsuleMetadata.sol";
import "./Base64.sol";

contract SkribblesMetadata is ICapsuleMetadata {
    
    /// @notice Returns base64-encoded json containing Capsule metadata.
    /// @dev `image` is passed as an argument to allow Capsule image rendering to be handled by an external contract.
    /// @param capsule Capsule to return metadata for.
    /// @param image Image to be included in metadata.
    function metadataOf(Capsule memory capsule, string memory image)
        external
        pure
        returns (string memory)
    {
        string memory pureText = "false";
        if (capsule.isPure) pureText = "true";
        bytes memory metadata = abi.encodePacked(
            '{"name": "Skribbles #',
            Strings.toString(capsule.id),
            '", "description": "Got something to say? Skribble it! Editable text NFTs rendered as SVGs on-chain.", "image": "',
            image,
            '", "attributes": [{"trait_type": "Color", "value": "',
            _bytes3ToColorCode(capsule.color),
            '"}, {"trait_type": "Font", "value": "',
            Strings.toString(capsule.font.weight),
            '"}]}'
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(metadata)
                )
            );
    }

    /// @notice Format bytes3 as html hex color code.
    /// @param b bytes3 value representing hex-encoded RGB color.
    /// @return o Formatted color code string.
    function _bytes3ToColorCode(bytes3 b)
        internal
        pure
        returns (string memory o)
    {
        bytes memory hexCode = bytes(Strings.toHexString(uint24(b)));
        // Trim leading 0x from hexCode
        for (uint256 i = 2; i < hexCode.length; i++) {
            o = string(abi.encodePacked(o, hexCode[i]));
        }
        // Pad start
        while (bytes(o).length < 6) {
            o = string.concat("00", o);
        }
        // Lead with #
        return string.concat("#", o);
    }
}