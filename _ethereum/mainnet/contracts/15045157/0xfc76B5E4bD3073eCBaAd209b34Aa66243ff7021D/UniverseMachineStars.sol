// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./RenderArgs.sol";
import "./Texture5.sol";

struct RenderStar {
    uint32[] colors;
    Matrix m;
}

library UniverseMachineStarsFactory {
    function create(Parameters calldata p, Matrix calldata t)
        external
        pure
        returns (RenderStar[] memory stars)
    {
        stars = new RenderStar[](150);
        
        for (uint256 i = 0; i < 150; ++i) {
            int64 x = Fix64V1.mul(
                p.starPositions[i].x * Fix64V1.ONE,
                2992558336 /* 0.6967592592592593 */
            );

            int64 y = Fix64V1.mul(
                -p.starPositions[i].y * Fix64V1.ONE,
                2992558336 /* 0.6967592592592593 */
            );

            int64 s = Fix64V1.div(
                Fix64V1.mul(
                    2992558336, /* 0.6967592592592593 */
                    (p.starPositions[i].s / 1000) * Fix64V1.ONE
                ),
                Fix64V1.TWO
            );

            uint8 r = p.myColorsR[uint32(p.starPositions[i].c % p.cLen)];
            uint8 g = p.myColorsG[uint32(p.starPositions[i].c % p.cLen)];
            uint8 b = p.myColorsB[uint32(p.starPositions[i].c % p.cLen)];
            
            uint32 tint = ColorMath.toColor(255, r, g, b);

            stars[i].colors = new uint32[](2);
            stars[i].colors[0] = ColorMath.tint(436207615, tint);
            stars[i].colors[1] = ColorMath.tint(3439329279, tint);

            stars[i].m = TextureMethods.rectify(x, y, 0, s, t);
        }
    }
}

library UniverseMachineStars {
    function renderStars(
        Graphics2D memory g,
        DrawContext memory f,
        VertexData[][] calldata d,
        RenderStar[] calldata stars
    ) external pure returns (uint8[] memory) {
        for (uint256 i = 0; i < 150; ++i) {
            for (uint32 j = 0; j < 2; j++) {

                f.color = stars[i].colors[j];
                f.t = stars[i].m;

                Graphics2DMethods.renderWithTransform(
                    g,
                    f,
                    d[j],
                    true
                );
            }
        }

        return g.buffer;
    }
}
