// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Base64.sol";
import "./Strings.sol";
import "./XandaoTypes.sol";
import "./Trigonometry.sol";

// code to generate the SVG taking the 36 colors as input
contract XandaoMeta {
    using Strings for uint256;
    using Strings for uint8;
    using Strings for int256;

    enum Colors {
        NONE, // colorIndex = 0
        CYAN, // colorIndex = 1
        MAGENTA, // colorIndex = 2
        YELLOW, // colorIndex = 3
        BLACK, // colorIndex = 4
        WHITE, // colorIndex = 5
        TRANSPARENT // colorIndex = 6
    }

    // Spiral key to map the 36 digits of the tokenID to the corresponding 36 cells in the grid
    uint8[] SPIRAL_KEY = [21, 15, 16, 22, 28, 27, 26, 20, 14, 8, 9, 10, 11, 17, 23, 29, 35, 34, 33, 32, 31, 25, 19, 13, 7, 1, 2, 3, 4, 5, 6, 12, 18, 24, 30, 36];
    string constant BASE_PART2 = "</g></svg>";

    // Token prices by Level - Array index is token level, price is a geomoetric progression from 0.006 to 6.000 ETH
    string[] LEVEL_PRICES = [
        "0.000","0.006","0.007","0.009","0.011","0.013","0.016","0.020","0.024","0.029",
        "0.035","0.043","0.053","0.064","0.078","0.095","0.116","0.141","0.172","0.209",
        "0.255","0.311","0.379","0.461","0.562","0.684","0.834","1.016","1.237","1.507",
        "1.836","2.237","2.725","3.319","4.043","4.925","6.000"
    ];

    function _checkTokenId(uint256 rawTokenId) internal pure returns(uint256 id, uint8 len) {
        // remove trailing 6's
        while (rawTokenId % 10 == 6) {
            rawTokenId /= 10;
        }

        uint256 tokenId = rawTokenId;

        require(
            tokenId >= 1 && tokenId < 10 ** 36,
            "Invalid token length"
        );

        //get number of digits
        uint8 tokenIdLen = uint8(bytes(tokenId.toString()).length);

        // verify digits are between 1-6
        for (uint8 i = 0; i < tokenIdLen; i++) {
            // Get the i-th digit of tokenPattern
            uint256 digit = (tokenId / (10 ** i)) % 10;

            // Check if the digit is between 1-6
            require(
                digit >= 1 && digit <= 6,
                "Invalid token digit value"
            );
        }
        return (tokenId, tokenIdLen);
    }
    
    // Function to get the 'max' grid size based on the number of digits in the tokenID
    function getGridSize(uint8 tokenIdLen) public pure returns (string memory) {
        string memory gridSize;
        if (tokenIdLen == 1) {
            gridSize = '1x1';
        } else if (tokenIdLen >= 2 && tokenIdLen <= 4) {
            gridSize = '2x2';
        } else if (tokenIdLen >= 5 && tokenIdLen <= 9) {
            gridSize = '3x3';
        } else if (tokenIdLen >= 10 && tokenIdLen <= 16) {
            gridSize = '4x4';
        } else if (tokenIdLen >= 17 && tokenIdLen <= 25) {
            gridSize = '5x5';
        } else {
            gridSize = '6x6';
        }
        return gridSize;
    }

    // The SVG viewbox ensures that the image is always centered on the corresponding grid, with a padding of 7.5" on all sides
    function getViewBox(uint8 tokenIdLen) public pure returns (string memory) {
        string memory viewBox;
        if (tokenIdLen == 1) {
            viewBox = '2.17 2.87 1.67 1.67';
        } else if (tokenIdLen >= 2 && tokenIdLen <= 4) {
            viewBox = '1.33 1.33 3.34 3.34';
        } else if (tokenIdLen >= 5 && tokenIdLen <= 9) {
            viewBox = '0.53 1.23 4.95 4.95';
        } else if (tokenIdLen >= 10 && tokenIdLen <= 16) {
            viewBox = '-0.34 -0.34 6.67 6.67'; 
        } else if (tokenIdLen >= 17 && tokenIdLen <= 25) {
            viewBox = '-1.12 -0.44 8.28 8.28'; 
        } else {
            viewBox = '-1.95 -1.95 9.89 9.89'; 
        }
        return viewBox;
    }

    function getBackgroundColor(uint8 tokenIdLen) public pure returns (string memory) {
        string memory bgColor;
        if (tokenIdLen == 1) {
            bgColor = 'B3E6E6';
        } else if (tokenIdLen >= 2 && tokenIdLen <= 4) {
            bgColor = 'E6B3E6';
        } else if (tokenIdLen >= 5 && tokenIdLen <= 9) {
            bgColor = 'E6E6B3';
        } else if (tokenIdLen >= 10 && tokenIdLen <= 16) {
            bgColor = '4D4D4D';
        } else if (tokenIdLen >= 17 && tokenIdLen <= 25) {
            bgColor = 'E6E6E6';
        } else {
            bgColor = '808080';
        }
        return bgColor;
    }

    function _basePart1(uint8 tokenIdLen) private pure returns(string memory) {
        string memory viewBox = getViewBox(tokenIdLen);
        string memory basePart1 = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' version='1.2' viewBox='",
                viewBox,
                "' width='100%' height='100%' shape-rendering='crispEdges'><g transform='rotate(-45 3 3)'>"
            )
        );
        return basePart1;
    }

    // create the SVG string from tokenID, which will be stored directly on the blockchain
    function generateSVG(uint256 rawTokenId) public view returns (string memory) {
        (uint256 tokenId, uint8 tokenIdLen) = _checkTokenId(rawTokenId);
        string memory svgContent = _basePart1(tokenIdLen);
        uint256 paddedId = _handlePadding(tokenId);
        for (uint i = 0; i < 36; i++) {
            uint spiralIndex = SPIRAL_KEY[i] - 1;
            uint8 colorIndex = uint8((paddedId / 10 ** (36 - i - 1)) % 10);
            string memory x = (spiralIndex % 6).toString();
            string memory y = (spiralIndex / 6).toString();
            string memory rectangle = string(
                abi.encodePacked(
                    "<rect id='",
                    (spiralIndex + 1).toString(),
                    "' fill='",
                    _getColor(colorIndex),
                    "' x='",
                    x,
                    "' y='",
                    y,
                    "' width='1' height='1'></rect>"
                )
            );
            svgContent = string(abi.encodePacked(svgContent, rectangle));
        }
        svgContent = string(abi.encodePacked(svgContent, BASE_PART2));
        return svgContent;
    }

    function generateFullXn(
        uint256 xn,
        string memory xnVersion
    ) public pure returns (string memory) {
        string memory fullXn;
        if (keccak256(abi.encodePacked(xnVersion)) == keccak256(abi.encodePacked('a'))) {
            fullXn = xn.toString();
        } else {
            fullXn = string.concat(xn.toString(), "-", xnVersion);
        }
        return fullXn;
    }

    function _handlePadding(uint256 tokenId) private pure returns (uint256) {
        //get number of digits
        uint8 numDigits = 0;
        uint256 temp = tokenId;
        while (temp != 0) {
            numDigits++;
            temp /= 10;
        }
        //add 6's as padding for anyting lass than 36 digits
        uint256 paddedId = tokenId;
        uint8 padding = 36 - numDigits;
        for (uint8 i = 0; i < padding; i++) {
            paddedId = paddedId * 10 + 6;
        }
        return paddedId;
    }

    //get array of digit value counts
    function _getDigitCounts(
        uint256 tokenPattern
    ) private pure returns (uint8[6] memory) {
        uint8[6] memory digitCounts;
        for (uint8 i = 0; i < 36; i++) {
            uint256 digit = (tokenPattern / (10 ** i)) % 10;
            digitCounts[digit - 1] += 1;
        }
        return digitCounts;
    }

    function _getColor(uint8 colorIndex) private pure returns (string memory) {
        if (colorIndex == uint8(Colors.CYAN)) {
            return "cyan";
        } else if (colorIndex == uint8(Colors.MAGENTA)) {
            return "magenta";
        } else if (colorIndex == uint8(Colors.YELLOW)) {
            return "yellow";
        } else if (colorIndex == uint8(Colors.BLACK)) {
            return "black";
        } else if (colorIndex == uint8(Colors.WHITE)) {
            return "white";
        } else {
            return "transparent";
        }
    }

    function _getColorHSL(uint8 colorIndex) private pure returns (uint256 h, uint256 s, uint256 l) {
        if (colorIndex == uint8(Colors.CYAN)) {
            return (uint256(180), uint256(100), uint256(50));
        } else if (colorIndex == uint8(Colors.MAGENTA)) {
            return (uint256(300), uint256(100), uint256(50));
        } else if (colorIndex == uint8(Colors.YELLOW)) {
            return (uint256(60), uint256(100), uint256(50));
        } else if (colorIndex == uint8(Colors.BLACK)) {
            return (uint256(0), uint256(0), uint256(0));
        } else if (colorIndex == uint8(Colors.WHITE)) {
            return (uint256(0), uint256(0), uint256(100));
        } else {
            return (uint256(0), uint256(0), uint256(0));
        }
    }

    // Function to calculate the average HSL value for composite color
    function _averageHSL(uint8[6] memory digitCounts) private pure returns (string memory) {
        uint256 coloredCells = digitCounts[0] +
            digitCounts[1] +
            digitCounts[2] +
            digitCounts[3] +
            digitCounts[4];
        uint256 totalCells = coloredCells;
        uint256 valueCap = totalCells * 100;

        int256 avgHueSin = 0;
        int256 avgHueCos = 0;
        uint256 avgSat = 0;
        uint256 avgLight = 0;

        for (uint8 i = 0; i < 5; i++) {
            uint8 colorIndex = i + 1;
            (uint256 h, uint256 s, uint256 l) = _getColorHSL(colorIndex);

            int256 weight = int256(uint(digitCounts[i]));
            avgHueSin += int256(
                weight * Trigonometry.sin((h * 2 * Trigonometry.PI) / 360)
            );
            avgHueCos += int256(
                weight * Trigonometry.cos((h * 2 * Trigonometry.PI) / 360)
            );
            avgSat += s * uint256(weight);
            avgLight += l * uint256(weight);
        }

        uint256 avgHue;
        int hueSigned = (Trigonometry.atan2(avgHueSin, avgHueCos) * 360) /
            int256(2 * Trigonometry.PI);
        if (hueSigned < 0) {
            avgHue = uint256(360) - uint256(Trigonometry.abs(hueSigned));
        } else {
            avgHue = uint256(hueSigned);
        }
        avgHue = (avgHue + 360) % 360;

        avgSat = ((avgSat) * 100) / (valueCap);
        avgLight = ((avgLight) * 100) / (valueCap);

        string memory hslString = string(
            abi.encodePacked(
                "hsl(",
                avgHue.toString(),
                ", ",
                avgSat.toString(),
                "%, ",
                avgLight.toString(),
                "%)"
            )
        );
        return hslString;
    }

    function generateTokenURI(
        uint256 rawTokenId,
        TokenInfo memory TokenObj
    ) public view returns (string memory) {
        uint256 paddedId = _handlePadding(rawTokenId);
        (uint256 tokenId, uint8 tokenIdLen) = _checkTokenId(rawTokenId);
        uint8[6] memory digitCounts = _getDigitCounts(paddedId);
        uint256 level = 37 - tokenIdLen;
        string memory gridSize = getGridSize(tokenIdLen);
        string memory bgColor = getBackgroundColor(tokenIdLen);
        string memory fullXn = generateFullXn(TokenObj.xn, TokenObj.xnVersion);

        string memory attributes = string(
            abi.encodePacked(
                '"attributes":[',
                '{"trait_type":"level","value":"', level.toString(), '"},',
                '{"trait_type":"value","value":"', LEVEL_PRICES[level], '"},',
                '{"trait_type":"grid","value":"', gridSize, '"},',
                '{"trait_type":"creator address","value":"', Strings.toHexString(TokenObj.creator), '"},',
                '{"trait_type":"creator name","value":"', TokenObj.creatorName, '"},',
                '{"trait_type":"composite color","value":"', _averageHSL(digitCounts), '"},',
                '{"trait_type":"1-cyan","value":', digitCounts[0].toString(), ',"max_value":36},',
                '{"trait_type":"2-magenta","value":', digitCounts[1].toString(), ',"max_value":36},',
                '{"trait_type":"3-yellow","value":', digitCounts[2].toString(), ',"max_value":36},',
                '{"trait_type":"4-black","value":', digitCounts[3].toString(), ',"max_value":36},',
                '{"trait_type":"5-white","value":', digitCounts[4].toString(), ',"max_value":36}',
                ']'
            )
        );

        bytes memory dataURI = abi.encodePacked(
            '{',
            '"name":"xn-', fullXn, '",',
            '"description":"\\"', TokenObj.description, '\\" by ', TokenObj.creatorName, '",',
            '"image":"data:image/svg+xml;utf8,', generateSVG(tokenId), '",',
            '"background_color":"', bgColor, '",',
            '"external_url":"https://pixels.xandao.com/view?id=', tokenId.toString(), '",',
            attributes,
            '}'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }
}
