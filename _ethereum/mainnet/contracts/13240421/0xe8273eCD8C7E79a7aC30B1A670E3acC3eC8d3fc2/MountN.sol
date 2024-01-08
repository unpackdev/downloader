// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./iN.sol";

contract MountN is ERC721Enumerable, ReentrancyGuard, Ownable {
    
    address public n;
    
    string public artLicence = "CC0";
    
    mapping(uint256 => string[4]) public morningGradientColors;
    mapping(uint256 => string[4]) public morningGradientOffsets;
    mapping(uint256 => string[4]) public noonGradientColors;
    mapping(uint256 => string[4]) public noonGradientOffsets;
    mapping(uint256 => string[4]) public sunsetGradientColors;
    mapping(uint256 => string[4]) public sunsetGradientOffsets;
    mapping(uint256 => string[4]) public nightGradientColors;
    mapping(uint256 => string[4]) public nightGradientOffsets;

    constructor(address _n)  ERC721("Mount n", "MN") Ownable() {
        require(_n != address(0), "zero address");
        n = _n;
        
        morningGradientColors[0] = ["#F1C5BA", "#F28066", "#F27243", "#463D58"];
        morningGradientColors[1] = ["#E5E4F2", "#F2C8DC", "#D8BAD4", "#BAC2D9"];
        morningGradientColors[2] = ["#EEEAE7", "#F2A595", "#6C7999", "#123E59"];
        morningGradientOffsets[0] = ["0.219958", "0.447917", "0.552083", "1"];
        morningGradientOffsets[1] = ["0.219958", "0.447917", "0.651042", "1"];
        morningGradientOffsets[2] = ["0.229167", "0.515625", "0.770833", "1"];

        noonGradientColors[0] = ["#0377A6", "#048ABF", "#04B1D9", "#BDE2F2"];
        noonGradientColors[1] = ["#0468BE", "#3477AB", "#0577BE", "#A8D5F2"];
        noonGradientColors[2] = ["#024C8B", "#03598C", "#6A97C0", "#ACC5D9"];
        noonGradientOffsets[0] = ["0.00520833", "0.255208", "0.463542", "1"];
        noonGradientOffsets[1] = ["0", "0.171875", "0.385417", "1"];
        noonGradientOffsets[2] = ["0", "0.203125", "0.609375", "1"];

        sunsetGradientColors[0] = ["#048CD9", "#E1BCBC", "#F2786D", "#F25E6C"];
        sunsetGradientColors[1] = ["#F29F05", "#F28705", "#F25C05", "#F24405"];
        sunsetGradientColors[2] = ["#C0343F", "#F2782F", "#F25D3D", "#8D456D"];
        sunsetGradientOffsets[0] = ["0", "0.682292", "0.901042", "1"];
        sunsetGradientOffsets[1] = ["0.219958", "0.447917", "0.651042", "1"];
        sunsetGradientOffsets[2] = ["0.09375", "0.572917", "0.739583", "1"];

        nightGradientColors[0] = ["#011226", "#1A3059", "#581C1C", "#5F5174"];
        nightGradientColors[1] = ["#011226", "#0E1E40", "#234573", "#635578"];
        nightGradientColors[2] = ["#0D0D0D", "#012325", "#386874", "#90A7AC"];
        nightGradientOffsets[0] = ["0.229167", "0.515625", "0.765625", "0.953125"];
        nightGradientOffsets[1] = ["0.219958", "0.399439", "0.669075", "1"];
        nightGradientOffsets[2] = ["0", "0.1875", "0.703125", "1"];
    }
    
    function getColor(uint256 first, uint256 valueIndex) internal view returns(string memory) { 
        uint256 paletteIndex = (first + block.timestamp) % 4;
        uint256 colorsIndex = (first + block.timestamp) % 3;
        if (paletteIndex == 0) {
            return morningGradientColors[colorsIndex][valueIndex];
        }
        if (paletteIndex == 1) {
            return noonGradientColors[colorsIndex][valueIndex];
        }
        if (paletteIndex == 2) {
            return sunsetGradientColors[colorsIndex][valueIndex];
        }
        return nightGradientColors[colorsIndex][valueIndex];
    }

    function getOffset(uint256 first, uint256 valueIndex) internal view returns(string memory) { 
        uint256 paletteIndex = (first + block.timestamp) % 4;
        uint256 offsetsIndex = (first + block.timestamp) % 3;
        if (paletteIndex == 0) {
            return morningGradientOffsets[offsetsIndex][valueIndex];
        }
        if (paletteIndex == 1) {
            return noonGradientOffsets[offsetsIndex][valueIndex];
        }
        if (paletteIndex == 2) {
            return sunsetGradientOffsets[offsetsIndex][valueIndex];
        }
        return nightGradientOffsets[offsetsIndex][valueIndex];
    }

    function getCoordinate(uint256 number) internal pure returns(uint256) { 
        return 220 + 43 * (14 - number);
    } 
    
    function generateSVG(uint256 tokenId) public view returns(string memory) { 
        uint256 first = iN(n).getFirst(tokenId);
        string [58] memory parts;
        
        parts[0] = '<svg id="chartSvg" width="1000" height="1000" viewBox="0 0 1000 1000" fill="none" xmlns="http://www.w3.org/2000/svg"><mask id="mask0" style="mask-type: alpha" maskUnits="userSpaceOnUse" x="100" y="100" width="800" height="800"><circle cx="500" cy="500" r="400" fill="#C4C4C4"></circle></mask><g mask="url(#mask0)"><path d="M500 900C720.914 900 900 720.914 900 500C900 279.086 720.914 100 500 100C279.086 100 100 279.086 100 500C100 720.914 279.086 900 500 900Z" fill="url(#paint0_linear)"></path><path id="path0" d="M214,';
        parts[1] = toString(getCoordinate(iN(n).getSecond(tokenId)));
        parts[2] = ' L70,';
        parts[3] = toString(getCoordinate(iN(n).getFirst(tokenId)));
        parts[4] = ' V995H920V';
        parts[5] = toString(getCoordinate(iN(n).getEight(tokenId)));
        parts[6] = ' L780,';
        parts[7] = toString(getCoordinate(iN(n).getSeventh(tokenId)));
        parts[8] = ' L670,';
        parts[9] = toString(getCoordinate(iN(n).getSixth(tokenId)));
        parts[10] = ' L556,';
        parts[11] = toString(getCoordinate(iN(n).getFifth(tokenId)));
        parts[12] = ' L442,';
        parts[13] = toString(getCoordinate(iN(n).getFourth(tokenId)));
        parts[14] = ' L328,';
        parts[15] = toString(getCoordinate(iN(n).getThird(tokenId)));
        parts[16] = ' L214,';
        parts[17] = toString(getCoordinate(iN(n).getSecond(tokenId)));
        parts[18] = 'Z" fill="white" fill-opacity="0.7"></path><path id="path1" d="M70,';
        parts[19] = toString(getCoordinate(iN(n).getFirst(tokenId)));
        parts[20] = ' L 214,';
        parts[21] = toString(getCoordinate(iN(n).getSecond(tokenId)));
        parts[22] = ' L 328,';
        parts[23] = toString(getCoordinate(iN(n).getThird(tokenId)));
        parts[24] = ' L 442,';
        parts[25] = toString(getCoordinate(iN(n).getFourth(tokenId)));
        parts[26] = ' L 556,';
        parts[27] = toString(getCoordinate(iN(n).getFifth(tokenId)));
        parts[28] = ' L 670,';
        parts[29] = toString(getCoordinate(iN(n).getSixth(tokenId)));
        parts[30] = ' L 780,';
        parts[31] = toString(getCoordinate(iN(n).getSeventh(tokenId)));
        parts[32] = ' L 920,';
        parts[33] = toString(getCoordinate(iN(n).getEight(tokenId)));
        parts[34] = '" stroke="url(#paint1_linear)" stroke-width="40"></path>';
        parts[35] = '</g>';
        parts[36] = '<defs>';
        parts[37] = '<linearGradient id="paint0_linear" x1="500" y1="100" x2="500" y2="900" gradientUnits="userSpaceOnUse">';
        parts[38] = '<stop id="color0" offset="';
        parts[39] = getOffset(first, 0);
        parts[40] = '" stop-color="';
        parts[41] = getColor(first, 0);
        parts[42] = '"></stop>';
        parts[43] = '<stop id="color1" offset="';
        parts[44] = getOffset(first, 1);
        parts[45] = '" stop-color="';
        parts[46] = getColor(first, 1);
        parts[47] = '"></stop>';
        parts[48] = '<stop id="color2" offset="';
        parts[49] = getOffset(first, 2);
        parts[50] = '" stop-color="';
        parts[51] = getColor(first, 2);
        parts[52] = '"></stop>';
        parts[53] = '<stop id="color3" offset="';
        parts[54] = getOffset(first, 3);
        parts[55] = '" stop-color="';
        parts[56] = getColor(first, 3);
        parts[57] = '"></stop></linearGradient><linearGradient id="paint1_linear" x1="501" y1="308" x2="501" y2="735" gradientUnits="userSpaceOnUse"><stop stop-color="white"></stop><stop offset="1" stop-color="white" stop-opacity="0"></stop></linearGradient></defs></svg>';

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8])
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[17],
                parts[18],
                parts[19],
                parts[20],
                parts[21],
                parts[22],
                parts[23],
                parts[24]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[25],
                parts[26],
                parts[27],
                parts[28],
                parts[29],
                parts[30],
                parts[31],
                parts[32]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[33],
                parts[34],
                parts[35],
                parts[36],
                parts[37],
                parts[38],
                parts[39],
                parts[40]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[41],
                parts[42],
                parts[43],
                parts[44],
                parts[45],
                parts[46],
                parts[47],
                parts[48]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[49],
                parts[50],
                parts[51],
                parts[52],
                parts[53],
                parts[54],
                parts[55],
                parts[56]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[57]
            )
        );

        return output;
    } 

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Mount n #',
                        toString(tokenId),
                        '", "description": "Just mountains with n.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(generateSVG(tokenId))),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));

    }
    
    function claim(uint256 tokenId) public nonReentrant {
        require(IERC721(n).ownerOf(tokenId) == msg.sender, "Not an owner");
        require(tokenId > 0 && tokenId < 8889, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
