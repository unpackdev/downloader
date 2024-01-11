// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Base64.sol";
import "./Strings.sol";

contract DoorsSVG {
    using Strings for uint256;

    bytes constant _PALETTE =
        hex"0000004d4d4dcccccc00a99d29abe20071bc2e319293278fed1e79ff0000ff8800ffff9bb8ffdec4e9fbd8d2fffccdff";

    string[16] internal _NAMES = [
        "Black",
        "Dark Grey",
        "Light Grey",
        "Teal",
        "Blue",
        "Ocean Blue",
        "Navy",
        "Purple",
        "Magenta",
        "Red",
        "Orange",
        "Yellow",
        "Green",
        "Sky Blue",
        "Lavender",
        "Pink"
    ];

    function _getSVG(uint8 body, uint8 knob)
        internal
        pure
        returns (bytes memory)
    {
        return (
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1080 1920">',
                '<rect width="100%" height="100%" fill="rgb(',
                abi.encodePacked(
                    uint256(uint8(_PALETTE[body * 3])).toString(),
                    ",",
                    uint256(uint8(_PALETTE[body * 3 + 1])).toString(),
                    ",",
                    uint256(uint8(_PALETTE[body * 3 + 2])).toString()
                ),
                ')" /><circle cx="912" cy="960" r="56" fill="rgb(',
                abi.encodePacked(
                    uint256(uint8(_PALETTE[knob * 3])).toString(),
                    ",",
                    uint256(uint8(_PALETTE[knob * 3 + 1])).toString(),
                    ",",
                    uint256(uint8(_PALETTE[knob * 3 + 2])).toString()
                ),
                ')" /></svg>'
            )
        );
    }

    function _getJSON(
        uint256 tokenId,
        uint8 body,
        uint8 knob
    ) internal view returns (bytes memory) {
        return
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"Door ',
                        tokenId.toString(),
                        '",',
                        unicode'"description":"Doors is a collection of 66 fully on–chain artworks 🌹 '
                        unicode"Project by Rafaël Rozendaal 2022 🌹 "
                        unicode"Smart contract by Alberto Granzotto 🌹 "
                        unicode'License: CC BY-NC-ND 4.0",',
                        '"attributes":[{"trait_type":"Door Color","value":"',
                        _NAMES[body],
                        '"},{"trait_type":"Knob Color","value":"',
                        _NAMES[knob],
                        '"}],',
                        '"image":"data:image/svg+xml;base64,',
                        Base64.encode(_getSVG(body, knob)),
                        '"}'
                    )
                )
            );
    }
}
