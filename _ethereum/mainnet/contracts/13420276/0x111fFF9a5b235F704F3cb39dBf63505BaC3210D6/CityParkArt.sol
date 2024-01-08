// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Strings.sol";
import "./SafeMath.sol";

import "./CityParkUtils.sol";

library CityParkArt {

    using SafeMath for uint16;
    using Strings for uint256;
    using Strings for uint8;
    using Strings for uint16;

    function _generateFirstTriangle(CityParkUtils.ColorXY memory colorXY) private pure returns (string memory) {
        return string(abi.encodePacked( 
            "<polygon points='",
            (colorXY.x-50).toString(),
            ",",
            colorXY.y.toString(),
            ", ",
            (colorXY.x+25).toString(),
            ",",
            (colorXY.y-150).toString(),
            ", ",
            (colorXY.x+100).toString(),
            ",",
            colorXY.y.toString(),
            "' style='fill:",
            colorXY.color,
            "'/>"
        ));
    }

    function _generateSecondTriangle(CityParkUtils.ColorXY memory colorXY) private pure returns (string memory) {
        return string(abi.encodePacked( 
            "<polygon points='",
            (colorXY.x-70).toString(),
            ",",
            (colorXY.y+80).toString(),
            ", ",
            (colorXY.x+25).toString(),
            ",",
            (colorXY.y-70).toString(),
            ", ",
            (colorXY.x+120).toString(),
            ",",
            (colorXY.y+80).toString(),
            "' style='fill:",
            colorXY.color,
            "'/>"
        ));
    }

    function _generateTreeTriangles(CityParkUtils.ColorXY memory colorXY) private pure returns (string memory) {
      return string(abi.encodePacked(
            _generateFirstTriangle(colorXY),
            _generateSecondTriangle(colorXY)
      ));
    }

    function _generateTrees(CityParkUtils.Art memory artData) public pure returns (string memory) {
        string memory trees = '';
        for (uint i = 0; i < artData.numTrees; i++) {
            CityParkUtils.ColorXY memory colorXY = CityParkUtils.ColorXY({
                x: CityParkUtils.seededRandom(80,790,i*i,artData),
                y: CityParkUtils.seededRandom(150,500,i*i+1,artData),
                color: artData.overrideWhite ? CityParkUtils.getBWColor(i*2+3,artData) : CityParkUtils.getColor(i*2+3,artData)
            });
 
          trees = string(abi.encodePacked(
              trees,
              "<rect width='50' height='200' x='",
              colorXY.x.toString(),
              "' y='",
              colorXY.y.toString(),
              "'",
              " style='fill:",
              colorXY.color,
              "'/>",
              _generateTreeTriangles(colorXY)
            ));
        }

        return trees;
    }

    function _generateWindow(uint x, uint y, string memory color) private pure returns (string memory) {
        return string(abi.encodePacked(
            "<circle cx='",
            x.toString(),
            "' cy='",
            y.toString(),
            "' r='15' style='fill:",
            color,
            "' />"
        ));
    }

    function _generateWindows(CityParkUtils.Art memory artData, CityParkUtils.ColorXY memory colorXY) private pure returns (string memory) {
        string memory wc = CityParkUtils.getColor(artData.randomSeed+3, artData);
        return string(abi.encodePacked(
            _generateWindow(colorXY.x+80,colorXY.y,wc),
            _generateWindow(colorXY.x-80,colorXY.y,wc),
            _generateWindow(colorXY.x,colorXY.y,wc)
        ));
    }

    function _generateUFO(CityParkUtils.Art memory artData) public pure returns (string memory) {
        CityParkUtils.ColorXY memory colorXY = CityParkUtils.ColorXY({
            x: CityParkUtils.seededRandom(160,680,6,artData),
            y: CityParkUtils.seededRandom(60,300,9,artData),
            color: artData.overrideWhite ? CityParkUtils.getBWColor(69420,artData) : CityParkUtils.getColor(69420,artData)
        });

        return string(abi.encodePacked(
            "<ellipse rx='50' ry='80' cx='",
            colorXY.x.toString(),
            "' cy='",
            colorXY.y.toString(),
            "'",
            " style='fill:",
            colorXY.color,
            ";stroke-width:7;stroke:black'/>",
            "<ellipse rx='150' ry='50' cx='",
            colorXY.x.toString(),
            "' cy='",
            colorXY.y.toString(),
            "'",
            " style='fill:",
            colorXY.color,
            ";stroke-width:3;stroke:black'/>",
            "<ellipse rx='50' ry='80' cx='",
            colorXY.x.toString(),
            "' cy='",
            colorXY.y.toString(),
            "'",
            " style='fill:",
            colorXY.color,
            "'/>",
            _generateWindows(artData, colorXY)
        ));
    }

    function _generateSunLines(CityParkUtils.ColorXY memory colorXY) private pure returns (string memory) {
        string memory sunLines = '';
        for (uint16 i = 0; i < 8; i++) {
            sunLines = string(abi.encodePacked(
                sunLines,
                _generateSunLine(colorXY, uint16(i.mul(45)))
            ));
        }
        return sunLines;
    }

    function _generateSunLine(CityParkUtils.ColorXY memory colorXY, uint16 rotate) private pure returns (string memory) {
      return string(abi.encodePacked(
            "<path stroke='",
            colorXY.color,
            "' style='transform:rotate(",
            rotate.toString(),
            "deg);transform-origin:",
            colorXY.x.toString(),
            "px -",
            colorXY.y.toString(),
            "px' d='M",
            colorXY.x.toString(),
            " -",
            (colorXY.y+65).toString(),
            "V -",
            (colorXY.y+105).toString(),
            "' stroke-width='25' />"
      ));
    }

    function _generateSun(CityParkUtils.Art memory artData) public pure returns (string memory) {
        CityParkUtils.ColorXY memory colorXY = CityParkUtils.ColorXY({
            x: CityParkUtils.seededRandom(120,760,4,artData),
            y: CityParkUtils.seededRandom(0,200,20,artData),
            color: artData.overrideWhite ? CityParkUtils.getBWColor(6969,artData) : CityParkUtils.getColor(6969,artData)
        });

        return string(abi.encodePacked(
            "<circle  r='50' cx='",
            colorXY.x.toString(),
            "' cy='-",
            colorXY.y.toString(),
            "' style='fill:",
            colorXY.color,
            "'/>",
            _generateSunLines(colorXY)
        ));
    }

    function _generateRug(CityParkUtils.Art memory artData) public pure returns (string memory) {
        uint randDegrees =  CityParkUtils.seededRandom(0, 90, 199, artData);
        return string(abi.encodePacked(
            "<rect width='1200' height='1500' x='600' y='-460' style='fill:",
            artData.overrideWhite ? CityParkUtils.getBWColor(9876,artData) : CityParkUtils.getColor(9876,artData),
            ";stroke-width:3;stroke:black' transform='rotate(",
            randDegrees.toString(),
            ")'/>",
            _generateStripes(artData, string(abi.encodePacked("-", (90-randDegrees).toString())))
        ));
    }

    function _generateStripes(CityParkUtils.Art memory artData, string memory oppRotateStr) private pure returns (string memory) {
        string memory stripes = '';
        uint numStripes = CityParkUtils.seededRandom(1, 4, 666, artData);
        for (uint i = 0; i < numStripes; i++) {
            uint randomPlace = CityParkUtils.seededRandom(100, 1100, i*2+3, artData);
            string memory xString;
            if (randomPlace > 600) {
                xString = string(abi.encodePacked("-", (randomPlace-600).toString()));
            } else {
                xString = (600-randomPlace).toString();
            }

            stripes = string(abi.encodePacked(
                stripes,
                "<rect width='50' height='1500' x='",
                xString,
                "' y='600'",
                " style='fill:",
                CityParkUtils.getColor(i*i+3,artData),
                ";stroke-width:3;stroke:black' transform='rotate(",
                oppRotateStr,
                ")'/>"
            ));
        }
        return stripes;
    }

    function _generateAllBricks(CityParkUtils.Art memory artData) public pure returns (string memory) {
        uint numBrickStructures = CityParkUtils.seededRandom(1,3,5555555,artData);
        string memory allBricks = '';
        for (uint i = 0; i < numBrickStructures; i++) {
            bool xPos =  CityParkUtils.seededRandom(0,2,i*i+69,artData) > 1;
            uint randX = CityParkUtils.seededRandom(0,300,i*i+888,artData);

            string memory xString;
            if (xPos) {
                xString = randX.toString();
            } else {
                xString = string(abi.encodePacked("-", randX.toString()));
            }

            allBricks = string(abi.encodePacked(
                allBricks,
                "<g transform='translate(",
                xString,
                ",",
                CityParkUtils.seededRandom(0,600,i*i+777,artData).toString(),
                ")'>",
                _generateBricks(artData, i)
            ));
        }
        return allBricks;
    }

    function _generateBricks(CityParkUtils.Art memory artData, uint rand) private pure returns (string memory) {
        string memory bricks = '';
        CityParkUtils.ColorXY memory colorXY = CityParkUtils.ColorXY({
            x: 300,
            y: 600,
            color: artData.overrideWhite ? CityParkUtils.getBWColor(rand+6, artData) : CityParkUtils.getColor(rand+9, artData)
        });
        uint numBricks = CityParkUtils.seededRandom(1,10,rand*2,artData);
        uint height = CityParkUtils.seededRandom(0,10,rand*3+1,artData);
        if (height % 2 == 0) {
            height++;
        }

        // Single half brick beginning
        for (uint i = 0; i < height / 2 + 1; i++) {
            bricks = string(abi.encodePacked(
                bricks,
                "<rect width='50' height='40' x='300' y='",
                (640+(80*i)).toString(),
                "' style='fill:",
                colorXY.color,
                ";stroke-width:3;stroke:black' transform='skewY(-10)'/>"
            ));
        }

        // Main brick faces
        for (uint i = 0; i < numBricks; i++) {
            for (uint j = 0; j < height / 2 + 1; j++) {

                // Top row, full row
                bricks = string(abi.encodePacked(
                    bricks,
                    "<rect width='100' height='40' x='",
                    (300+(i*100)).toString(),
                    "' y='",
                    (600+(80*j)).toString(),
                    "' style='fill:",
                    colorXY.color,
                    ";stroke-width:3;stroke:black' transform='skewY(-10)'/>"
                ));
            }

            // Handle negative x value
            uint baseXPos = 495;
            uint xLocPos;
            uint xLocNeg;
            string memory xString;
            if (i >= 5) {
                xLocNeg = 5 + ((i-5)*100);
                xString = xLocNeg.toString();
            } else {
                xLocPos = baseXPos - (i*100);
                xString = string(abi.encodePacked("-", xLocPos.toString()));
            }

            // Top face
            bricks = string(abi.encodePacked(
                bricks,
                "<rect width='100' height='40' x='",
                xString,
                "' y='560' style='fill:",
                colorXY.color,
                ";stroke-width:3;stroke:black' transform='skewY(-10) skewX(53)'/>"
            ));

            if (i != numBricks-1) {
                for (uint j = 0; j < height / 2 + 1; j++) {
                    bricks = string(abi.encodePacked(
                        bricks,
                        "<rect width='100' height='40' x='",
                        (350+(i*100)).toString(),
                        "' y='",
                        (640+(80*j)).toString(),
                        "' style='fill:",
                        colorXY.color,
                        ";stroke-width:3;stroke:black' transform='skewY(-10)'/>"
                    ));
                }
            }
        }

        // Single half brick end
        for (uint i = 0; i < height / 2 + 1; i++) {
            bricks = string(abi.encodePacked(
                bricks,
                "<rect width='50' height='40' x='",
                (250+(numBricks*100)).toString(),
                "' y='",
                (640+(80*i)).toString(),
                "' style='fill:",
                colorXY.color,
                ";stroke-width:3;stroke:black' transform='skewY(-10)'/>"
            ));
        }


        // Brick left face
        for (uint i = 0; i < height+1; i++) {
            string memory yString = '';
            if (i >= 6) {
                yString = (600+(15+((i-6)*40))).toString();
            } else {
                yString = (600-(225-(i*40))).toString();
            }


            bricks = string(abi.encodePacked(
                bricks,
                "<rect width='50' height='40' x='250' y='",
                yString,
                "' style='fill:",
                colorXY.color,
                ";stroke-width:3;stroke:black' transform='skewY(30)'/>"
            ));
        }

        bricks = string(abi.encodePacked(bricks, '</g>'));
        return bricks;
    }

    function _generateFence(CityParkUtils.Art memory artData, uint rand) private pure returns (string memory) {
        string memory fence = '';
        uint howWide = CityParkUtils.seededRandom(1,7,rand+69,artData);

        for (uint i = 0; i < 3; i++) {
            fence = string(abi.encodePacked(
                fence,
                "<rect width='",
                (howWide*100).toString(),
                "' height='20' x='275' y='",
                (600+(50*i)).toString(),
                "' style='fill:white' />"
            ));
        }

        for (uint i = 0; i < howWide; i++) {
            uint xStart = 300+(i*100);
            fence = string(abi.encodePacked(
                fence,
                "<rect width='50' height='150' x='",
                xStart.toString(),
                "' y='600' style='fill:white' />",
                "<polygon points='",
                xStart.toString(),
                ",600, ",
                (xStart+25).toString(),
                ",550, ",
                (xStart+50).toString(),
                ",600' style='fill:white' />"
            ));
        }

        fence = string(abi.encodePacked(fence, '</g>'));
        return fence;
    }

    function _generateAllFences(CityParkUtils.Art memory artData) public pure returns (string memory) {
        uint numFenceStructures = CityParkUtils.seededRandom(1,3,333333333,artData);
        string memory allFences = '';
        for (uint i = 0; i < numFenceStructures; i++) {
            bool xPos =  CityParkUtils.seededRandom(0,2,i*i+69,artData) > 1;
            uint randX = CityParkUtils.seededRandom(0,300,i*i+888,artData);

            string memory xString;
            if (xPos) {
                xString = randX.toString();
            } else {
                xString = string(abi.encodePacked("-", randX.toString()));
            }

            allFences = string(abi.encodePacked(
                allFences,
                "<g transform='translate(",
                xString,
                ",",
                CityParkUtils.seededRandom(0,300,i*i+777,artData).toString(),
                ")'>",
                _generateFence(artData, i*i)
            ));
        }
        return allFences;
    }
}
