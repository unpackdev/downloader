// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Graphics2D.sol";
import "./Matrix.sol";
import "./CustomPath.sol";
import "./Stroke.sol";
import "./ColorMath.sol";
import "./DrawContext.sol";

import "./Textures.sol";
import "./TextureData.sol";
import "./RenderUniverseArgs.sol";

library Texture1Factory {
    function createTexture() external pure returns (TextureData memory texture) {
        texture.vertices = new VertexData[][](2);
        texture.colors = new uint32[](2);

        texture.vertices[0] = CustomPathMethods.vertices(rect(688, 644, 890, 890));
        texture.vertices[1] = CustomPathMethods.vertices(rect(666, 666, 890, 890));
        texture.colors[0] = 100663296;
        texture.colors[1] = 4294967295;
    }

    function rect(
        int32 x,
        int32 y,
        int32 width,
        int32 height
    ) private pure returns (CustomPath memory line) {
        line = CustomPathMethods.create(8);
        CustomPathMethods.moveTo(line, x * Fix64V1.ONE, y * Fix64V1.ONE);
        CustomPathMethods.lineTo(
            line,
            (x + width) * Fix64V1.ONE,
            y * Fix64V1.ONE
        );
        CustomPathMethods.lineTo(
            line,
            (x + width) * Fix64V1.ONE,
            (y + height) * Fix64V1.ONE
        );
        CustomPathMethods.lineTo(
            line,
            x * Fix64V1.ONE,
            (y + height) * Fix64V1.ONE
        );
        CustomPathMethods.lineTo(line, x * Fix64V1.ONE, y * Fix64V1.ONE);
        return line;
    }
}