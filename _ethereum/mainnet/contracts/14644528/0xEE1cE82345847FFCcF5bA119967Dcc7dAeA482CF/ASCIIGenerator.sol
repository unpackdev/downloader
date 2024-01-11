// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Strings.sol";
import "./Ownable.sol";
import "./Base64.sol";

contract ASCIIGenerator is Ownable {
    using Base64 for string;
    using Strings for uint256;

    uint256 [][] public imageRows;
    string internal description = "MEV Army Legion Banners by x0r are fully on-chain and customizable. Banners are legion owned, and when you customize a banner, it will change for everyone who owns that banner.";
    string internal SVGHeaderPartOne = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1500 550'><defs><style>.cls-1{font-size: 10px; fill:";
    string internal SVGHeaderPartTwo = ";font-family: monospace}</style></defs><g><rect width='1500' height='550' fill='black' />";
    string internal firstTextTagPart = "<text lengthAdjust='spacing' textLength='1500' class='cls-1' x='0' y='";
    string internal SVGFooter = "</g></svg>";
    uint256 internal tspanLineHeight = 12;


    //================== ASCII GENERATOR FUNCTIONS ==================

    /** 
    * @notice Generates full metadata
    */
    function generateMetadata(string memory _legionName, uint256 _legion, string memory _fillChar, string memory _color) public view returns (string memory){
        string memory SVG = generateSVG(_legion, _fillChar, _color);

        string memory metadata = Base64.encode(bytes(string(abi.encodePacked('{"name":"', _legionName, ' Banner','","description":"', description,'","image":"', SVG, '"}'))));
        
        return string(abi.encodePacked('data:application/json;base64,', metadata));
    }

    /** 
    * @notice Generates the SVG image
    */
    function generateSVG(uint256 _legion, string memory _fillChar, string memory _color) public view returns (string memory){

        // generate core ascii text 
        string [45] memory rows = generateCoreAscii(_legion, _fillChar);

        // create SVG header with the text color of the given legion
        string memory SVGHeader = string(abi.encodePacked(SVGHeaderPartOne, _color, SVGHeaderPartTwo));

        // read text tag into memory
        string memory _firstTextTagPart = firstTextTagPart;

        string memory center;
        string memory span;
        uint256 y = tspanLineHeight;

        // generate SVG elements
        for(uint256 i; i < rows.length; i++){
            span = string(abi.encodePacked(_firstTextTagPart, y.toString(), "'>", rows[i], "</text>")); 
            center = string(abi.encodePacked(center, span));
            y += tspanLineHeight;
        }

        // Base64 encode the SVG text 
        string memory SVGImage = Base64.encode(bytes(string(abi.encodePacked(SVGHeader, center, SVGFooter))));
        return string(abi.encodePacked('data:image/svg+xml;base64,', SVGImage));
    }

    /** 
    * @notice Generates all ASCII rows of the image
    */
    function generateCoreAscii(uint256 _legion, string memory _fillChar) public view returns (string [45] memory){
        string [45] memory asciiImage;

        for (uint256 i; i < asciiImage.length; i++) {
            asciiImage[i] = rowToString(imageRows[_legion - 1][i], _fillChar);
        }
        
        return asciiImage;
    }

    /** 
    * @notice Generates one ASCII row as a string
    */
    function rowToString(uint256 _row, string memory _fillchar) internal pure returns (string memory){
        string memory rowString;
        
        for (uint256 i; i < 250; i++) {
            if ( ((_row >> 1 * i) & 1) == 0) {
                rowString = string(abi.encodePacked(rowString, "."));
            } else {
                rowString = string(abi.encodePacked(rowString, _fillchar));
            }
        }

        return rowString;
    }


    
    //================== STORE IMAGE DATA ==================

    function storeImageStores(uint256 [][] memory _imageRows) external onlyOwner {
        imageRows = _imageRows;
    }

    function setDescription(string calldata _description) external onlyOwner {
        description = _description;
    }

    function setSVGParts(
        uint256 _tspanLineHeight, 
        string calldata _SVGHeaderPartOne, 
        string calldata _SVGHeaderPartTwo,
        string calldata _firstTextTagPart,
        string calldata _SVGFooter) external onlyOwner {
            tspanLineHeight = _tspanLineHeight;
            SVGHeaderPartOne = _SVGHeaderPartOne;
            SVGHeaderPartTwo = _SVGHeaderPartTwo;
            firstTextTagPart = _firstTextTagPart;
            SVGFooter = _SVGFooter;
    }

    function getSVGParts() external view returns (string memory, string memory, string memory, string memory, uint256){
        return (SVGHeaderPartOne, SVGHeaderPartTwo, firstTextTagPart, SVGFooter, tspanLineHeight);
    }

}