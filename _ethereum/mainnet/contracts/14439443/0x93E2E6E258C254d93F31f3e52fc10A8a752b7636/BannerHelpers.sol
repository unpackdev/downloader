// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import "./Base64.sol";
import "./StringUtils.sol";

library BannerHelpers {
    uint256 public constant MINTING_COST_MULTIPLIER = 0.001 ether;
    uint256 public constant UPDATE_COST = 0.000008 ether;

    string public constant ATTR_TEXT = "text";
    string public constant ATTR_TEXT_SIZE = "textSize";
    string public constant ATTR_TEXT_COLOR = "textColor";
    string public constant ATTR_BG_COLOR = "bgColor";

    // set default values for attributes
    string public constant DEFAULT_NAME = "Steal this NFT!";
    string public constant DEFAULT_DESCRIPTION =
        "This space could be yours for the modest amount of 21M BTC.";
    string public constant DEFAULT_TEXT = "GM!";
    string public constant DEFAULT_TEXT_COLOR = "#95cd41";
    string public constant DEFAULT_TEXT_SIZE = "2.5rem";
    string public constant DEFAULT_BG_COLOR = "#ea5c2b";
    uint8 public constant DEFAULT_TEXT_LENGTH = 20;

    // the juice of the NFT
    string public constant SVG_1 =
        "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 750 250'>";
    string public constant SVG_TEXT_STYLE_1 = "<style>.base { fill: ";
    // TODO: optimmize the svg by inlining the style
    // style="text-shadow:1px 1px #666, 3px 3px #000" fill="#95cd41" font-family="serif" font-size="2.5rem">gn!</text></svg>
    string public constant SVG_TEXT_STYLE_3 =
        "; font-family: serif; text-shadow: 1px 1px #666, 3px 3px #000; font-size: ";
    string public constant SVG_TEXT_STYLE_5 = "; }</style>";
    string public constant SVG_RECT_1 =
        "<rect width='100%' height='100%' fill='";
    string public constant SVG_RECT_3 =
        "'/><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>";

    function previewTokenValues(
        string memory name,
        string memory description,
        string memory bgColor,
        string memory text,
        string memory textColor,
        string memory textSize
    )
        public
        pure
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory
        )
    {
        return (
            // token name
            su.isEmptyOrNull(name) ? DEFAULT_NAME : name,
            // token description
            su.isEmptyOrNull(description) ? DEFAULT_DESCRIPTION : description,
            // token background color
            su.isEmptyOrNull(bgColor) ? DEFAULT_BG_COLOR : bgColor,
            // token text
            su.isEmptyOrNull(text) ? DEFAULT_TEXT : text,
            // token text color
            su.isEmptyOrNull(textColor) ? DEFAULT_TEXT_COLOR : textColor,
            // token text size
            su.isEmptyOrNull(textSize) ? DEFAULT_TEXT_SIZE : textSize
        );
    }

    function previewTokenURI(
        string memory name,
        string memory description,
        string memory bgColor,
        string memory text,
        string memory textColor,
        string memory textSize
    ) public pure returns (string memory) {
        require(su.isValidString(bytes(name)), "INVALID_NAME");
        require(su.isValidString(bytes(description)), "INVALID_DESCRIPTION");
        require(su.isValidString(bytes(text)), "INVALID_TEXT");
        require(su.isValidString(bytes(textColor)), "INVALID_TEXT_COLOR");
        require(su.isValidString(bytes(textSize)), "INVALID_TEXT_SIZE");
        require(su.isValidString(bytes(bgColor)), "INVALID_BG_COLOR");

        (
            name,
            description,
            bgColor,
            text,
            textColor,
            textSize
        ) = previewTokenValues(
            name,
            description,
            bgColor,
            text,
            textColor,
            textSize
        );

        // build things on-demand - start by concatenating the svg
        bytes memory nftSvgPt1 = abi.encodePacked(
            SVG_1,
            SVG_TEXT_STYLE_1,
            textColor,
            SVG_TEXT_STYLE_3,
            textSize,
            SVG_TEXT_STYLE_5
        );
        bytes memory nftSvg = abi.encodePacked(
            nftSvgPt1,
            SVG_RECT_1,
            bgColor,
            SVG_RECT_3,
            text,
            "</text></svg>"
        );

        // TODO: pre-base64 some of this, and then simply string concat!
        // then build the token uri json
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name": "',
                            name,
                            '", "description": "',
                            description,
                            '", "image": "data:image/svg+xml;base64,',
                            Base64.encode(nftSvg),
                            '"}'
                            // TODO: add the attributes: [textSize, textColor, bgColor] ?
                        )
                    )
                )
            );
    }
}
