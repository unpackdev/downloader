// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Graphics2D.sol";
import "./Matrix.sol";
import "./Ellipse.sol";
import "./ColorMath.sol";

import "./Textures.sol";

library Texture5Factory {
    function createTexture() external pure returns (VertexData[][] memory t) {        
        VertexData[] memory c1 = EllipseMethods.vertices(EllipseMethods.create(
            4767413698560,
            4776003633152,
            66743791616,
            66743791616
        ));
        VertexData[] memory c2 = EllipseMethods.vertices(EllipseMethods.create(
            4767413698560,
            4776003633152,
            28604481536,
            28604481536
        ));        
        t = new VertexData[][](2);
        t[0] = c1;
        t[1] = c2;
        return t;
    }
}
