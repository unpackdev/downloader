// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Graphics2D.sol";
import "./Matrix.sol";
import "./Ellipse.sol";
import "./Stroke.sol";
import "./DrawContext.sol";

import "./Textures.sol";
import "./RenderUniverseArgs.sol";

library Texture0Factory {
    function createTexture() external pure returns (TextureData memory texture) {
        texture.vertices = new VertexData[][](4);
        texture.colors = new uint32[](4);

        Ellipse memory circle1 = EllipseMethods.create(
            2860448219136,
            6682969112576,
            1906965479424,
            1906965479424
        );

        texture.vertices[0] = EllipseMethods.vertices(circle1);

        Stroke memory stroke1 = StrokeMethods.create(texture.vertices[0], 0, 200, 200);
        stroke1.lineCap = LineCap.Round;
        stroke1.lineJoin = LineJoin.Round;

        Ellipse memory circle2 = EllipseMethods.create(
            2860448219136,
            4776003633152,
            95348277248,
            95348277248
        );

        texture.vertices[2] = EllipseMethods.vertices(circle2);

        Stroke memory stroke2 = StrokeMethods.create(
            texture.vertices[2],
            1073741824, /* 0.25 */
            200,
            200
        );
        
        texture.vertices[1] = StrokeMethods.vertices(stroke1);        
        texture.vertices[3] = StrokeMethods.vertices(stroke2);

        texture.colors[0] = 4294967295;
        texture.colors[1] = 16777215;
        texture.colors[2] = 4278190080;
        texture.colors[3] = 1056964608;
    }
}