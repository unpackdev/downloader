// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Errors.sol";

import "./RenderArgs.sol";
import "./RenderUniverseArgs.sol";
import "./RenderUniverseTextures.sol";

import "./Texture0.sol";
import "./Texture1.sol";
import "./Texture2.sol";
import "./Texture3.sol";
import "./Texture4.sol";
import "./Textures.sol";

import "./UniverseMachineSkeleton.sol";

import "./Strings.sol";

struct CreateArgs {
    int64 angle;
    int64 colorChoice;
    uint32 count;
    int64 reduceAmount;
}

library UniverseMachineUniverseFactory {

    int64 public constant MasterScale = 2992558231; /* 0.6967592592592593 */
    int64 public constant ReduceAmount = 2147483 /* 0.0005 */;
    int64 public constant BaseSize = 9543417331712 /* 2222 */;

    function create(Parameters calldata p, Matrix memory m)
        external
        pure
        returns (RenderUniverseArgs[] memory results)
    {
        results = new RenderUniverseArgs[](56000);

        CreateArgs memory c;

        Ellipse memory e = EllipseMethods.circle(0, 0, 6442450944 /* 1.5 */);

        for (uint32 i = 0; i < 2000; i++) {
            for (uint32 j = 0; j < 28; j++) {

                RenderUniverseArgs memory a;

                int64 step = Fix64V1.div(int32(i) * Fix64V1.ONE, int16(2000) * Fix64V1.ONE);
                int64 x = BezierMethods.mx(p.paths[j], step);
                int64 y = BezierMethods.my(p.paths[j], step);                

                e.originX = x;
                e.originY = -y;
                a.path = EllipseMethods.vertices(e);

                getColorChoice(p, c, i, j);
                a.tint = ColorMath.toColor(
                    255,
                    p.myColorsR[uint64(c.colorChoice / Fix64V1.ONE)],
                    p.myColorsG[uint64(c.colorChoice / Fix64V1.ONE)],
                    p.myColorsB[uint64(c.colorChoice / Fix64V1.ONE)]
                );

                getAngle(p, c, i, j);
                a.angle = -c.angle;                

                a.x = Fix64V1.mul(x, MasterScale);
                a.y = Fix64V1.mul(-y, MasterScale);
                a.size = Fix64V1.mul(MasterScale, Fix64V1.div(Fix64V1.sub(BaseSize, Fix64V1.mul(BaseSize, Fix64V1.mul(ReduceAmount, int32(i) * Fix64V1.ONE))), BaseSize));               
                a.rectify = TextureMethods.rectify(a.x, a.y, a.angle, a.size, m);
                results[c.count++] = a;                
            }
        }
    }

    function getAngle(
        Parameters calldata p,
        CreateArgs memory c,
        uint32 i,
        uint32 j
    ) internal pure {
        if (p.whichRot[j] == 0) {
            if (p.whichRotDir[j] == 0) {
                c.angle = radians(
                    Fix64V1.mul(
                        int32(i) * Fix64V1.ONE,
                        2147483648 /* 0.5 */
                    )
                );
            } else {
                c.angle = radians(
                    -Fix64V1.mul(
                        int32(i) * Fix64V1.ONE,
                        2147483648 /* 0.5 */
                    )
                );
            }
        } else if (p.whichRot[j] == 1) {
            if (p.whichRotDir[j] == 0) {
                c.angle = radians(
                    Fix64V1.sub(
                        360 * Fix64V1.ONE,
                        Fix64V1.mul(
                            360 * Fix64V1.ONE,
                            Fix64V1.mul(
                                2147483, /* 0.0005 */
                                int32(i) * Fix64V1.ONE
                            )
                        )
                    )
                );
            } else {
                c.angle = radians(
                    -Fix64V1.sub(
                        360 * Fix64V1.ONE,
                        Fix64V1.mul(
                            360 * Fix64V1.ONE,
                            Fix64V1.mul(
                                2147483, /* 0.0005 */
                                int32(i) * Fix64V1.ONE
                            )
                        )
                    )
                );
            }
        } else {
            c.angle = 0;
        }
    }

    function getColorChoice(Parameters calldata p, CreateArgs memory c, uint32 i, uint32 j)
        internal
        pure
    {
        c.colorChoice = Fix64V1.floor(
            Fix64V1.sub(
                p.cLen * Fix64V1.ONE,
                Fix64V1.mul(
                    Fix64V1.mul(
                        p.cLen * Fix64V1.ONE,
                        2147483 /* 0.0005 */
                    ),
                    int32(i) * Fix64V1.ONE
                )
            ) % (p.cLen * Fix64V1.ONE)
        );
        if (p.whichColorFlow[j] != 0) {
            if (p.whichColorFlow[j] == 1) {
                c.colorChoice = Fix64V1.floor(
                    Fix64V1.add(
                        Fix64V1.mul(int32(i) * Fix64V1.ONE, Fix64V1.TWO),
                        int32(j) * Fix64V1.ONE
                    ) % (p.cLen * Fix64V1.ONE)
                );
            } else if (p.whichColorFlow[j] == 2) {
                c.colorChoice = Fix64V1.floor(
                    Fix64V1.add(
                        Fix64V1.mul(
                            int32(j) * Fix64V1.ONE,
                            Fix64V1.div(
                                p.cLen * Fix64V1.ONE,
                                int16(28) * Fix64V1.ONE
                            )
                        ),
                        Fix64V1.mul(
                            Fix64V1.add(
                                int32(i) * Fix64V1.ONE,
                                int32(j) * Fix64V1.ONE
                            ),
                            1288490240 /* 0.3 */
                        )
                    ) % (p.cLen * Fix64V1.ONE)
                );
            } else if (p.whichColorFlow[j] == 3) {
                c.colorChoice = Fix64V1.floor(
                    Fix64V1.add(
                        Fix64V1.mul(
                            int32(j) * Fix64V1.ONE,
                            Fix64V1.div(
                                p.cLen * Fix64V1.ONE,
                                Fix64V1.mul(
                                    int16(28) * Fix64V1.ONE,
                                    429496736 /* 0.1 */
                                )
                            )
                        ),
                        Fix64V1.mul(
                            Fix64V1.add(
                                int32(i) * Fix64V1.ONE,
                                int32(j) * Fix64V1.ONE
                            ),
                            429496736 /* 0.1 */
                        )
                    ) % (p.cLen * Fix64V1.ONE)
                );
            }
        }
    }

    function radians(int64 degree) private pure returns (int64) {
        return Fix64V1.mul(degree, Fix64V1.div(Fix64V1.PI, 180 * Fix64V1.ONE));
    }
}

library UniverseMachineUniverse {
    function renderUniverse(
        Graphics2D memory g,
        DrawContext memory f,
        int32[] calldata whichTex,
        RenderUniverseArgs[] calldata u,
        RenderUniverseTextures calldata t,
        Matrix calldata scaled
    ) external pure returns (uint8[] memory) {

        uint count;
        for (uint32 i; i < 2000; i++) {
            for (uint32 j; j < 28; j++) {
                
                f.t = scaled;
                f.color = 922746880;
                Graphics2DMethods.renderWithTransform(
                    g,
                    f,
                    u[count].path,                    
                    true                                  
                );

                f.t = u[count].rectify;                
                f.tint = u[count].tint;

                if (whichTex[j] == 0) {                    
                    TextureMethods.draw(g, t.t0, f);       
                } else if (whichTex[j] == 1) {                                     
                    TextureMethods.draw(g, t.t1, f);                   
                } else if (whichTex[j] == 2) {
                    TextureMethods.draw(g, t.t2, f);
                } else if (whichTex[j] == 3) {
                    TextureMethods.draw(g, t.t3, f);
                } else if (whichTex[j] == 4) {
                    TextureMethods.draw(g, t.t4, f);
                } else {
                    revert ArgumentOutOfRange(); 
                }
                count++;        
            }
        }

        return g.buffer;
    }    
}
