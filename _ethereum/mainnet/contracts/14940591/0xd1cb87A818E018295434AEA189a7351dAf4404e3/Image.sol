// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./base64.sol";
import "./SVG.sol";
import "./Utils.sol";
import "./TinierFont.sol";

contract Image {
    function render(
        string memory name,
        address collection,
        uint8 level
    ) public pure returns (string memory) {
        string[2][5] memory levels = [
            ["#AAAAAA", "#424242"],
            ["#4E7AD4", "#70DA99"],
            ["#E5C075", "#70DA99"],
            ["#F1CD89", "#9943D1"],
            ["#F9F365", "#F27400"]
        ];
        string memory startColor = levels[level][0];
        string memory stopColor = levels[level][1];

        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" style="background:#000;font-family:Courier New">',
                styles(),
                logo(),
                info(name, collection),
                svg.el(
                    "defs",
                    "",
                    svg.el(
                        "linearGradient",
                        string.concat(
                            svg.prop("id", "grd"),
                            svg.prop("x1", "0"),
                            svg.prop("y1", "0"),
                            svg.prop("x2", "180"),
                            svg.prop("y2", "180"),
                            svg.prop("gradientUnits", "userSpaceOnUse")
                        ),
                        string.concat(
                            svg.el("stop", svg.prop("stop-color", startColor)),
                            svg.el(
                                "stop",
                                string.concat(
                                    svg.prop("stop-color", stopColor),
                                    svg.prop("offset", "1")
                                )
                            )
                        )
                    )
                ),
                "</svg>"
            );
    }

    function tinierFontData() public pure returns (bytes memory) {
        return TinierFont.fontdata;
    }

    function tinierFontBase64() public pure returns (string memory) {
        return
            string.concat(
                "data:font/ttf;base64,",
                string(Base64.encode(TinierFont.fontdata))
            );
    }

    function tinierFontFace() public pure returns (string memory) {
        return
            string.concat(
                '@font-face{font-family:tinier;src:url("',
                tinierFontBase64(),
                '" format(ttf);}'
            );
    }

    function styles() internal pure returns (string memory) {
        return svg.el("style", "", tinierFontFace());
    }

    function logo() internal pure returns (string memory) {
        return
            string.concat(
                svg.el(
                    "mask",
                    string.concat(svg.prop("id", "hot_mask")),
                    string.concat(
                        svg.text(
                            string.concat(
                                svg.prop("x", "20"),
                                svg.prop("y", "50"),
                                svg.prop("font-size", "49"),
                                svg.prop("fill", "white")
                            ),
                            "HOT"
                        ),
                        svg.text(
                            string.concat(
                                svg.prop("x", "20"),
                                svg.prop("y", "90"),
                                svg.prop("font-size", "49"),
                                svg.prop("fill", "white")
                            ),
                            "CHAIN"
                        ),
                        svg.text(
                            string.concat(
                                svg.prop("x", "20"),
                                svg.prop("y", "130"),
                                svg.prop("font-size", "49"),
                                svg.prop("fill", "white")
                            ),
                            "SVG"
                        )
                    )
                ),
                svg.g(
                    svg.prop("mask", "url(#hot_mask)"),
                    svg.rect(
                        string.concat(
                            svg.prop("width", "180"),
                            svg.prop("height", "180"),
                            svg.prop("fill", "url(#grd)")
                        )
                    )
                )
            );
    }

    function info(string memory name, address collection)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                svg.text(
                    string.concat(
                        svg.prop("x", "20"),
                        svg.prop("y", "310"),
                        svg.prop("font-size", "20"),
                        svg.prop("font-family", "tinier"),
                        svg.prop("fill", "#ABABAB")
                    ),
                    string.concat("<![CDATA[", name, "]]>")
                ),
                svg.text(
                    string.concat(
                        svg.prop("x", "20"),
                        svg.prop("y", "330"),
                        svg.prop("font-size", "12"),
                        svg.prop("fill", "#999")
                    ),
                    string.concat("0x", utils.addressToAsciiString(collection))
                )
            );
    }
}
