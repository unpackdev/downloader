// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Graphics2D.sol";
import "./CustomPath.sol";
import "./Stroke.sol";
import "./Parameters.sol";

library UniverseMachineMatsFactory {

     function createMats(Graphics2D memory g)
        external
        pure
        returns (VertexData[][] memory mats)
    {
        mats = new VertexData[][](86);
        int8 edge = 85;
        for(uint8 i = 0; i < mats.length; i++) {
            mats[i] = UniverseMachineMatsFactory.create(edge--, g.width, g.height);
        }
        return mats;
    }

    function create(
        int8 edge,
        uint32 width,
        uint32 height
    ) internal pure returns (VertexData[] memory) {
        CustomPath memory line = CustomPathMethods.create(8);

        // TL to BL
        CustomPathMethods.moveTo(line, edge * Fix64V1.ONE, (int32(height) - edge) * Fix64V1.ONE);
        CustomPathMethods.lineTo(line, edge * Fix64V1.ONE, edge * Fix64V1.ONE);

        // BL to BR
        CustomPathMethods.moveTo(line, (edge + 1) * Fix64V1.ONE, (edge + 1) * Fix64V1.ONE);
        CustomPathMethods.lineTo(line, (int32(width) - edge) * Fix64V1.ONE, (edge + 1) * Fix64V1.ONE);

        // TL to TR
        CustomPathMethods.moveTo(line, (edge + 1) * Fix64V1.ONE, (int32(height) - edge - 1) * Fix64V1.ONE);
        CustomPathMethods.lineTo(line, (int32(width) - edge) * Fix64V1.ONE, (int32(height) - edge - 1) * Fix64V1.ONE);

        // TR to BR
        CustomPathMethods.moveTo(line, (int32(width) - edge - 1) * Fix64V1.ONE, (int32(height) - edge - 2) * Fix64V1.ONE);
        CustomPathMethods.lineTo(line, (int32(width) - edge - 1) * Fix64V1.ONE, (edge + 2) * Fix64V1.ONE);

        Stroke memory stroke = StrokeMethods.create(CustomPathMethods.vertices(line), Fix64V1.ONE, 200, 200);

        return StrokeMethods.vertices(stroke);
    }
}

library UniverseMachineMats {
    function renderMats(Graphics2D memory g, DrawContext memory f, Parameters calldata p, VertexData[][] calldata t)
        external
        pure
        returns (uint8[] memory)
    {
        uint count;
        
        f.color = getMatColor(p, 150);
        renderMat(g, t[count++], f);

        f.color = getMatColor(p, 50);
        for (uint8 i = 0; i < 8; i++) {
            renderMat(g, t[count++], f);
        }

        f.color = getMatColor(p, 0);
        for (uint8 i = 0; i < 77; i++) {
            renderMat(g, t[count++], f);
        }

        return g.buffer;
    }

    function getMatColor(Parameters memory p, uint32 index)
        private
        pure
        returns (uint32)
    {
        uint32 colorIndex = uint32(p.starPositions[0].c);        
        uint8 r = p.myColorsR[(colorIndex + index) % uint32(p.cLen)];
        uint8 g = p.myColorsG[(colorIndex + index) % uint32(p.cLen)];
        uint8 b = p.myColorsB[(colorIndex + index) % uint32(p.cLen)];            
        return ColorMath.toColor(255, r, g, b);
    }

    function renderMat(
        Graphics2D memory g,
        VertexData[] memory t,
        DrawContext memory f
    ) private pure {
        Graphics2DMethods.render(
            g,
            f,
            t,
            false
        );
    }
}
