// SPDX-License-Identifier: MIT
/// @title AutoglyphsRenderer
/// @notice Autoglyphs Renderer
/// @author CyberPnk <cyberpnk@autoglyphsrenderer.cyberpnk.win>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.16;

// error EmptyArray();
// error GlueOutOfBounds(uint256 length);

import "./IStringUtilsV3.sol";
import "./IAutoglyphs.sol";
// import "./Array.sol";
import "./strings.sol";

// import "./console.sol";
contract AutoglyphsRenderer {
    using strings for *;

    // using Array for string[];

    IStringUtilsV3 public stringUtils;
    IAutoglyphs public autoglyphs;

    string[] private strNums = [
        "00", "01", "02", "03", "04", "05", "06", "07", "08", "09",
        "10", "11", "12", "13", "14", "15", "16", "17", "18", "19",
        "20", "21", "22", "23", "24", "25", "26", "27", "28", "29",
        "30", "31", "32", "33", "34", "35", "36", "37", "38", "39",
        "40", "41", "42", "43", "44", "45", "46", "47", "48", "49",
        "50", "51", "52", "53", "54", "55", "56", "57", "58", "59",
        "60", "61", "62", "63", "64"
    ];

    constructor(address stringUtilsContract, address autoglyphsContract) {
        stringUtils = IStringUtilsV3(stringUtilsContract);
        autoglyphs = IAutoglyphs(autoglyphsContract);
    }

    function getSvg(uint256 tokenId) public view returns (string memory) {
        bytes memory textGlyph = bytes(autoglyphs.draw(tokenId));
        require(textGlyph.length == 4318, "Wrong length");

        strings.slice[] memory svgLines = new strings.slice[](4098);
        svgLines[0] = 
                "<svg xmlns='http://www.w3.org/2000/svg' version='1.2' viewBox='0 0 640 640'>"
                    "<style>line,circle{stroke:black;stroke-width:2;stroke-linecap:square;stroke-opacity:1;transform:matrix(1,0,0,1,0,0);fill-opacity:1;fill:none;}rect{fill:black;}rect.bg{fill:white;}</style>"
                    "<rect x='0' y='0' width='640' height='640' fill='white' class='bg'/>".toSlice();
        for (uint16 rowIndex = 0; rowIndex < 64; rowIndex++) {
            string memory strRowIndex = strNums[rowIndex];
            string memory strRowIndexPlusOne = strNums[rowIndex + 1];
            for (uint16 colIndex = 0; colIndex < 64; colIndex++) {
                bytes1 glyph = bytes1(textGlyph[30 + rowIndex * 67 + colIndex]);
                string memory strColIndex = strNums[colIndex];
                string memory strColIndexPlusOne = strNums[colIndex + 1];
                if (glyph == 'O') {
                    svgLines[rowIndex * 64 + colIndex + 1] = 
                        string(abi.encodePacked("<circle cx='", strColIndex, "5' cy='", strRowIndex, "5' r='5'/>"))
                        .toSlice();
                } else if (glyph == '+') {
                    svgLines[rowIndex * 64 + colIndex + 1] = 
                        string(
                            abi.encodePacked(
                                abi.encodePacked("<line x1='", strColIndex, "5' y1='", strRowIndex, "0' x2='", strColIndex, "5' y2='", strRowIndexPlusOne, "0'/>"),
                                abi.encodePacked("<line x1='", strColIndex, "0' y1='", strRowIndex, "5' x2='", strColIndexPlusOne, "0' y2='", strRowIndex, "5'/>")
                            )
                        )
                        .toSlice();
                } else if (glyph == 'X') {
                    svgLines[rowIndex * 64 + colIndex + 1] = 
                        string(
                            abi.encodePacked(
                                abi.encodePacked("<line x1='", strColIndex, "0' y1='", strRowIndex, "0' x2='", strColIndexPlusOne, "0' y2='", strRowIndexPlusOne, "0'/>"),
                                abi.encodePacked("<line x1='", strColIndex, "0' y1='", strRowIndexPlusOne, "0' x2='", strColIndexPlusOne, "0' y2='", strRowIndex, "0'/>")
                            )
                        )
                        .toSlice();
                } else if (glyph == '|') {
                    svgLines[rowIndex * 64 + colIndex + 1] = 
                        string(abi.encodePacked("<line x1='", strColIndex, "5' y1='", strRowIndex, "0' x2='", strColIndex, "5' y2='", strRowIndexPlusOne, "0'/>"))
                        .toSlice();
                } else if (glyph == '-') {
                    svgLines[rowIndex * 64 + colIndex + 1] = 
                        string(abi.encodePacked("<line x1='", strColIndex, "0' y1='", strRowIndex, "5' x2='", strColIndexPlusOne, "0' y2='", strRowIndex, "5'/>"))
                        .toSlice();
                } else if (glyph == '\\') {
                    svgLines[rowIndex * 64 + colIndex + 1] = 
                        string(abi.encodePacked("<line x1='", strColIndex, "0' y1='", strRowIndex, "0' x2='", strColIndexPlusOne, "0' y2='", strRowIndexPlusOne, "0'/>"))
                        .toSlice();
                } else if (glyph == '/') {
                    svgLines[rowIndex * 64 + colIndex + 1] = 
                        string(abi.encodePacked("<line x1='", strColIndex, "0' y1='", strRowIndexPlusOne, "0' x2='", strColIndexPlusOne, "0' y2='", strRowIndex, "0'/>"))
                        .toSlice();
                } else if (glyph == '#') {
                    svgLines[rowIndex * 64 + colIndex + 1] = 
                        string(abi.encodePacked("<rect x='", strColIndex, "0' y='", strRowIndex,"0' width='10' height='10'/>"))
                        .toSlice();
                } else {
                    svgLines[rowIndex * 64 + colIndex + 1] = ''.toSlice();
                }
            }
        }
        svgLines[4097] = '</svg>'.toSlice();
        return ''.toSlice().join(svgLines);

    }

    function getDataUriSvg(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;utf8,", getSvg(tokenId)));
    }

    function getDataUriBase64(uint256 tokenId) public view returns (string memory) {
        return stringUtils.base64EncodeSvg(bytes(getSvg(tokenId)));
    }

    function getEmbeddableSvg(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked('<image x=0 y=0 height=640 href="', getDataUriSvg(tokenId), '"/>'));
    }

    function getTraitsJsonValue(uint256) public pure returns(string memory) {
        return '{"On Chain":"Yes"}';
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        string memory strtokenId = stringUtils.numberToString(tokenId);

        string memory image = getSvg(tokenId);

        string memory traitsStr = getTraitsJsonValue(tokenId);

        bytes memory json = abi.encodePacked(
            'data:application/json;utf8,{'
                '"title": "Autoglyph #', strtokenId, '",'
                '"name": "Autoglyph #', strtokenId, '",'
                '"image": "data:image/svg+xml,', image, '",'
                '"traits": [ ', traitsStr, '],'
                '"description": "Autoglyphs are the first on-chain generative art on the Ethereum blockchain. A completely self-contained mechanism for the creation and ownership of an artwork."'
            '}'
        );

        // return stringUtils.base64EncodeJson(json);
        return string(json);
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return autoglyphs.ownerOf(_tokenId);
    }

}




