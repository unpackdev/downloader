// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Ellipse.sol";
import "./RenderArgs.sol";

library UniverseMachineSkeletonFactory {
    function create(Parameters calldata p) external pure returns (VertexData[][] memory data) {
        Ellipse memory e = EllipseMethods.circle(
            0,
            0,
            6442450944 /* 1.5 */
        );

        data = new VertexData[][](2000 * p.numPaths);
        
        uint count = 0;
        for (uint32 i = 0; i < 2000; i++) {
            for (uint32 j = 0; j < p.numPaths; j++) {
                e.originX = BezierMethods.mx(
                    p.paths[j],
                    Fix64V1.div(
                        int32(i) * Fix64V1.ONE,
                        int16(2000) * Fix64V1.ONE
                    )
                );
                e.originY = BezierMethods.my(
                    p.paths[j],
                    Fix64V1.div(
                        int32(i) * Fix64V1.ONE,
                        int16(2000) * Fix64V1.ONE
                    )
                );                
                data[count++] = EllipseMethods.vertices(e);
            }
        }
    }
}

library UniverseMachineSkeleton {
    function renderSkeleton(
        Graphics2D memory g,
        DrawContext memory f,
        Matrix calldata m,
        VertexData[][] memory data
    ) external pure returns (uint8[] memory) {        
        f.color = 922746880 /* 0x55000000 */;
        f.t = m;
        for(uint i = 0; i < data.length; i++) {            
            Graphics2DMethods.renderWithTransform(
                g,
                f,
                data[i],
                true
            );
        }
        return g.buffer;
    }
}
