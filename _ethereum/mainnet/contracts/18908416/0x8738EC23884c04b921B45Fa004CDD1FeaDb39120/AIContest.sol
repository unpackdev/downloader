// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Claire Silver Ai Contest
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                .,;;;;;;;;;;;;;;;;;;;;;;;;;;;;,.                                                //
//                                                :XWWWWWWWWWWWWWWWWWWWWWWWWWWWWX:                                                //
//                                                cXMMMMMMMMWNNNNWMMMMMMMMMMMMMMXc                                                //
//                                           'xkkkKWMMMMMMMWx''''xNWMMMMMMMMMMMMWKkkkx'                                           //
//                                           :XMMMMMMMMMMMMWl    lXWMMMMMMMMMMMMMMMMMX:                                           //
//                                      .,;;;dNMMMMMMMMMMMMWkc:::lddddd0WMMMMMMMMMMMMNd;;;,.                                      //
//                                      :XWWWWMMMMMMMMMMMMMMMMMMWl.    lWMMMMMMMMMMMMMWWWWX:                                      //
//                                      :XMMMMMMMMMMMMMMMMMMMMMMWo..  .oWMMMMMMMMMMMMMMMMMX:                                      //
//                                      :XMMMMMMMMMMMMMMMMMMMMMMMX00OO0XMMMMMMMMMMMMMMMMMMX:                                      //
//                                      :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:                                      //
//                                      ;0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0;                                      //
//                                      'oddddddddddddddddddddddddddddddddddddddddddddddddo'                                      //
//                                      ,oddddddddddddddddddddddddddddddddddddddddddddddddo,                                      //
//                                 .:::cldddddddddoc:::::::codddddddddddddddoc:::::::coddddlc:::.                                 //
//                                 'odddddddddddddl;,,,,,,,;ldddddddddddddddl;,,,,,,,;lddddddddo'                                 //
//                                 'oddddddddolllllc:::::::clllloodddddolllllc:::::::coddddddddo'                                 //
//                                 'oddddddddl;,,;coddddddddc;,,;ldddddl;,,;codddddddddddddddddo'                                 //
//                                 ,oddddddddl;,,,cddddddddoc,,,;ldddddl;,,,cdxddddddddddddddddo,                                 //
//                            .:::clddddoc:::;,,,;dXXXXkcccc;,,,,:c:::::;,,;dXXXXkccccodddddddddlc:::.                            //
//                            'oddddddddl;,,,,,,,;kWMMWk::::;,,,,,,,,,,,,,,;xWMMWk::::ldddddddddddddo'                            //
//                            'oddddddddocccc:,,,,oOOOOo:;;;;,,,,,,,,,,,,,,;oOOOOo:;;:ldddddddddddddo'                            //
//                            'odddddddddddddl;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;ldddddddddddddo'                            //
//                            'odddddddddddddl;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;ldddddddddddddo'                            //
//                            'odddddddddddddl;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;ldddddddddddddo'                            //
//                            'odddddddddddddl;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;ldddddddddddddo'                            //
//                            'odddddddddddddl;,,,,,,,,,,,,,,,,,,coodooc,,,,,,,,,,,,,;ldddddddddddddo'                            //
//                            'odddddddddddddl;,,,,,,,,,,,,,,,,,;xNWMMWx;,,,,,,,,,,,,;ldddddddddddddo'                            //
//                            'odddddddddddddl;,,,,,,,,,,,,,,,,,;xXNWWNx;,,,,,,,,,,,,;ldddddddddddddo'                            //
//                            'odddddddddddddl;,,,,,,,,,,,,,,,,,,:lloll:,,,,,,,,,,,,,;ldddddddddddddo'                            //
//                            'odddddddddddddl;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;ldddddddddddddo'                            //
//                            .;;;:ldddddddddl;,,,,,,,,,,,,,coooooooooooooooc,,,,,,,,;ldddddddddl:;;;.                            //
//                                 ,oddddddddl;,,,,,,,,,,,,;xWMMMMMMMMMWMMMWx;,,,,,,,;lddddddddo,                                 //
//                                 'oddddddddl:;;;;,,,,,,,,;xNWWWWWWWWWWWWWNx;,,,;;;;:lddddddddo'                                 //
//                                 'odddddddddooooc;,,,,,,,,:loooooooooooool:,,,;coooodddddddddo'                                 //
//                                 'odddddddddddddl;,,,,,,,,,,,,,,,,,,,,,,,,,,,,;ldddddddddddddo'                                 //
//                                 .;;;:ldddddddddl;,,,cooooc,,,,,,,,,,,,,,,cooodddddddddddl:;;;.                                 //
//                                      ,oddddddddl;,,;xWMMWx;,,,,,,,,,,,,,;xWMMW0ddddddddo,                                      //
//                                      'oooodddddl;,,;xWWWWx;;;;;;;;;;;;;;;xXNNNOdoooooodo'                                      //
//                                       ....c0XXKd;,,,:looox00000000000000Oc''''..........                                       //
//                                           :XMMWx;,,,,,,,;kWMMMMMMMMMMMMMX:                                                     //
//                                           :XMMWk;,,,,,,,;oO000XWMMMW0dddo'                                                     //
//                                           :XMMWx;,,,,,,,,,,,,;kNWMMN:                                                          //
//                                           :XMMWx;,,,,,,,,,,,,;xNWMMX:                                                          //
//                                           :XMMWx;,,,,,,,,,,,,;xNWMMX:                                                          //
//                                           :XMMWx;,,,,,,,,,,,,;xNWMMX:                                                          //
//                                           :XMMWx;,,,,,,,,,,,,;xNWMMX:                                                          //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AIContest is ERC721Creator {
    constructor() ERC721Creator("Claire Silver Ai Contest", "AIContest") {}
}
