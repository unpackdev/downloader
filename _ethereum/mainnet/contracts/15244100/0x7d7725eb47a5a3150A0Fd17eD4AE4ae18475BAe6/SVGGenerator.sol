// contracts/SVGGenerator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./xpmath.sol";
import "./Base64.sol";
import "./StringLib.sol";

import "./FireGenerator.sol";
import "./FireGenerator2.sol";

contract SVGGenerator {
    int128 private constant OVERLAP_DETECT = 1200; //number in rad*1000
    uint16 private constant SPACE_RAD = 1300;
    int128 private constant PRECISION = 10000; //4 decimals
    uint16 private constant DOWN60 = 9599;
    uint16 private constant UP60 = 11344;
    uint16 private constant DOWN90 = 14486;
    uint16 private constant UP90 = 16929;
    uint16 private constant DOWN120 = 19897;
    uint16 private constant UP120 = 21991;
    uint16 private constant DOWN180 = 30194;
    uint16 private constant UP180 = 32637;

    enum LineColor {
        Red,
        Green,
        Blue,
        Yellow,
        Default
    }

    FireGenerator private fireGenerator;

    constructor(FireGenerator _fireGenerator) {
        fireGenerator = _fireGenerator;
    }

    function nonExistSVGInOpenSeaFormat(uint256 tokenId, uint256 rootGen0TokenId)
        public
        pure
        returns (string memory)
    {
        string
            memory output = '<svg width="600" height="600" xmlns="http://www.w3.org/2000/svg"><text id="svg_6" font-size="10" y="311" x="301">generating...</text><svg>';
        return encodeInSVGFormat(output, tokenId, rootGen0TokenId, 0, 0, 0);
    }

    function genSVGInOpenSeaFormat(
        uint16[] memory cusps,
        uint16[] memory planets,
        uint32 generation,
        uint256 tokenId,
        uint16 month,
        uint16 day,
        uint256 rootGen0TokenId
    ) public view returns (string memory) {
        string memory output = soGenSVG(cusps, planets, generation, month, day);
        return encodeInSVGFormat(output, tokenId, rootGen0TokenId, generation, month, day);
    }

    function encodeInSVGFormat(string memory _rawSVG, uint256 tokenId, uint256 rootGen0TokenId, uint32 generation, uint16 month, uint16 day)
        private
        pure
        returns (string memory)
    {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Meta Astrology Chart #',
                        StringLib.uintToString(tokenId),
                        '", "description": "metaverse on-chain astro chart", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(_rawSVG)),
                        '", "attributes": [{"trait_type": "rootGen0TokenId", "value": "',
                        StringLib.uintToString(rootGen0TokenId),
                        '"}, {"trait_type": "generation", "value": "',
                        StringLib.uintToString(generation),
                        '"}, {"trait_type": "month", "value": "',
                        StringLib.uintToString(month),
                        '"}, {"trait_type": "day", "value": "',
                        StringLib.uintToString(day),
                        '"}]}'
                    )
                )
            )
        );

        _rawSVG = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return _rawSVG;
    }

    ///*********constants */
    string constant golden0 = "e3d8ab";
    string constant golden1 = "ab6e13";
    string constant golden2 = "b49d5d";
    string constant silver0 = "c1c1c1";
    string constant silver1 = "757575";
    string constant silver2 = "989898";

    function soGenSVG(
        uint16[] memory cusps,
        uint16[] memory planets,
        uint32 generation,
        uint16 month,
        uint16 day
    ) public view returns (string memory result) {
        require(cusps.length == 12, "wrong csups");
        require(planets.length == 11, "wrong planets");
        //s0-color-s1-color-s2-color-s3-circles-s4
        bool isGen0 = generation == 0;
        FireGenerator.ElementType elementType = fireGenerator.judgeElementTypeByPlanetDegree(planets[0]);
        if (isGen0) {
            //TODO(ironman_ch): move these code to FireGenerator
            string memory part2 = FireGenerator2.svgPart2(isGen0, elementType);
            part2 = fireGenerator.replaceThemeColor(isGen0, elementType, month, day, part2);
            result = concat(FireGenerator2.svgPart0(), golden0);
            result = concat(result, FireGenerator2.svgPart1());
            result = concat(result, golden1);
            result = concat(result, part2);
            // result = concat(result, golden2); will concat in the firegenerato
        } else {
            result = concat(FireGenerator2.svgPart0(), silver0);
            result = concat(result, FireGenerator2.svgPart1());
            result = concat(result, silver1);
            result = concat(result, FireGenerator2.svgPart2(isGen0, elementType));
            // result = concat(result, silver2); will concat in the firegenerator
        }
        //TODO(ironman_ch): move these code to FireGenerator
        string memory part3 = FireGenerator2.svgPart3(isGen0, elementType);
        part3 = fireGenerator.replaceThemeColor(isGen0, elementType, month, day, part3);
        result = concat(result, part3);

        string memory date = concat(
            concat(uintToString(month), "."),
            uintToString(day)
        );
        string memory centralText = string(abi.encodePacked(
            '<g filter="drop-shadow(0 1px 1px #000)">',
            text(
                "600",
                "600",
                concat(
                    concat(unicode"「Gen ", uintToString(generation)),
                    unicode"」"
                ),
                "2rem"
            ),
            text(
                "600",
                "650",
                concat(concat(unicode"✦ ", date), unicode" ✦"),
                "1.5rem"
            ),
            '</g>'
        ));
        string memory cuspsInSVG = genCuspsAsLines(cusps);
        (string memory planetsInSVG, string memory relationLines) = genPlanetsAsText(planets);
        FireGenerator.GenAndElement memory params = FireGenerator.GenAndElement({
            isGen0: isGen0, elementType: elementType, cuspsBody: cuspsInSVG, planetsBody: planetsInSVG, planets: planets
        });
        FireGenerator.ParamsPart2 memory paramsPart2 = FireGenerator.ParamsPart2({
            relationLines: relationLines,
            centralText: centralText,
            month: month,
            day: day
        });

        result = concat(result, fireGenerator.completeChartBody(params, paramsPart2));

        
        
        result = concat(result, "</svg>");
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(string memory self, string memory other)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(self, other));
    }

    function uintToString(uint256 value) private pure returns (string memory) {
        return string(uintToBytes(value));
    }

    function uintToBytes(uint256 value) private pure returns (bytes memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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
        return buffer;
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.  (eee.aaa).tostring
     */
    function intToFixedNx4String(int256 value)
        public
        pure
        returns (string memory)
    {
        string memory sign = "";
        if (value < 0) {
            sign = "-";
            value = -value;
        }
        bytes memory buffer = uintToBytes(uint256(value));
        string memory interger = "";
        string memory decimal = "";
        if (buffer.length <= 4) {
            interger = "0.";
            decimal = string(buffer);
            while (bytes(decimal).length < 4) {
                decimal = concat("0", decimal);
            }
            interger = concat(sign, interger);
            return concat(interger, decimal);
        } else {
            bytes memory tmp = new bytes(1);
            for (uint256 i = 0; i < buffer.length - 4; i++) {
                tmp[0] = buffer[i];
                interger = concat(interger, string(tmp));
            }
            interger = concat(interger, ".");
            for (uint256 i = buffer.length - 4; i < buffer.length; i++) {
                tmp[0] = buffer[i];
                decimal = concat(decimal, string(tmp));
            }
            interger = concat(sign, interger);
            return concat(interger, decimal);
        }
    }

    // to 64.64 fixed point number
    function to64x64(int128 x) public pure returns (int128) {
        unchecked {
            return XpMath.divi(x, PRECISION);
        }
    }

    // from 64.64 fixed point number to uint
    function toInt(int128 x) public pure returns (int256) {
        return XpMath.muli(x, PRECISION);
    }

    function genLineCoordinates(
        int128 alpha,
        int128 r0,
        int128 r1
    ) public pure returns (int256[4] memory coordinates) {
        int128 cx = 600 << 64;
        r0 = r0 << 64;
        r1 = r1 << 64;
        return [
            toInt(XpMath.add(cx, XpMath.mul(r0, XpMath.cos(alpha)))),
            toInt(XpMath.sub(cx, XpMath.mul(r0, XpMath.sin(alpha)))),
            toInt(XpMath.add(cx, XpMath.mul(r1, XpMath.cos(alpha)))),
            toInt(XpMath.sub(cx, XpMath.mul(r1, XpMath.sin(alpha))))
        ];
    }

    function genRelationLineCoord(
        int128 r,
        int128 alpha,
        int128 beta
    ) public pure returns (int256[4] memory coordinates) {
        r = r << 64;
        int128 cx = 600 << 64; //center
        return [
            toInt(XpMath.add(cx, XpMath.mul(r, XpMath.cos(alpha)))),
            toInt(XpMath.sub(cx, XpMath.mul(r, XpMath.sin(alpha)))),
            toInt(XpMath.add(cx, XpMath.mul(r, XpMath.cos(beta)))),
            toInt(XpMath.sub(cx, XpMath.mul(r, XpMath.sin(beta))))
        ];
    }

    function genCuspsAsLines(uint16[] memory cusps)
        private
        pure
        returns (string memory res)
    {
        int128[] memory cusps64x64 = new int128[](12);

        for (uint8 i = 0; i < cusps.length; i++) {
            cusps64x64[i] = to64x64(int32(uint32(cusps[i])));
        }
        for (uint32 i = 0; i < cusps.length; i += 1) {
            int256[4] memory xy = genLineCoordinates(cusps64x64[i], 230, 355);
            res = concat(
                res,
                line(xy[0], xy[1], xy[2], xy[3], 10000, LineColor.Default)
            ); //20000 means 2.0000
        }
    }

    function fixOverlap(uint16[] memory _planets)
        public
        pure
        returns (uint16[] memory)
    {
        for (uint8 i = 1; i < _planets.length; i++) {
            for (uint8 j = 0; j <i ; j++) {
                // detect and move it
                int128 diff = XpMath.abs(
                    int128(uint128(_planets[i])) - int128(uint128(_planets[j]))
                );
                if (diff <= OVERLAP_DETECT) {
                    uint256 tmp = _planets[j] + SPACE_RAD;
                    _planets[i] = uint16(tmp % 65536);
                }
            }
        }
        return _planets;
    }
    function genPlanetsAsText(uint16[] memory _planets)
        private
        pure
        returns (string memory res, string memory relationLines)
    {
        string[11] memory PLANETS_TEXT = [
            unicode"☉", //0
            unicode"☽", //1
            unicode"☿", //2
            unicode"♀", //3
            unicode"♂", //4
            unicode"♃", //5
            unicode"♄", //6
            unicode"♅", //7
            unicode"♆", //8
            unicode"♇", //9
            "ASC"
        ];
        //sort for detect overlap, small to big
        uint16[] memory planets = new uint16[](_planets.length);
        for(uint8 i = 0; i < _planets.length; i++) {
            planets[i] = _planets[i];
        }
        for (uint256 i = 0; i < planets.length; i++) {
            for (uint256 j = i + 1; j < planets.length; j++) {
                if (planets[i] > planets[j]) {
                    uint16 temp = planets[i];
                    planets[i] = planets[j];
                    planets[j] = temp;
                    string memory tmpStr = PLANETS_TEXT[i];
                    PLANETS_TEXT[i] = PLANETS_TEXT[j];
                    PLANETS_TEXT[j] = tmpStr;
                }
            }
        }
        //draw Realtionship lines
        relationLines = drawPlanetRelationLines(planets);
        //copy to a int128 array
        int128[] memory realPlanets64x64 = new int128[](11);
        for (uint8 i = 0; i < planets.length; i++) {
            //never overflow, planets is a uint16 array
            realPlanets64x64[i] = to64x64(int32(uint32(planets[i])));
        }
        //fix overlap
        planets=fixOverlap(planets);
        int128[] memory planets64x64 = new int128[](11);
        for (uint8 i = 0; i < planets.length; i++) {
            //to64x64
            planets64x64[i] = to64x64(int32(uint32(planets[i])));
        }
        //draw planets
        for (uint32 i = 0; i < PLANETS_TEXT.length; i++) {
            int256[4] memory xy = genLineCoordinates(
                planets64x64[i],
                0,
                345 - 30
            );

            string memory fontSize = i == PLANETS_TEXT.length - 1 ? "25" : "30";
            res = concat(
                res,
                text(
                    intToFixedNx4String(xy[2]),
                    intToFixedNx4String(xy[3]),
                    PLANETS_TEXT[i],
                    fontSize
                )
            );
            int256[4] memory xy1 = genLineCoordinates(
                realPlanets64x64[i],
                0,
                355 //target R
            );
            xy = genLineCoordinates(planets64x64[i], 0, 345 - 30);
            res = concat(res, dot(xy1[2], xy1[3]));
        }
    }

    function drawPlanetRelationLines(uint16[] memory planets)
        public
        pure
        returns (string memory res)
    {
        for (uint8 i = 0; i < planets.length; i++) {
            for (uint8 j = i + 1; j < planets.length; j++) {
                res = concat(
                    res,
                    drawPlanetRelationLine(planets[i], planets[j])
                );
            }
        }
    }

    // Require A <= B
    function drawPlanetRelationLine(uint16 planetA, uint16 planetB)
        public
        pure
        returns (string memory res)
    {
        require(planetA <= planetB, "PRL");
        int128 radius = 228;
        uint16 diff = planetB - planetA;
        int256[4] memory xy;
        res = "";
        xy = genRelationLineCoord(
            radius,
            to64x64(int32(uint32(planetA))),
            to64x64(int32(uint32(planetB)))
        );
        if (DOWN60 <= diff && diff <= UP60) {
            //60
            res = line(xy[0], xy[1], xy[2], xy[3], 10000, LineColor.Yellow);
        } else if (DOWN90 <= diff && diff <= UP90) {
            //90
            res = line(xy[0], xy[1], xy[2], xy[3], 10000, LineColor.Red);
        } else if (DOWN120 <= diff && diff <= UP120) {
            //120
            res = line(xy[0], xy[1], xy[2], xy[3], 10000, LineColor.Green);
        } else if (DOWN180 <= diff && diff <= UP180) {
            //180
            res = line(xy[0], xy[1], xy[2], xy[3], 10000, LineColor.Blue);
        }
    }

    function text(
        string memory x,
        string memory y,
        string memory content,
        string memory fontSize
    ) private pure returns (string memory res) {
        res = '<text text-anchor="middle" ';
        res = setAttribute(res, "x", x);
        res = setAttribute(res, "y", y);
        res = setAttribute(res, "font-size", fontSize);
        res = concat(res, ">");
        res = concat(res, content);
        res = concat(res, "</text>");
    }

    function dot(int256 x, int256 y) private pure returns (string memory res) {
        res = "<circle";
        res = setAttribute(res, "cx", intToFixedNx4String(x));
        res = setAttribute(res, "cy", intToFixedNx4String(y));
        res = setAttribute(res, "r", "3");
        res = setAttribute(res, "fill", "#000");
        res = concat(res, "/>");
    }

    function line(
        int256 x1,
        int256 y1,
        int256 x2,
        int256 y2,
        int256 width,
        LineColor color
    ) private pure returns (string memory) {
        return
            lineForString(
                intToFixedNx4String(x1),
                intToFixedNx4String(y1),
                intToFixedNx4String(x2),
                intToFixedNx4String(y2),
                intToFixedNx4String(width),
                color
            );
    }

    function lineForString(
        string memory x1,
        string memory y1,
        string memory x2,
        string memory y2,
        string memory width,
        LineColor color
    ) private pure returns (string memory) {
        string memory l = "<line ";
        l = setAttribute(l, "x1", x1);
        l = setAttribute(l, "y1", y1);
        l = setAttribute(l, "x2", x2);
        l = setAttribute(l, "y2", y2);
        l = setAttribute(l, "stroke-width", width);
        if (color != LineColor.Default) {
            if (color == LineColor.Red) {
                l = setAttribute(l, "stroke", "#b41718"); //Red
            } else if (color == LineColor.Green) {
                l = setAttribute(l, "stroke", "#3069ce"); //Green
            } else if (color == LineColor.Blue) {
                l = setAttribute(l, "stroke", "#3764B1"); //Blue
            } else if (color == LineColor.Yellow) {
                l = setAttribute(l, "stroke", "#E3CD6F"); //Yellow
            }
        }
        return concat(l, "/>");
    }

    function setAttribute(
        string memory origin,
        string memory key,
        string memory value
    ) private pure returns (string memory res) {
        res = concat(origin, " ");
        res = concat(res, key);
        res = concat(res, '="');
        res = concat(res, value);
        res = concat(res, '"');
    }
}
