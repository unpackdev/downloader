//"SPDX-License-Identifier: GPL-3.0

/*******************************************
              _                       _
             | |                     | |
  _ __   ___ | |_   _ ___   __ _ _ __| |_
 | '_ \ / _ \| | | | / __| / _` | '__| __|
 | |_) | (_) | | |_| \__ \| (_| | |  | |_
 | .__/ \___/|_|\__, |___(_)__,_|_|   \__|
 | |             __/ |
 |_|            |___/
 a homage to math, geometry and cryptography.
********************************************/

pragma solidity ^0.8.4;

import "./Trigonometry.sol";
import "./Fixed.sol";


library PolyRenderer {
    using Trigonometry for uint16;
    using Fixed for int64;

    struct Polygon {
        uint8 sides;
        uint8 color;
        uint64 size;
        uint16 rotation;
        uint64 top;
        uint64 left;
        uint64 opacity;
    }

    struct Circle {
        uint8 color;
        uint64 radius;
        uint64 c_y;
        uint64 c_x;
        uint64 opacity;
    }

    function svgOf(bytes calldata data, bool isCircle) external pure returns (string memory){
        // initialise svg
        string memory svg = '<svg width="256" height="256" viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg">';

        // fill it with the background colour
        string memory bgColor = string(abi.encodePacked("rgb(", uint2str(uint8(data[0]), 0, 1), ",", uint2str(uint8(data[1]), 0, 1), ",", uint2str(uint8(data[2]), 0, 1), ")"));
        svg = string(abi.encodePacked(svg, '<rect width="256" height="256" fill="', bgColor, '"/>'));

        // load Palette
        string[4] memory colors;
        for (uint8 i = 0; i < 4; i++) {
            colors[i] = string(abi.encodePacked(uint2str(uint8(data[3 + i * 3]), 0, 1), ",", uint2str(uint8(data[4 + i * 3]), 0, 1), ",", uint2str(uint8(data[5 + i * 3]), 0, 1), ","));
        }

        // Fill it with Polygons or Circles
        uint polygons = (data.length - 15) / 5;
        string memory poly = '';
        Polygon memory polygon;
        for (uint i = 0; i < polygons; i++) {
            polygon = polygonFromBytes(data[15 + i * 5 : 15 + (i + 1) * 5]);
            poly = string(abi.encodePacked(poly,
                isCircle
                ? renderCircle(polygon, colors)
                : renderPolygon(polygon, colors))
            );
        }
        return string(abi.encodePacked(svg, poly, '</svg>'));
    }

    function attributesOf(bytes calldata data, bool isCircle) external pure returns (string memory){
        uint elements = (data.length - 15) / 5;
        if (isCircle) {
            return string(abi.encodePacked('[{"trait_type":"Circles","value":', uint2str(elements, 0, 1), '}]'));
        }
        string[4] memory types = ["Triangles", "Squares", "Pentagons", "Hexagons"];
        uint256[4] memory sides_count;
        for (uint i = 0; i < elements; i++) {
            sides_count[uint8(data[15 + i * 5] >> 6)]++;
        }
        string memory result = '[';
        string memory last;
        for (uint i = 0; i < 4; i++) {
            last = i == 3 ? '}' : '},';
            result = string(abi.encodePacked(result, '{"trait_type":"', types[i], '","value":',
                uint2str(sides_count[i], 0, 1), last));
        }
        return string(abi.encodePacked(result, ']'));
    }

    function renderCircle(Polygon memory polygon, string[4] memory colors) internal pure returns (string memory){
        int64 radius = getRadius(polygon.sides, polygon.size);
        return string(abi.encodePacked('<circle cx="', fixedToString(int64(polygon.left).toFixed(), 1), '" cy="',
            fixedToString(int64(polygon.top).toFixed(), 1), '" r="', fixedToString(radius, 1), '" style="fill:rgba(',
            colors[polygon.color], opacityToString(polygon.opacity), ')"/>'));
    }

    function opacityToString(uint64 opacity) internal pure returns (string memory) {
        return opacity == 31
        ? '1'
        : string(abi.encodePacked('0.', uint2str(uint64(int64(opacity).div(31).fractionPart()), 5, 1)));
    }

    function polygonFromBytes(bytes calldata data) internal pure returns (Polygon memory) {
        Polygon memory polygon;
        // read first two bits from the left and add 3
        polygon.sides = (uint8(data[0]) >> 6) + 3;
        // read the next two bits
        polygon.color = (uint8(data[0]) >> 4) & 3;
        // read the next 5 bits
        polygon.opacity = ((uint8(data[0]) % 16) << 1) + (uint8(data[1]) >> 7);
        // read the last 7 bits.
        polygon.rotation = uint8(data[1]) % 128;
        polygon.top = uint8(data[2]);
        polygon.left = uint8(data[3]);
        polygon.size = uint64(uint8(data[4])) + 1;
        return polygon;
    }

    function renderPolygon(Polygon memory polygon, string[4] memory colors) internal pure returns (string memory){
        int64[] memory points = getVertices(polygon);

        int64 v;
        int8 sign;
        string memory last;
        string memory result = '<polygon points="';
        for (uint j = 0; j < points.length; j++) {
            v = points[j];
            sign = v < 0 ? - 1 : int8(1);
            last = j == points.length - 1 ? '" style="fill:rgba(' : ",";
            result = string(abi.encodePacked(result, fixedToString(v, sign), last));
        }
        return string(abi.encodePacked(result, colors[polygon.color], opacityToString(polygon.opacity), ')"/>'));
    }

    function fixedToString(int64 fPoint, int8 sign) internal pure returns (bytes memory){
        return abi.encodePacked(uint2str(uint64(sign * fPoint.wholePart()), 0, sign), ".",
            uint2str(uint64(fPoint.fractionPart()), 5, 1));
    }

    function getRotationVector(uint16 angle) internal pure returns (int64[2] memory){
        // returns [cos(angle), -sin(angle)]
        return [
            int64(angle.cos()).div(32767), //-32767 to 32767.
            int64(-angle.sin()).div(32767)
        ];
    }

    function rotate(int64[2] memory R, int64[2] memory pos) internal pure returns (int64[2] memory){
        // R = [cos(angle), -sin(angle)]
        // rotation_matrix = [[cos(angle), -sin(angle)], [sin(angle), cos(angle)]]
        // this function returns rotation_matrix.dot(pos)
        int64[2] memory result;
        result[0] = R[0].mul(pos[0]) + R[1].mul(pos[1]);
        result[1] = - R[1].mul(pos[0]) + R[0].mul(pos[1]);
        return result;
    }

    function vectorSum(int64[2] memory a, int64[2] memory b) internal pure returns (int64[2] memory){
        return [a[0] + b[0], a[1] + b[1]];
    }

    function getRadius(uint8 sides, uint64 size) internal pure returns (int64){
        // the radius of the circumscribed circle is equal to the length of the regular poly edge divided by
        // cos(internal_angle/2).
        int64 cos_ang_2 = int64(uint64([7439101574, 6074001000, 5049036871, 4294967296][sides - 3]));
        return int64(size).toFixed().div(cos_ang_2);
    }

    function getVertices(Polygon memory polygon) internal pure returns (int64[] memory) {
        int64[] memory result = new int64[](2 * polygon.sides);
        uint16 internalAngle = [1365, 2048, 2458, 2731][polygon.sides - 3]; // Note: 16384 is 2pi
        uint16 angle = [5461, 4096, 3277, 2731][polygon.sides - 3]; // 16384/sides
        int64 radius = getRadius(polygon.sides, polygon.size);

        // We map our rotation that goes from [0, 128[, to [0, 16384/sides[. 16384 is 2pi on the Trigonometry package.
        // We say 128 = 16384/sides because if you rotate a regular polygon by 2pi/number_of_sides it will be exactly the
        // same as rotating it by 2pi (due to the symmetries of regular polys).
        // We gain more precision by taking advantage of these symmetries.

        uint16 rotation = uint16((polygon.rotation << 7) / polygon.sides + internalAngle);

        int64[2] memory R = getRotationVector(rotation);
        int64[2] memory vector = rotate(R, [radius, 0]);
        int64[2] memory center = [int64(polygon.left).toFixed(), int64(polygon.top).toFixed()];
        int64[2] memory pos = vectorSum(center, vector);
        result[0] = pos[0];
        result[1] = pos[1];
        R = getRotationVector(angle);
        for (uint8 i = 0; i < polygon.sides - 1; i++) {
            vector = rotate(R, vector);
            pos = vectorSum(center, vector);
            result[(i + 1) * 2] = pos[0];
            result[(i + 1) * 2 + 1] = pos[1];
        }
        return result;
    }

    function uint2str(uint _i, uint8 zero_padding, int8 sign) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        if ((zero_padding > 0) && (zero_padding > length)) {
            uint pad_length = zero_padding - length;
            bytes memory pad = new bytes(pad_length);
            k = 0;
            while (k < pad_length) {
                pad[k++] = bytes1(uint8(48));
            }
            bstr = abi.encodePacked(pad, bstr);
        }
        if (sign < 0) {
            return string(abi.encodePacked("-", bstr));
        } else {
            return string(bstr);
        }
    }
}