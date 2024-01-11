// SPDX-License-Identifier: MIT
/* Copyright (c) Kohi Art Community, Inc. All rights reserved. */

/*
/*
///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//     @@@@@@@@@@@@@@                        @@@@                                // 
//               @@@@                        @@@@ @@@@@@@@                       // 
//               @@@@    @@@@@@@@@@@@@@@@    @@@@@@@          @@@@@@@@@@@@@@@@   // 
//               @@@@                        @@@@                                // 
//     @@@@@@@@@@@@@@                        @@@@@@@@@@@@@                       // 
//               @@@@                          @@@@@@@@@@@                       // 
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////
*/

pragma solidity ^0.8.13;

import "./VertexData.sol";
import "./Fix64V1.sol";
import "./Trig256.sol";

struct Ellipse {
    int64 originX;
    int64 originY;
    int64 radiusX;
    int64 radiusY;
    uint32 steps;
}

library EllipseMethods {

    function circle(
        int64 originX,
        int64 originY,
        int64 radius
    ) external pure returns (Ellipse memory data) {
        return create_impl(originX, originY, radius, radius);
    }

    function create(
        int64 originX,
        int64 originY,
        int64 radiusX,
        int64 radiusY
    ) external pure returns (Ellipse memory data) {
        return create_impl(originX, originY, radiusX, radiusY);
    }

    function create_impl(int64 originX,
        int64 originY,
        int64 radiusX,
        int64 radiusY
    ) private pure returns (Ellipse memory data) {
        data.originX = originX;
        data.originY = originY;
        data.radiusX = radiusX;
        data.radiusY = radiusY;

        int64 ra = Fix64V1.div(
            Fix64V1.add(
                int64(Fix64V1.abs(int64(radiusX))),
                int64(Fix64V1.abs(int64(radiusY)))
            ),
            Fix64V1.TWO
        );

        int64 da = Fix64V1.mul(
            Trig256.acos(
                Fix64V1.div(
                    ra,
                    Fix64V1.add(
                        ra,
                        Fix64V1.div(
                            536870912, /* 0.125 */
                            Fix64V1.ONE
                        )
                    )
                )
            ),
            Fix64V1.TWO
        );

        int64 t1 = Fix64V1.mul(Fix64V1.TWO, Fix64V1.div(Fix64V1.PI, da));
        data.steps = uint32(int32(Fix64V1.round(t1) / Fix64V1.ONE));
        return data;
    }

    function vertices(Ellipse memory data)
        external
        pure
        returns (VertexData[] memory results)
    {
        results = new VertexData[](data.steps + 3);

        VertexData memory v0;
        v0.command = Command.MoveTo;
        v0.position = Vector2(
            Fix64V1.add(data.originX, data.radiusX),
            data.originY
        );
        results[0] = v0;

        int64 anglePerStep = Fix64V1.div(
            Fix64V1.TWO_PI,
            int32(data.steps) * Fix64V1.ONE
        );
        int64 angle = 0;
        
        for (uint32 i = 1; i < uint32(data.steps); i++) {

            VertexData memory v1;
            v1.command = Command.LineTo;

            angle = Fix64V1.add(angle, anglePerStep);

            int64 x = Fix64V1.add(
                data.originX,
                Fix64V1.mul(Trig256.cos(angle), data.radiusX)
            );

            int64 y = Fix64V1.add(
                data.originY,
                Fix64V1.mul(Trig256.sin(angle), data.radiusY)
            );

            v1.position = Vector2(x, y);
            results[i] = v1;
        }

        VertexData memory v2;
        v2.position = Vector2(0, 0);
        v2.command = Command.EndPoly;
        results[uint32(data.steps)] = v2;

        VertexData memory v3;
        v3.command = Command.Stop;
        results[uint32(data.steps + 1)] = v3;
    }
}