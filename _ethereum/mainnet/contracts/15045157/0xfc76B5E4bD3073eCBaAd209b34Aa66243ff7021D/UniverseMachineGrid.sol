// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Ellipse.sol";
import "./RenderArgs.sol";

library UniverseMachineGrid {

    function renderGrid(Graphics2D memory g, DrawContext memory f, Parameters calldata p, Matrix calldata m) external pure returns (uint8[] memory) {
        
        Ellipse memory e = EllipseMethods.create(0, 0, 19327352832 /* 4.5 */, 19327352832 /* 4.5 */);
        
        VertexData[][] memory dots = new VertexData[][](28);
        for (uint16 i = 0; i < 28; i++) {
            e.originX = p.gridPoints[i].x;
            e.originY = p.gridPoints[i].y;
            dots[i] = EllipseMethods.vertices(e);
        }

        f.color = 4278190080 /* 0xFF000000 */;
        f.t = m;
        
        for (uint16 i = 0; i < dots.length; i++) {
            Graphics2DMethods.renderWithTransform(
                g,
                f,
                dots[i],
                true
            );            
        }

        return g.buffer;
    }
}