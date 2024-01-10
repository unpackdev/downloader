// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) Joshua Davis. All rights reserved. */

pragma solidity ^0.8.13;

import "./ColorMath.sol";
import "./Matrix.sol";

import "./IUniverseMachineParameters.sol";
import "./Parameters.sol";
import "./XorShift.sol";
import "./Star.sol";

/*
////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                        //
//                                                                                                        //
//                                            ,,╓╓╥╥╥╥╥╥╥╥╖╓,                                             //
//                                      ╓╥H╢▒░░▄▄▄▄██████▄▄▄▄░░▒▒H╖,                                      //
//                                 ,╓H▒░░▄████████████████████████▄░░▒H╖                                  //
//                              ╓╥▒░▄██████████████████████████████████▄░▒b,                              //
//                           ╓║▒░▄████████████████████████████████████████▄░▒H╓                           //
//                        ╓╥▒░▄██████████████████████████████████████████████▄░▒╥,                        //
//                      ╓╢░▄████▓███████████████████████████████████████████████▄░▒╖                      //
//                    ╥▒░████▓████████████████████████████████████████████████████▄░▒╖                    //
//                  ╥▒░████▓█████████████████████████████████████████████████████████░▒╖                  //
//                ╥▒░████▓████████████████████████████████████████████████████████▓████░▒╖                //
//              ╓▒░█████▓███████████████████████████████████████████████████████████▓████░▒╖              //
//            ,║▒▄████▓███████████████████░'▀██████████████████░]█████████████████████▓███▄▒▒             //
//           ╓▒░█████▓████████████████████▒  ░███████████████▀   ███████████████████████▓███░▒╖           //
//          ╥▒▄█████▓█████████████████████░    └▀▀▀▀▀▀▀▀██▀░    ;████████████████████████▓███▄▒╥          //
//         ╢▒██████▓██████████████████████▌,                    ░█████████████████████████████▌▒▒         //
//        ▒▒██████▓████████████████████████▌     ,, ,╓, ,,     ¿████████████████████████████████▒▒        //
//       ╢▒██████▓█████████████████████████▌    ▒██▒█░█░██░   .█████████████████████████████▓███▌▒▒       //
//      ]▒▐█████▓███████████████████████████▒       ░▀▀        ██████████████████████████████████░▒┐      //
//      ▒░██████▓███████████████████████████                   ▐█████████████████████████████▓████▒▒      //
//     ]▒▐█████▓███████████████████████████░                   ░█████████████████████████████▓████░▒L     //
//     ▒▒██████▓██████████████████████████▌                     ░████████████████████████████▓████▌▒▒     //
//     ▒▒█████▓███████████████████████████░                      ▐███████████████████████████▓█████▒▒     //
//     ▒▒█████▓███████████████████████████▒                      ░███████████████████████████▓████▌▒▒     //
//     ▒▒█████▓███████████████████████████▒                      ▒██████████████████████████▓█████▌▒[     //
//     ]▒░████▓███████████████████████████░                      ▐██████████████████████████▓█████░▒      //
//      ▒▒████▓███████████████████████████▌                      ▐█████████████████████████▓█████▌▒▒      //
//      ╙▒░████▓██████████████████████████▌                      ▐███████████████████████████████░▒       //
//       ╙▒░███▓███████████████████████████░                    ░███████████████████████████████░▒`       //
//        ╙▒░███▓██████████████████████████▌                   ,█████████████████████████▓█████░▒╜        //
//         ╙▒░███▓██████████████████████████░                 ,▐████████████████████████▓█████░▒`         //
//          ╙▒░███▓███████████████████████████░             ;▄██████████████████████████████▀░▒           //
//            ╢▒▀███▓█████████████████████████▄█▌▄▄███▄▄▄,░▄▄▄███████████████████████▓█████░▒╜            //
//             ╙▒░▀███▓█████████████████████████████████████████████████████████████▓████▀░▒`             //
//               ╙▒░████▓█████████████████████████████████████████████████████████▓████▀░▒╜               //
//                 ╨▒░███████████████████████████████████████████████████████████▓███▀░▒╜                 //
//                   ╙▒░▀██████████████████████████████████████████████████████▓███▀░▒╜                   //
//                     ╙▒░▀█████████████████████████████████████████████████▓████▀░▒╜                     //
//                       `╨▒░▀████████████████████████████████████████████████▀▒░╨`                       //
//                          ╙▒░░▀██████████████████████████████████████████▀░░▒╜                          //
//                             ╙╣░░▀████████████████████████████████████▀▒░▒╜                             //
//                                ╙╨▒░░▀████████████████████████████▀░░▒╜`                                //
//                                    ╙╨╢▒░░▀▀███████████████▀▀▀▒░▒▒╜`                                    //
//                                         `╙╙╨╨▒▒░░░░░░░░▒▒╨╨╜"`                                         //
//                                                                                                        //
//       ▄▄▄██▀▀▀▒█████    ██████  ██░ ██  █    ██  ▄▄▄      ▓█████▄  ▄▄▄    ██▒   █▓ ██▓  ██████         //
//         ▒██  ▒██▒  ██▒▒██    ▒ ▓██░ ██▒ ██  ▓██▒▒████▄    ▒██▀ ██▌▒████▄ ▓██░   █▒▓██▒▒██    ▒         //
//         ░██  ▒██░  ██▒░ ▓██▄   ▒██▀▀██░▓██  ▒██░▒██  ▀█▄  ░██   █▌▒██  ▀█▄▓██  █▒░▒██▒░ ▓██▄           //
//      ▓██▄██▓ ▒██   ██░  ▒   ██▒░▓█ ░██ ▓▓█  ░██░░██▄▄▄▄██ ░▓█▄   ▌░██▄▄▄▄██▒██ █░░░██░  ▒   ██▒        //
//       ▓███▒  ░ ████▓▒░▒██████▒▒░▓█▒░██▓▒▒█████▓  ▓█   ▓██▒░▒████▓  ▓█   ▓██▒▒▀█░  ░██░▒██████▒▒        //
//       ▒▓▒▒░  ░ ▒░▒░▒░ ▒ ▒▓▒ ▒ ░ ▒ ░░▒░▒░▒▓▒ ▒ ▒  ▒▒   ▓▒█░ ▒▒▓  ▒  ▒▒   ▓▒█░░ ▐░  ░▓  ▒ ▒▓▒ ▒ ░        //
//       ▒ ░▒░    ░ ▒ ▒░ ░ ░▒  ░ ░ ▒ ░▒░ ░░░▒░ ░ ░   ▒   ▒▒ ░ ░ ▒  ▒   ▒   ▒▒ ░░ ░░   ▒ ░░ ░▒  ░ ░        //
//       ░ ░ ░  ░ ░ ░ ▒  ░  ░  ░   ░  ░░ ░ ░░░ ░ ░   ░   ▒    ░ ░  ░   ░   ▒     ░░   ▒ ░░  ░  ░          //
//       ░   ░      ░ ░        ░   ░  ░  ░   ░           ░  ░   ░          ░  ░   ░   ░        ░          //
//                                                          ░                  ░                          //
//     ██▓███   ██▀███   ▄▄▄     ▓██   ██▓  ██████ ▄▄▄█████▓ ▄▄▄     ▄▄▄█████▓ ██▓ ▒█████   ███▄    █     //
//    ▓██░  ██▒▓██ ▒ ██▒▒████▄    ▒██  ██▒▒██    ▒ ▓  ██▒ ▓▒▒████▄   ▓  ██▒ ▓▒▓██▒▒██▒  ██▒ ██ ▀█   █     //
//    ▓██░ ██▓▒▓██ ░▄█ ▒▒██  ▀█▄   ▒██ ██░░ ▓██▄   ▒ ▓██░ ▒░▒██  ▀█▄ ▒ ▓██░ ▒░▒██▒▒██░  ██▒▓██  ▀█ ██▒    //
//    ▒██▄█▓▒ ▒▒██▀▀█▄  ░██▄▄▄▄██  ░ ▐██▓░  ▒   ██▒░ ▓██▓ ░ ░██▄▄▄▄██░ ▓██▓ ░ ░██░▒██   ██░▓██▒  ▐▌██▒    //
//    ▒██▒ ░  ░░██▓ ▒██▒ ▓█   ▓██▒ ░ ██▒▓░▒██████▒▒  ▒██▒ ░  ▓█   ▓██▒ ▒██▒ ░ ░██░░ ████▓▒░▒██░   ▓██░    //
//    ▒▓▒░ ░  ░░ ▒▓ ░▒▓░ ▒▒   ▓▒█░  ██▒▒▒ ▒ ▒▓▒ ▒ ░  ▒ ░░    ▒▒   ▓▒█░ ▒ ░░   ░▓  ░ ▒░▒░▒░ ░ ▒░   ▒ ▒     //
//    ░▒ ░       ░▒ ░ ▒░  ▒   ▒▒ ░▓██ ░▒░ ░ ░▒  ░ ░    ░      ▒   ▒▒ ░   ░     ▒ ░  ░ ▒ ▒░ ░ ░░   ░ ▒░    //
//    ░░         ░░   ░   ░   ▒   ▒ ▒ ░░  ░  ░  ░    ░        ░   ▒    ░       ▒ ░░ ░ ░ ▒     ░   ░ ░     //
//                ░           ░  ░░ ░           ░                 ░  ░         ░      ░ ░           ░     //
//                                                                                                        //
//                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

contract UniverseMachineParameters is IUniverseMachineParameters {

    int32 public constant StageW = 1505;
    int32 public constant StageH = 2228;
    
    uint8 public constant NumCols = 4;
    uint8 public constant NumRows = 7;
    uint16 public constant GridSize = NumCols * NumRows;

    uint8 public constant NumTextures = 8;
    uint16 public constant NumColors = 750;

    uint8 public constant ColorSpread = 150;    
    int16 public constant GridMaxMargin = -335;
    uint8 public constant StarMax = 150;

    uint32[5][10] clrs;
    uint8[4][56] masterSet;

    constructor() {
        clrs = [
            [0xFFA59081, 0xFFF26B8F, 0xFF3C7373, 0xFF7CC4B0, 0xFFF2F2F5],
            [0xFFF2F2F5, 0xFF0C2F40, 0xFF335E71, 0xFF71AABF, 0xFFA59081],
            [0xFFF35453, 0xFF007074, 0xFFD2D8BE, 0xFFEFCF89, 0xFFF49831],
            [0xFF2B5D75, 0xFFF35453, 0xFFF2F2F5, 0xFF5E382C, 0xFFCB7570],
            [0xFFF9C169, 0xFF56C4B5, 0xFF214B73, 0xFF16163F, 0xFF9A5E1F],
            [0xFFFBE5B6, 0xFFF9C169, 0xFF9C7447, 0xFF775D40, 0xFF4A5343],
            [0xFFE2EBE1, 0xFFE7D9AD, 0xFF63AA62, 0xFF0C3A3C, 0xFF87C4C2],
            [0xFFE8E8E8, 0xFFB9B9B9, 0xFF666666, 0xFF262626, 0xFF65D8E4],
            [0xFF466E8B, 0xFFFEF5E7, 0xFFF1795E, 0xFF666073, 0xFF192348],
            [0xFFFFFFFF, 0xFF8C8C8C, 0xFF404040, 0xFF8C8C8C, 0xFFF2F2F2]
        ];

        masterSet = [
            [1, 5, 4, 2],
            [6, 5, 4, 3],
            [4, 1, 4, 2],
            [4, 1, 0, 2],
            [4, 1, 2, 2],
            [4, 5, 4, 1],
            [3, 5, 3, 0],
            [3, 0, 3, 0],
            [3, 5, 2, 0],
            [3, 2, 2, 0],
            [3, 1, 2, 0],
            [3, 0, 2, 0],
            [2, 4, 4, 1],
            [2, 4, 2, 1],
            [2, 3, 4, 1],
            [2, 3, 0, 1],
            [2, 1, 4, 1],
            [2, 1, 0, 1],
            [2, 1, 4, 2],
            [2, 1, 0, 2],
            [2, 1, 2, 2],
            [2, 0, 4, 1],
            [2, 5, 4, 1],
            [2, 5, 0, 1],
            [2, 5, 4, 2],
            [2, 5, 0, 2],
            [2, 5, 2, 2],
            [1, 4, 0, 1],
            [1, 3, 4, 1],
            [1, 3, 0, 1],
            [1, 3, 2, 1],
            [1, 1, 4, 1],
            [1, 1, 4, 2],
            [1, 1, 0, 2],
            [1, 1, 2, 2],
            [1, 0, 4, 0],
            [1, 0, 4, 1],
            [1, 5, 2, 1],
            [1, 5, 4, 2],
            [1, 5, 0, 2],
            [1, 5, 2, 2],
            [0, 1, 2, 2],
            [0, 5, 4, 2],
            [0, 5, 2, 2],
            [6, 4, 2, 1],
            [6, 3, 4, 1],
            [6, 3, 2, 1],
            [6, 1, 4, 2],
            [6, 1, 0, 2],
            [6, 1, 2, 2],
            [6, 0, 4, 1],
            [6, 0, 0, 1],
            [6, 0, 2, 1],
            [6, 5, 4, 2],
            [6, 5, 0, 2],
            [6, 5, 2, 2]
        ];
    }

    function getUniverse(uint8 index)
        external
        override
        view
        returns (uint8[4] memory universe)
    {
        return masterSet[uint32(index)];
    }

    function getParameters(uint256 tokenId, int32 seed)
        external
        override
        view
        returns (Parameters memory parameters) 
    {
        {
            (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                seed,
                1 * Fix64V1.ONE,
                55 * Fix64V1.ONE
            );
            parameters.whichMasterSet = tokenId == 0 ? 0 : uint32(value);
            seed = modifiedSeed;
        }

        {
            (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                seed,
                0 * Fix64V1.ONE,
                9 * Fix64V1.ONE
            );
            parameters.whichColor = value;
            seed = modifiedSeed;
        }

        {
            (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                seed,
                0 * Fix64V1.ONE,
                int16(GridSize - 1) * Fix64V1.ONE
            );
            parameters.endIdx = value;
            seed = modifiedSeed;
        }

        buildColors(parameters);

        {
            (Universe memory universe, int32 modifiedSeed) = buildUniverse(parameters, seed);
            seed = modifiedSeed;

            buildGrid(parameters);

            buildPaths(parameters, universe);

            buildStars(parameters, seed);
        }        
    }

    function buildColors(Parameters memory parameters) private view {

        uint32[5] memory whichClr = clrs[uint32(parameters.whichColor)];
        
        int64 inter = Fix64V1.div(Fix64V1.ONE, int64(uint64(uint8(ColorSpread))) * Fix64V1.ONE);

        parameters.myColorsR = new uint8[](NumColors);
        parameters.myColorsG = new uint8[](NumColors);
        parameters.myColorsB = new uint8[](NumColors);        

        uint32 index = 0;
        for (uint32 i = 0; i < whichClr.length; i++)
        {
            uint32 j = i == whichClr.length - 1 ? 0 : i + 1;

            for (uint32 x = 0; x < ColorSpread; x++)
            {
                int64 m = int64(uint64(uint8(x))) * Fix64V1.ONE;
                uint32 c = ColorMath.lerp(whichClr[i], whichClr[j], Fix64V1.mul(inter, m));
                
                parameters.myColorsR[index] = uint8(c >> 16);
                parameters.myColorsG[index] = uint8(c >>  8);
                parameters.myColorsB[index] = uint8(c >>  0);

                index++;
            }
        }
        parameters.cLen = int16(NumColors);
    }

    struct Universe {
        int32[] whichBezierPattern;
        int32[] whichGridPos;
        int32[] whichBezierH1a;
        int32[] whichBezierH1b;
        int32[] whichBezierH2a;
        int32[] whichBezierH2b;
    }

    function buildUniverse(Parameters memory parameters, int32 seed)
        private
        view
        returns (Universe memory universe, int32)
    {
        parameters.whichTex = new int32[](GridSize);
        parameters.whichColorFlow = new int32[](GridSize);
        parameters.whichRot = new int32[](GridSize);
        parameters.whichRotDir = new int32[](GridSize);

        universe.whichBezierPattern = new int32[](GridSize);
        universe.whichGridPos = new int32[](GridSize);
        universe.whichBezierH1a = new int32[](GridSize);
        universe.whichBezierH1b = new int32[](GridSize);
        universe.whichBezierH2a = new int32[](GridSize);
        universe.whichBezierH2b = new int32[](GridSize);        

        for (uint16 i = 0; i < GridSize; i++) {
            {
                uint256 _case = masterSet[uint32(parameters.whichMasterSet)][0];

                if (_case == 0) {
                    universe.whichBezierPattern[i] = 0;
                } else if (_case == 1) {
                    universe.whichBezierPattern[i] = 1;
                } else if (_case == 2) {
                    universe.whichBezierPattern[i] = 2;
                } else if (_case == 3) {
                    universe.whichBezierPattern[i] = 3;
                } else if (_case == 4) {
                    universe.whichBezierPattern[i] = 4;
                } else if (_case == 5) {
                    universe.whichBezierPattern[i] = 5;
                } else if (_case == 6) {
                    (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                        seed,
                        0,
                        int8(5) * Fix64V1.ONE
                    );
                    universe.whichBezierPattern[i] = value;
                    seed = modifiedSeed;
                }
            }

            {
                uint256 _case = masterSet[uint32(parameters.whichMasterSet)][1];

                if (_case == 0) {
                    parameters.whichTex[i] = 0;
                } else if (_case == 1) {
                    parameters.whichTex[i] = 1;
                } else if (_case == 2) {
                    parameters.whichTex[i] = 2;
                } else if (_case == 3) {
                    parameters.whichTex[i] = 3;
                } else if (_case == 4) {
                    parameters.whichTex[i] = 4;
                } else if (_case == 5) {
                    (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                        seed,
                        0,
                        (int8(NumTextures) - 2) * Fix64V1.ONE
                    );
                    parameters.whichTex[i] = value;
                    seed = modifiedSeed;
                }
            }

            {
                uint256 _case = masterSet[uint32(parameters.whichMasterSet)][2];

                if (_case == 0) {
                    parameters.whichColorFlow[i] = 0;
                } else if (_case == 1) {
                    parameters.whichColorFlow[i] = 1;
                } else if (_case == 2) {
                    parameters.whichColorFlow[i] = 2;
                } else if (_case == 3) {
                    parameters.whichColorFlow[i] = 3;
                } else if (_case == 4) {
                    (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                        seed,
                        0,
                        3 * Fix64V1.ONE
                    );
                    parameters.whichColorFlow[i] = value;
                    seed = modifiedSeed;
                }
            }

            {
                uint256 _case = masterSet[uint32(parameters.whichMasterSet)][3];

                if (_case == 0) {
                    parameters.whichRot[i] = 0;
                } else if (_case == 1) {
                    parameters.whichRot[i] = 1;
                } else if (_case == 2) {
                    parameters.whichRot[i] = 2;
                } else if (_case == 3) {
                    parameters.whichRot[i] = 3;
                } else if (_case == 4) {
                    (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                        seed,
                        0,
                        2 * Fix64V1.ONE
                    );
                    parameters.whichRot[i] = value;
                    seed = modifiedSeed;
                }
            }

            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    0 * Fix64V1.ONE,
                    1 * Fix64V1.ONE
                );
                parameters.whichRotDir[i] = value;
                seed = modifiedSeed;
            }

            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    0 * Fix64V1.ONE,
                    (int16(GridSize) - 1) * Fix64V1.ONE
                );
                universe.whichGridPos[i] = value;
                seed = modifiedSeed;
            }

            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    -(Fix64V1.div(StageW * Fix64V1.ONE, Fix64V1.TWO)),
                    Fix64V1.div(StageW * Fix64V1.ONE, Fix64V1.TWO)
                );
                universe.whichBezierH1a[i] = value;
                seed = modifiedSeed;
            }

            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    -(StageH * Fix64V1.ONE),
                    StageH * Fix64V1.ONE
                );
                universe.whichBezierH1b[i] = value;
                seed = modifiedSeed;
            }

            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    -(Fix64V1.div(StageW * Fix64V1.ONE, Fix64V1.TWO)),
                    Fix64V1.div(StageW * Fix64V1.ONE, Fix64V1.TWO)
                );
                universe.whichBezierH2a[i] = value;
                seed = modifiedSeed;
            }

            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    -(StageH * Fix64V1.ONE),
                    StageH * Fix64V1.ONE
                );
                universe.whichBezierH2b[i] = value;
                seed = modifiedSeed;
            }
        }

        return (universe, seed);
    }

    function buildGrid(Parameters memory parameters) private pure {
        parameters.gridPoints = new Vector2[](GridSize);

        int64 ratio = Fix64V1.div(
            int8(NumCols) * Fix64V1.ONE,
            int8(NumRows) * Fix64V1.ONE
        );
        int64 margin = Fix64V1.min(
            GridMaxMargin * Fix64V1.ONE,
            Fix64V1.div(StageW * Fix64V1.ONE, Fix64V1.TWO)
        );

        int64 width = Fix64V1.sub(
            StageW * Fix64V1.ONE,
            Fix64V1.mul(margin, Fix64V1.TWO)
        );
        int64 height = Fix64V1.div(width, ratio);

        if (
            height >
            Fix64V1.sub(StageH * Fix64V1.ONE, Fix64V1.mul(margin, Fix64V1.TWO))
        ) {
            height = Fix64V1.sub(
                StageH * Fix64V1.ONE,
                Fix64V1.mul(margin, Fix64V1.TWO)
            );
            width = Fix64V1.mul(height, ratio);
        }

        for (uint16 i = 0; i < GridSize; i++) {
            uint16 col = i % NumCols;
            int64 row = Fix64V1.floor(
                Fix64V1.div(int16(i) * Fix64V1.ONE, int8(NumCols) * Fix64V1.ONE)
            );
            int64 x = Fix64V1.add(
                Fix64V1.div(-width, Fix64V1.TWO),
                Fix64V1.mul(
                    int16(col) * Fix64V1.ONE,
                    Fix64V1.div(
                        width,
                        Fix64V1.sub(int8(NumCols) * Fix64V1.ONE, Fix64V1.ONE)
                    )
                )
            );
            int64 y = Fix64V1.add(
                Fix64V1.div(-height, Fix64V1.TWO),
                Fix64V1.mul(
                    row,
                    Fix64V1.div(
                        height,
                        Fix64V1.sub(int8(NumRows) * Fix64V1.ONE, Fix64V1.ONE)
                    )
                )
            );

            parameters.gridPoints[i] = Vector2(x, y);
        }
    }

    function buildPaths(Parameters memory parameters, Universe memory universe) private pure {
        
        parameters.paths = new Bezier[](GridSize);
        parameters.numPaths = 0;

        for (uint256 i = 0; i < GridSize; i++) {
            Vector2 memory p1 = Vector2(
                parameters.gridPoints[i].x,
                parameters.gridPoints[i].y
            );
            Vector2 memory p2 = p1;
            Vector2 memory p3 = Vector2(
                parameters.gridPoints[uint32(parameters.endIdx)].x,
                parameters.gridPoints[uint32(parameters.endIdx)].y
            );
            Vector2 memory p4 = p3;

            uint32 _case = uint32(universe.whichBezierPattern[i]);

            if (_case == 1) {
                p3 = p4 = Vector2(
                    parameters.gridPoints[uint32(universe.whichGridPos[i])].x,
                    parameters.gridPoints[uint32(universe.whichGridPos[i])].y
                );
            } else if (_case == 2) {
                p3 = Vector2(
                    universe.whichBezierH1a[i] * Fix64V1.ONE,
                    universe.whichBezierH1b[i] * Fix64V1.ONE
                );
                p4 = Vector2(
                    parameters.gridPoints[uint32(universe.whichGridPos[i])].x,
                    parameters.gridPoints[uint32(universe.whichGridPos[i])].y
                );
            } else if (_case == 3) {
                p3 = p4 = Vector2(
                    parameters.gridPoints[i].x,
                    parameters.gridPoints[i].y
                );
            } else if (_case == 4) {
                p2 = Vector2(
                    universe.whichBezierH1a[i] * Fix64V1.ONE,
                    universe.whichBezierH1b[i] * Fix64V1.ONE
                );
                p3 = Vector2(
                    universe.whichBezierH2a[i] * Fix64V1.ONE,
                    universe.whichBezierH2b[i] * Fix64V1.ONE
                );
                p4 = Vector2(
                    parameters.gridPoints[uint32(universe.whichGridPos[i])].x,
                    parameters.gridPoints[uint32(universe.whichGridPos[i])].y
                );
            } else if (_case == 5) {
                p2 = Vector2(
                    universe.whichBezierH1a[i] * Fix64V1.ONE,
                    universe.whichBezierH1b[i] * Fix64V1.ONE
                );
                p3 = Vector2(
                    universe.whichBezierH2a[i] * Fix64V1.ONE,
                    universe.whichBezierH2b[i] * Fix64V1.ONE
                );
            }

            parameters.paths[parameters.numPaths++] = BezierMethods.create(
                p1,
                p2,
                p3,
                p4
            );
        }
    }

    function buildStars(Parameters memory parameters, int32 seed)
        private
        pure
        returns (int32)
    {
        parameters.starPositions = new Star[](StarMax);

        for (uint8 i = 0; i < StarMax; ++i) {
            int32 x;
            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    Fix64V1.mul(
                        parameters.gridPoints[0].x,
                        5368709120 /* 1.25 */
                    ),
                    Fix64V1.mul(
                        parameters.gridPoints[GridSize - 1].x,
                        5368709120 /* 1.25 */
                    )
                );
                x = value;
                seed = modifiedSeed;
            }

            int32 y;
            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    Fix64V1.mul(
                        parameters.gridPoints[0].y,
                        4724464128 /* 1.1 */
                    ),
                    Fix64V1.mul(
                        parameters.gridPoints[GridSize - 1].y,
                        4724464128 /* 1.1 */
                    )
                );
                y = value;
                seed = modifiedSeed;
            }

            int32 sTemp;
            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    1 * Fix64V1.ONE,
                    3 * Fix64V1.ONE
                );
                sTemp = value;
                seed = modifiedSeed;
            }

            int32 c;
            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    0,
                    (parameters.cLen - 1) * Fix64V1.ONE
                );
                c = value;
                seed = modifiedSeed;
            }

            parameters.starPositions[i] = Star(
                x,
                y,
                int16((sTemp == 1) ? 1000 : (sTemp == 2) ? 2000 : 3000),
                c
            );
        }

        return seed;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IUniverseMachineParameters).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
