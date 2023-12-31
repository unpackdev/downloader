// SPDX-License-Identifier: MIT
/*
 * if you find someone copying this without attribution, call em out
 *
 * 「 A Milli (x8)
 *   ..
 *   Tougher than Nigerian hair
 *   My criteria compared to your career just isn't fair 」 - Weezy
 */

pragma solidity ^0.8.18;

import "./GiftWrap.sol";
import "./Base64.sol";

contract GiftWrappedToken is GiftWrap {
    enum TweakableParams {
        Stop1,
        Stop2,
        Cx,
        Cy
    }
    enum TweakableColours {
        Stop0,
        Stop1,
        Stop2,
        Foreground
    }

    address public artist;
    address constant THE_CONCEPT = 0x70a304C1776Db52417420722cBAc4b3902ca6aEa;

    int16[2] public cXY = [int16(7296), int16(2368)];
    int16[3] public stopOffsets = [int16(0), int16(670), int16(1000)];
    string[3] public stopColours = ["#e9e9e9", "#0657f9", "#d6d6d6bb"];
    string public fgFill = "white";

    modifier onlyArtistOrOwner() virtual {
        require(msg.sender == owner() || msg.sender == artist, "not for you");
        _;
    }

    constructor() GiftWrap(THE_CONCEPT) {
        artist = msg.sender;
    }

    function setArtist(address newArtist) public onlyOwner {
        artist = newArtist;
    }

    function setColour(
        TweakableColours choice,
        string memory color
    ) public onlyArtistOrOwner {
        if (choice == TweakableColours.Foreground) {
            fgFill = color;
        } else if (uint(choice) < 3) {
            stopColours[uint(choice)] = color;
        }
    }

    function tweakParam(
        TweakableParams choice,
        int16 value
    ) public onlyArtistOrOwner {
        if (
            choice == TweakableParams.Stop1 || choice == TweakableParams.Stop2
        ) {
            require(value > 0 && value < 1001, "out of bounds");
            stopOffsets[uint(choice) + 1] = value;
        } else if (
            choice == TweakableParams.Cx || choice == TweakableParams.Cy
        ) {
            require(value > -2501 && value < 12501, "out of bounds");
            cXY[uint(choice) - 2] = value;
        }
    }

    function uri(uint256 i) public view override returns (string memory) {
        string memory s = super.uri(i);
        string memory name = string(abi.encodePacked(s, " of The Concept"));

        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<?xml version="1.0" encoding="UTF-8"?>',
                        '<svg width="500" height="500" viewBox="0 0 500 500" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                        _svgDefsHead(),
                        _svgDefsTail(),
                        '<circle cx="250" cy="250" r="202.254248593736856025" fill="url(#grad)"></circle>',
                        (i > 0) ? _svgText(s) : _svgLogo(),
                        "</svg>"
                    )
                )
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "image":"',
                                image,
                                '", "attributes": [{ "display_type": "number", "trait_type": "permille", "value": ',
                                LibString.toString(i),
                                '}, { "display_type": "number", "trait_type": "wads", "value": ',
                                LibString.toString(super._pToAmt(i)),
                                unicode'}], "description": "This ERC-1155 token contains a set amount of The Concept. {id} per mīlle to be exact."}'
                            )
                        )
                    )
                )
            );
    }

    function _toDecimal(
        int number,
        uint pow10
    ) private pure returns (string memory) {
        bool negative = number < 0;
        if (negative) number *= -1;
        uint256 n = uint256(number);
        uint256 leftOfDecimal = n / 10 ** pow10;
        uint256 rightOfDecimal = n % 10 ** pow10;
        string memory s;
        if (rightOfDecimal > 0) {
            s = string(
                abi.encodePacked(".", LibString.toString(rightOfDecimal))
            );
        }
        s = string(abi.encodePacked(LibString.toString(leftOfDecimal), s));
        if (negative) s = string(abi.encodePacked("-", s));
        return s;
    }

    function _svgDefsHead() private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<defs>",
                    '<radialGradient id="grad" cx="',
                    _toDecimal(cXY[0], 4),
                    '" cy="',
                    _toDecimal(cXY[1], 4),
                    '" r="1">'
                )
            );
    }

    function _svgDefsTail() private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<stop offset="0%" stop-color="',
                    stopColours[0],
                    '"></stop>',
                    '<stop offset="',
                    _toDecimal(stopOffsets[1], 1),
                    '%" stop-color="',
                    stopColours[1],
                    '"></stop>',
                    '<stop offset="',
                    _toDecimal(stopOffsets[2], 1),
                    '%" stop-color="',
                    stopColours[2],
                    '"></stop>',
                    "</radialGradient>",
                    "</defs>"
                )
            );
    }

    function _svgLogo() private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g transform="translate(250, 250) scale(2.66)" fill="',
                    fgFill,
                    '"><path d="M57.93 38.21V15.34h9.64l.17.31a180.68 180.68 0 0 1 1.54 2.7c.57 1 1.13 1.94 1.25 2.07.12.14.16.25.1.25s-.01.11.1.25c.13.13.3.4.38.6.09.18.31.6.5.9.2.31.42.7.5.85.07.15.29.53.48.84.19.3.44.75.56.98.12.23.34.61.49.84.15.23.36.58.46.77a538.62 538.62 0 0 0 4.1 7.23 19.92 19.92 0 0 0 1.04 1.75c.28.57.54 1 .7 1.17.1.08.16.26.16.4 0 .13.05.26.12.28.1.04 1.02 1.58 2.2 3.7l.85 1.5c.24.4.68 1.19.97 1.73a13.75 13.75 0 0 0 .92 1.51c0 .05.2.43.45.83.26.41.59.98.74 1.27.28.54.28.53.31-16.1l.04-16.63h8.56v45.74h-9.52l-.45-.8-.67-1.23a2.02 2.02 0 0 0-.32-.5 1.33 1.33 0 0 1-.26-.42 8.1 8.1 0 0 0-.43-.8 27.86 27.86 0 0 1-1.44-2.5 194.77 194.77 0 0 1-2.77-4.76c-.25-.46-.53-.93-.61-1.03a10.3 10.3 0 0 1-.85-1.45c-.22-.41-.5-.9-.64-1.1-.13-.2-.28-.45-.33-.56a9.08 9.08 0 0 0-.4-.7c-.16-.27-.49-.84-.72-1.27a8.5 8.5 0 0 0-.6-.99c-.11-.12-.2-.28-.2-.35 0-.07-.15-.36-.34-.64a15.8 15.8 0 0 1-.6-.98c-.44-.76-1.3-2.28-1.45-2.5a58.7 58.7 0 0 1-2.22-3.96c-.1-.04-.53-.75-1.63-2.7a340.33 340.33 0 0 0-1.75-3.1 2.06 2.06 0 0 0-.3-.4c-.15-.15-.23-.33-.19-.4.04-.06.01-.11-.07-.11-.1 0-.15 5.01-.15 16.63v16.62h-8.42zM116.69 61c-.05-.04 0-.25.1-.45.12-.2.47-1 .79-1.77l.83-1.97c.14-.3.48-1.13.77-1.82.28-.7.63-1.52.77-1.82l.77-1.83.7-1.68c.11-.23.42-1 .7-1.69.28-.7.6-1.45.71-1.68.11-.23.37-.83.57-1.33a116.8 116.8 0 0 1 1.25-3.02c.29-.7.64-1.52.78-1.82l.77-1.83c.28-.7.6-1.45.7-1.68a123.46 123.46 0 0 0 1.48-3.51l.56-1.33a475.88 475.88 0 0 1 3-7.16 281.3 281.3 0 0 0 2.65-6.31l.92-2.18.28-.7h6.8l.35.84a146.77 146.77 0 0 0 1.08 2.6c.2.5.45 1.1.56 1.33.58 1.3 1.49 3.43 2.7 6.38a117.25 117.25 0 0 0 1.23 2.88 830.81 830.81 0 0 1 3.01 7.16 90.77 90.77 0 0 1 1.57 3.65c.14.3.49 1.13.77 1.82a80 80 0 0 0 1.25 2.95c.46 1.04.63 1.45.63 1.55 0 .12.6 1.45.95 2.1.13.23.22.45.2.49-.02.04.29.82.69 1.75a140.06 140.06 0 0 1 2.01 4.77 67.89 67.89 0 0 1 2.19 5.23c0 .14-1.02.17-4.62.17h-4.61l-.18-.45c-.3-.77-.5-1.25-1.12-2.7a341.17 341.17 0 0 1-1.82-4.35l-.64-1.5a8.8 8.8 0 0 1-.5-1.3c0-.04-.11-.32-.27-.6a2.35 2.35 0 0 1-.28-.78c0-.23-.46-.24-8.33-.24h-8.32l-.74 1.72-1.44 3.33c-.37.88-.84 1.97-1.44 3.3-.1.23-.5 1.13-.86 2l-.67 1.57h-4.58c-2.52 0-4.63-.04-4.67-.09zm27.54-19.9c0-.05-.12-.33-.28-.63-.15-.3-.28-.67-.28-.81a.67.67 0 0 0-.12-.4 3.54 3.54 0 0 1-.34-.83c-.23-.76-.8-2.38-1.22-3.5l-1.27-3.52-1.22-3.4c-.12-.33-.28-.58-.36-.56a2.8 2.8 0 0 0-.45.95 250.84 250.84 0 0 1-2.39 6.8c-.1.31-.35 1-.56 1.55-.2.54-.43 1.2-.5 1.47-.09.27-.23.68-.33.91-.27.66-.52 1.38-.6 1.72l-.07.32h5c2.74 0 5-.04 5-.08zM99.8 60.55c.12-.21.48-1.02.8-1.8a611.37 611.37 0 0 1 1.25-3c.24-.59.52-1.22.63-1.41a71.52 71.52 0 0 1 1.9-4.56l.55-1.34c.34-.86.43-1.06.83-1.96l.59-1.4.55-1.34c.14-.3.48-1.13.77-1.82l.7-1.68a30.26 30.26 0 0 0 1.23-2.98c0-.06.1-.33.25-.6.14-.27.49-1.06.77-1.76.29-.7.6-1.45.71-1.68l.56-1.33a98.72 98.72 0 0 1 1.32-3.16l.78-1.83.5-1.19c.32-.82.6-1.5.9-2.17a23.48 23.48 0 0 0 1.2-2.94c-.03 0 .05-.2.17-.43.13-.23.43-.9.67-1.48a341.8 341.8 0 0 1 1.07-2.56l.4-.94h5.16c4.35 0 5.16.03 5.16.2s-.53 1.47-1.2 2.95l-.49 1.2a21 21 0 0 1-.55 1.33c-.14.3-.36.85-.5 1.2-.13.34-.35.88-.49 1.19-.14.3-.35.84-.49 1.19-.13.35-.32.82-.43 1.05-.1.23-.45 1.05-.76 1.82-.32.78-.7 1.66-.86 1.97-.15.3-.27.61-.27.68 0 .07-.08.32-.19.56l-.71 1.7-.71 1.69c-.5 1.1-.8 1.84-.84 2.04-.03.11-.31.8-.63 1.54a114.34 114.34 0 0 0-1.62 3.86 228.29 228.29 0 0 0-1.12 2.66 476.9 476.9 0 0 0-1.86 4.5 424.33 424.33 0 0 1-2.56 6.17l-.5 1.2c-.2.5-.44 1.1-.55 1.33l-.5 1.19a65.7 65.7 0 0 1-.84 2.07l-.17.45H99.59z" transform="translate(-109.855 -38.15)" /></g>'
                )
            );
    }

    function _svgText(string memory text) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text y="250px" x="250px" text-anchor="middle" dominant-baseline="central" fill="',
                    fgFill,
                    '" font-family="Calibri, -apple-system, sans-serif" font-weight="400" font-size="140px">',
                    text,
                    "</text>"
                )
            );
    }
}
