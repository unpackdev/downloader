// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KONOKA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                            //    //
//    //                                                                            //    //
//    //                                                                            //    //
//    //                   ..&g-, .,      ....(J+J(-...                             //    //
//    //               (JdMMMMMMMNMNN.+MMMMMMMMMMMMMMMMMMNa.,                       //    //
//    //              .gQMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN,                    //    //
//    //             .MMMNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMe...               //    //
//    //            .MMMMMMMMMNQHNHNMNHMMNkMMMMMMMMMMMMMMMMMMMMMMMMNMMMMNa,         //    //
//    //           .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNMMHNM#MMMMMMMMMMMMMMMMMMN,       //    //
//    //            .MHMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNMNMMNMMMMMMMMMMMMM@=     //    //
//    //           ~/"dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNMMMMMMNNMN,     //    //
//    //              -MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMb     //    //
//    //               (MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMF     //    //
//    //               .GMMMMMMMMMMMMMMMMMNMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN`     //    //
//    //               ,JMMMMMMMMMMM#MMMM#(#vMMMMMWMMMMMMdMMMMMMMMMMMMMMMMMTM.      //    //
//    //               _dMMMMMMMMMM?57"""!(3(7"T9YdMMMM#5MMMMMMMMMMMMMMMMM@",^      //    //
//    //                JMMMMMNMF.._(gMMMMQ,..........__-HdMMM#MMMMMMMMMD'          //    //
//    //            `    WdMMMNM%--"~J .MMb?!........._((J./7"(#MMMMMMM#            //    //
//    //                 .3MMMMM_. `.MMMMMM ........._1?4NNWN-.(TMMMMMMF            //    //
//    //                 ..dMMM#.._`,N9TBMt..........(MaMMd](H-.JMMMMM@             //    //
//    //                  _dMMd#..~~_-<~~_...........,MMMMN}`(3(MMMMMD              //    //
//    //            `      JMMd#.~~~:::~~............~_~(dY` ..JMMMF`               //    //
//    //                     .H....~.................~~:__~...(MMM#                 //    //
//    //                       !-............_........~_~::~~_MMMM'                 //    //
//    //                        .m,...........~............._?MMM'          `       //    //
//    //            `            .dvJ............~........_                         //    //
//    //                   `       \j ~~.............._`                `           //    //
//    //               `     `        .~~~~~~~.~.~-=(                 .             //    //
//    //            `   ..(::::_-     ``_JMMNNMMMM@     ..ggNgJ,   ` JM!   .,  `    //    //
//    //               (::::::::~     `    ``JM9^  `  (M@^.M# ?MN..HMMM""MNJMN.     //    //
//    //              (::::::::~   `     .g[         JM'  JM^::(M]  .M]  ,M).H#     //    //
//    //           ` (::::::::`     `    M#          MN..MM' <+MM<<.M@   (M!        //    //
//    //             :::::::~    `   `   (YMMMMMMMMt .TMY= .NMM8::(M@.MNNMD         //    //
//    //            .::::::~   `  `  ` `  ` `` `  `            <:::::<              //    //
//    //                                                                            //    //
//    //                                                                            //    //
//    ////////////////////////////////////////////////////////////////////////////////    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract KNK is ERC721Creator {
    constructor() ERC721Creator("KONOKA", "KNK") {}
}
