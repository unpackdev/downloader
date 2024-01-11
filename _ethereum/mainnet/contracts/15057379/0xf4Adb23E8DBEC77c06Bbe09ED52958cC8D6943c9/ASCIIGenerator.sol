// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @author: x0r - Michael Blau

import "./Strings.sol";
import "./Ownable.sol";
import "./Base64.sol";

contract ASCIIGenerator is Ownable {
    using Base64 for string;
    using Strings for uint256;

    uint256[] public imageRows;


    string internal description = "Basefee is a fully on-chain dynamic NFT that is a visual representation of the ETH burned in every transaction due to EIP-1559. The ASCII image is of a fire with Ethereum flames composed of the current basefee of the network. The ASCII will update every block to display the current basefee using the BASEFEE EVM opcode.";
    string internal SVGHeader =
        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 600 670'><defs><style>.cls-1{font-size: 10px; fill: white; font-family:monospace;}</style></defs><g><rect width='600' height='670' fill='black' />";
    string internal firstTextTagPart = "<text lengthAdjust='spacing' textLength='600' class='cls-1' x='0' y='";
    string internal SVGFooter = "</g></svg>";
    string internal separator = "/";
    uint256 internal tspanLineHeight = 12;


    // =================== ASCII GENERATOR FUNCTIONS =================== //

    /** 
     * @notice Generates full metadata
     */
    function generateMetadata(uint256 _tokenId, uint256 _maxSupply) public view returns (string memory){
        string memory SVG = generateSVG();

        string memory metadata = Base64.encode(bytes(string.concat('{"name": "Basefee #', _tokenId.toString(),'/', _maxSupply.toString(), '","description":"', description,'","image":"', SVG, '"}')));
        
        return string.concat('data:application/json;base64,', metadata);
    }

    /**
     * @notice Generates the SVG image
     */
    function generateSVG() public view returns (string memory) {
        // generate core ascii text
        string[55] memory rows = genCoreAscii();

        // read text tag into memory
        string memory _firstTextTagPart = firstTextTagPart;
        string memory center;
        string memory span;
        uint256 y = tspanLineHeight;

        // generate SVG elements
        for (uint256 i; i < rows.length; i++) {
            span = string.concat(_firstTextTagPart, y.toString(), "'>", rows[i],"</text>");
            center = string.concat(center, span);
            y += tspanLineHeight;
        }

        // base64 encode the SVG text
        string memory SVGImage = Base64.encode(
            bytes(string.concat(SVGHeader, center, SVGFooter))
        );

        return string.concat("data:image/svg+xml;base64,", SVGImage);
    }

    /** 
     * @notice Generates all ASCII rows of the image
     */
    function genCoreAscii() public view returns (string[55] memory) {
        string[55] memory asciiImage;

        // get current block basefee and convert to a string array
        uint256 basefee = uint256(block.basefee) / 1e9;
        string[] memory baseFeeArray = toStringArray(toNumArray(basefee));

        for (uint256 i; i < asciiImage.length; i++) {
            asciiImage[i] = rowToString(imageRows[i], baseFeeArray);
        }

        return asciiImage;
    }

    /** 
     * @notice Generates one ASCII row as a string
     */
    function rowToString(uint256 _row, string[] memory _baseFeeArray)
        internal
        pure
        returns (string memory)
    {
        string memory rowString;
        uint256 lastIndex;

        for (uint256 i; i < 100; i++) {
            if (((_row >> (1 * i)) & 1) == 0) {
                rowString = string.concat(rowString, ".");
            } else {
                rowString = string.concat(rowString, _baseFeeArray[lastIndex % _baseFeeArray.length]);
                lastIndex++;
            }
        }

        return rowString;
    }


    // =================== ASCII UTILITY FUNCTIONS =================== //

    /**
     * @notice converts an array of numbers to an array of strings plus a separator string
     */
    function toStringArray(uint256[] memory _numArray)
        internal
        view
        returns (string[] memory)
    {
        string[] memory strArray = new string[](1 + _numArray.length);

        for (uint256 i; i < strArray.length - 1; i++) {
            strArray[i] = _numArray[i].toString();
        }

        strArray[strArray.length - 1] = separator;
        return strArray;
    }

    /**
     * @notice convert a number to an array containing each digit of the number
     */
    function toNumArray(uint256 _value)
        internal
        pure
        returns (uint256[] memory)
    {
        if (_value == 0) {
            uint256[] memory _zero = new uint256[](1);
            _zero[0] = 0;
            return _zero;
        }

        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        uint256[] memory arr = new uint256[](digits);
        while (_value != 0) {
            digits -= 1;
            arr[digits] = uint256(_value % 10);
            _value /= 10;
        }
        return arr;
    }
    

    // =================== STORE IMAGE DATA =================== //

    function storeImageParts(uint256[] memory _imageRows) external onlyOwner {
        imageRows = _imageRows;
    }

    function setSVGParts(
        string calldata _SVGHeader,
        string calldata _SVGFooter,
        string calldata _firstTextTagPart,
        string calldata _separator,
        uint256 _tspanLineHeight
    ) external onlyOwner {
        SVGHeader = _SVGHeader;
        SVGFooter = _SVGFooter;
        firstTextTagPart = _firstTextTagPart;
        separator = _separator;
        tspanLineHeight = _tspanLineHeight;
    }

    function getSVGParts()
        external
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            uint256
        )
    {
        return (SVGHeader, SVGFooter, firstTextTagPart, separator, tspanLineHeight);
    }

    function setDescription(string calldata _description) external onlyOwner {
        description = _description;
    }

}
