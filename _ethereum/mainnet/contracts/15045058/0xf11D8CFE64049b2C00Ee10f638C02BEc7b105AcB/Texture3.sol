// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Graphics2D.sol";
import "./Matrix.sol";
import "./Ellipse.sol";
import "./ColorMath.sol";
import "./DrawContext.sol";

import "./Textures.sol";
import "./RenderUniverseArgs.sol";

library Texture3Factory {
    function createTexture() external pure returns (TextureData memory texture) {
        texture.vertices = new VertexData[][](4);
        texture.colors = new uint32[](4);

        texture.vertices[0] = EllipseMethods.vertices(
            EllipseMethods.create(
                2860448219136,
                6682969112576,
                1430224109568,
                1430224109568
            )
        );
        texture.vertices[1] = EllipseMethods.vertices(
            EllipseMethods.create(
                2860448219136,
                8351563907072,
                190696554496,
                190696554496
            )
        );
        texture.vertices[2] = EllipseMethods.vertices(
            EllipseMethods.create(
                2860448219136,
                8351563907072,
                47674138624,
                47674138624
            )
        );
        texture.vertices[3] = EllipseMethods.vertices(
            EllipseMethods.create(
                2860448219136,
                8780631244800,
                95348277248,
                95348277248
            )
        );

        texture.colors[0] = 4294967295;
        texture.colors[1] = 50331648;
        texture.colors[2] = 4278190080;
        texture.colors[3] = 4294967295;
    }
}
