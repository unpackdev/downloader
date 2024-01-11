// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Graphics2D.sol";
import "./DrawContext.sol";
import "./Matrix.sol";
import "./VertexData.sol";

import "./RenderUniverseArgs.sol";
import "./TextureData.sol";

library TextureMethods {

    function draw(
        Graphics2D memory g,
        TextureData memory texture,
        DrawContext memory f
    ) internal pure {
        
        for (uint256 i = 0; i < texture.vertices.length; i++) {
            f.color = ColorMath.tint(texture.colors[i], f.tint);
            Graphics2DMethods.renderWithTransform(
                g,
                f,
                texture.vertices[i],               
                true
            );
        }
    }

    function rectify(int64 x, int64 y, int64 r, int64 s, Matrix memory t) internal pure returns (Matrix memory transform) {
        int64 dx = x;
        int64 dy = y;

        if (!MatrixMethods.isIdentity(t)) {
            (dx, dy) = MatrixMethods.transform(t, dx, dy);
        }

        dx = Fix64V1.add(dx, Fix64V1.ONE);
        dy = Fix64V1.sub(dy, Fix64V1.ONE);

        transform = MatrixMethods.newIdentity();
        transform = MatrixMethods.mul(transform, MatrixMethods.newTranslation(-4771708665856 /* -1111 */, -4771708665856 /* -1111 */));
        transform = MatrixMethods.mul(transform, MatrixMethods.newScale(s, s));

        if (r != 0) {
            transform = MatrixMethods.mul(transform, MatrixMethods.newRotation(r));
        }

        transform = MatrixMethods.mul(transform, MatrixMethods.newTranslation(dx, dy));
        return transform;
    }
}