// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./AccessControl.sol";
import "./Base64.sol";
import "./Strings.sol";
import "./strings.sol";

contract GrowerPrinter is AccessControl {
    using Strings for uint256;
    using strings for *;

    bytes32 public constant CONSUMER_ROLE = keccak256("CONSUMER_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function json(
        string memory growerPunk,
        string memory attrs,
        uint256 length,
        uint256 maxLength,
        uint256 tokenId
    ) external view onlyRole(CONSUMER_ROLE) returns (string memory) {
        strings.slice memory sliceAttr = attrs.toSlice();
        strings.slice memory delimAttr = ", ".toSlice();

        string[] memory attrParts = new string[](sliceAttr.count(delimAttr) + 1);
        for (uint256 i = 0; i < attrParts.length; i++) {
            attrParts[i] = sliceAttr.split(delimAttr).toString();
        }

        string memory attributes = string.concat('","attributes":[{"trait_type":"Head","value":"', attrParts[0], '"}');

        for (uint256 i = 1; i < attrParts.length; i++) {
            attributes = string.concat(attributes, ',{"trait_type":"Features","value":"', attrParts[i], '"}');
        }

        if (length >= maxLength) {
            attributes = string.concat(attributes, ',{"trait_type":"Growth","value":"GROWN"}');
        } else {
            string memory growth = "O";
            uint256 count = 1;
            while (count < length / 10) {
                growth = string.concat(growth, "O");
                count += 2;
            }

            attributes = string.concat(attributes, ',{"trait_type":"Growth","value":"GR', growth, 'WING"}');
        }

        return
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name":"GrowerPunk #',
                        tokenId.toString(),
                        attributes,
                        '],"description":"GrowerPunks","image":"data:image/svg+xml;base64,',
                        Base64.encode(bytes(growerPunk)),
                        '"}'
                    )
                )
            );
    }

    function svg(
        string memory punk,
        string memory attrs,
        uint256 length
    ) external view onlyRole(CONSUMER_ROLE) returns (string memory) {
        strings.slice memory slicePunk = punk.toSlice();
        slicePunk
            .beyond(
                'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24">'
                    .toSlice()
            )
            .until("</svg>".toSlice());

        // determine gender + skin color
        bool isMale = !hasAttr("Female", attrs);
        string memory skinColor = colorAtPixel(slicePunk, isMale ? "7" : "9", "23");

        // draw the shaft
        if (isMale) {
            // draw tip
            string memory colorAtTipTop = colorAtPixel(slicePunk, "12", "5");
            string memory colorAtTipBot = colorAtPixel(slicePunk, "12", "6");
            if (colorAtTipTop.toSlice().equals(skinColor.toSlice())) {
                slicePunk = slicePunk
                    .concat(
                        '<rect x="12" y="5" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/>'
                            .toSlice()
                    )
                    .toSlice();
            }
            if (colorAtTipBot.toSlice().equals(skinColor.toSlice())) {
                slicePunk = slicePunk
                    .concat(
                        '<rect x="12" y="6" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/>'
                            .toSlice()
                    )
                    .toSlice();
            }
            // bit of makeup
            if (!hasAttr("Big Beard", attrs)) {
                slicePunk = slicePunk
                    .concat(
                        string
                            .concat(
                                '<rect x="10" y="23" width="1" height="1" shape-rendering="crispEdges" fill="',
                                skinColor,
                                '"/>'
                            )
                            .toSlice()
                    )
                    .toSlice();
            }
            if (hasAttr("Hoodie", attrs)) {
                // draw a nice long sheathed shaft
                slicePunk = slicePunk
                    .concat(
                        string
                            .concat(
                                '<rect x="4" y="24" width="12" height="',
                                (length + 5).toString(),
                                '" shape-rendering="crispEdges" fill="#000000ff"/><rect x="7" y="24" width="4" height="1" shape-rendering="crispEdges" fill="#000000ff"/>',
                                '<rect x="5" y="24" width="8" shape-rendering="crispEdges" fill="#555555ff"',
                                string.concat(' height="', (length + 5).toString(), '"/>')
                            )
                            .toSlice()
                    )
                    .toSlice();
            } else {
                // draw a nice long shaft
                slicePunk = string
                    .concat(
                        '<rect x="6" y="19" width="10" height="',
                        (length + 5).toString(),
                        '" shape-rendering="crispEdges" fill="#000000ff"/>',
                        '<rect x="7" y="19" width="8" shape-rendering="crispEdges"',
                        string.concat(' fill="', skinColor, '" height="', (length + 5).toString(), '"/>')
                    )
                    .toSlice()
                    .concat(slicePunk)
                    .toSlice();
                // draw additional traits
                if (hasAttr("Gold Chain", attrs)) {
                    if (!hasAttr("Luxurious Beard", attrs) && !hasAttr("Big Beard", attrs)) {
                        slicePunk = slicePunk
                            .concat(
                                '<rect x="10" y="22" width="5" height="1" shape-rendering="crispEdges" fill="#ffc926ff"/>'
                                    .toSlice()
                            )
                            .toSlice();
                    }
                } else if (hasAttr("Chinstrap", attrs) || hasAttr("Front Beard", attrs) || hasAttr("Goat", attrs)) {
                    if (hasAttr("Silver Chain", attrs)) {
                        slicePunk = slicePunk
                            .concat(
                                '<rect x="10" y="22" width="1" height="1" shape-rendering="crispEdges" fill="#dfdfdfff"/><rect x="14" y="22" width="1" height="1" shape-rendering="crispEdges" fill="#dfdfdfff"/>'
                                    .toSlice()
                            )
                            .toSlice();
                    } else {
                        slicePunk = slicePunk
                            .concat(
                                string
                                    .concat(
                                        '<rect x="10" y="22" width="1" height="1" shape-rendering="crispEdges" fill="',
                                        skinColor,
                                        '"/>'
                                    )
                                    .toSlice()
                            )
                            .toSlice();
                    }
                } else if (!hasAttr("Big Beard", attrs) && hasAttr("Silver Chain", attrs)) {
                    slicePunk = slicePunk
                        .concat(
                            '<rect x="10" y="22" width="5" height="1" shape-rendering="crispEdges" fill="#dfdfdfff"/>'
                                .toSlice()
                        )
                        .toSlice();
                }
            }
        } else {
            // draw tip
            if (!hasAttr("Mohawk", attrs)) {
                string memory colorAtTipTop = colorAtPixel(slicePunk, "12", "8");
                string memory colorAtTipBot = colorAtPixel(slicePunk, "12", "9");
                if (colorAtTipTop.toSlice().equals(skinColor.toSlice())) {
                    slicePunk = slicePunk
                        .concat(
                            '<rect x="12" y="8" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/>'
                                .toSlice()
                        )
                        .toSlice();
                }
                if (colorAtTipBot.toSlice().equals(skinColor.toSlice())) {
                    slicePunk = slicePunk
                        .concat(
                            '<rect x="12" y="9" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/>'
                                .toSlice()
                        )
                        .toSlice();
                }
            }
            // draw a nice long shaft
            slicePunk = string
                .concat(
                    '<rect x="8" y="19" width="8" height="',
                    (length + 5).toString(),
                    '" shape-rendering="crispEdges" fill="#000000ff"/>',
                    '<rect x="9" y="19" width="6" shape-rendering="crispEdges"',
                    string.concat(' fill="', skinColor, '" height="', (length + 5).toString(), '"/>')
                )
                .toSlice()
                .concat(slicePunk)
                .toSlice();
            // draw additional traits
            if (hasAttr("Choker", attrs)) {
                if (hasAttr("Straight Hair", attrs)) {
                    slicePunk = slicePunk
                        .concat(
                            string
                                .concat(
                                    '<rect x="12" y="23" width="1" height="1" shape-rendering="crispEdges"',
                                    string.concat(' fill="', skinColor, '"/>')
                                )
                                .toSlice()
                        )
                        .toSlice();
                } else if (hasAttr("Orange Side", attrs)) {
                    slicePunk = slicePunk
                        .concat(
                            string
                                .concat(
                                    '<rect x="12" y="23" width="1" height="1" shape-rendering="crispEdges"',
                                    string.concat(' fill="', skinColor, '"/>'),
                                    '<rect x="13" y="22" width="1" height="1" shape-rendering="crispEdges" fill="#000000ff"/>'
                                )
                                .toSlice()
                        )
                        .toSlice();
                } else {
                    slicePunk = slicePunk
                        .concat(
                            string
                                .concat(
                                    '<rect x="12" y="23" width="1" height="1" shape-rendering="crispEdges"',
                                    string.concat(' fill="', skinColor, '"/>'),
                                    '<rect x="14" y="20" width="2" height="2" shape-rendering="crispEdges" fill="#000000ff"/><rect x="13" y="21" width="2" height="2" shape-rendering="crispEdges" fill="#000000ff"/>'
                                )
                                .toSlice()
                        )
                        .toSlice();
                }
            } else if (hasAttr("Silver Chain", attrs)) {
                slicePunk = slicePunk
                    .concat(
                        string
                            .concat(
                                '<rect x="12" y="23" width="1" height="1" shape-rendering="crispEdges"',
                                string.concat(' fill="', skinColor, '"/>'),
                                '<rect x="12" y="22" width="3" height="1" shape-rendering="crispEdges" fill="#dfdfdfff"/>'
                            )
                            .toSlice()
                    )
                    .toSlice();
            } else if (hasAttr("Gold Chain", attrs)) {
                slicePunk = slicePunk
                    .concat(
                        string
                            .concat(
                                '<rect x="12" y="23" width="1" height="1" shape-rendering="crispEdges"',
                                string.concat(' fill="', skinColor, '"/>'),
                                '<rect x="12" y="22" width="3" height="1" shape-rendering="crispEdges" fill="#ffc926ff"/>'
                            )
                            .toSlice()
                    )
                    .toSlice();
            }
        }

        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 ',
                (length + 24).toString(),
                '"><rect width="100%" height="100%" fill="#6a8494"/>',
                slicePunk.toString(),
                "</svg>"
            );
    }

    function colorAtPixel(
        strings.slice memory _slicePunk,
        string memory _x,
        string memory _y
    ) internal pure returns (string memory) {
        strings.slice memory rect;
        strings.slice memory copy = _slicePunk.copy().find(string.concat('<rect x="', _x, '" y="', _y).toSlice());
        copy.split('fill="'.toSlice(), rect);
        return copy.until(copy.copy().find("ff".toSlice()).beyond("ff".toSlice())).toString();
    }

    function hasAttr(string memory _attr, string memory _attrs) internal pure returns (bool) {
        strings.slice memory foundAttr = _attrs.toSlice().find(_attr.toSlice());
        return !foundAttr.empty();
    }
}
