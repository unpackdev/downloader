// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Graphics2D.sol";
import "./Matrix.sol";
import "./Stroke.sol";
import "./CustomPath.sol";
import "./ColorMath.sol";
import "./DrawContext.sol";

import "./Textures.sol";
import "./TextureData.sol";
import "./RenderUniverseArgs.sol";

library Texture2Factory {
    function createTexture() external pure returns (TextureData memory data) {
        uint32 color1 = 4294967295;
        uint32 color2 = 16777215;

        int64 h = 4767413698560;
        int64 x = 4771708665856;
        int64 y = 0;

        data.vertices = new VertexData[][](2221);
        data.colors = new uint32[](2221);

        uint16 count = 0;

        for (
            int64 i = y;
            i <= Fix64V1.add(y, h);
            i += 2147483648 /* 0.5 */
        ) {
            int64 inter = Fix64V1.map(i, y, Fix64V1.add(y, h), 0, Fix64V1.ONE);
            uint32 c = ColorMath.lerp(color1, color2, inter);
            int64 s = h - i;

            CustomPath memory line = CustomPathMethods.create(8);
            CustomPathMethods.moveTo(line, x, s);
            CustomPathMethods.lineTo(
                line,
                Fix64V1.add(x, i),
                Fix64V1.add(s, i)
            );

            Stroke memory stroke = StrokeMethods.create(
                CustomPathMethods.vertices(line),
                Fix64V1.ONE, 200, 200
            );

            data.vertices[count] = StrokeMethods.vertices(stroke);
            data.colors[count] = c;
            count++;
        }
    }
}
