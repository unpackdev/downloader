
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ASH Collector Card
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//    o.                                                                                              .cKM    //
//    .                                                                                                 cX    //
//                                                                                                      .x    //
//                                                                                                      .d    //
//                                                                                                      .d    //
//                                                                                                      .d    //
//                        .. .'... .  .....'...  .  .'.......''..'.....  ............'..                .d    //
//                       ..............ASH.........COLLECTOR.........CARD................               .d    //
//                       .'',',,;'... .''''''','.,'.,,.',''.....''','... .'''''';..';,'.                .d    //
//                                                                                                      .d    //
//                                                                                                      .d    //
//                                                                                                      .d    //
//                                                 .                                                    .d    //
//                                             .cc;'..;;;,.','.                                         .d    //
//                                          ..'oOOd:;:oddooxxdl::;.                                     .d    //
//                                         .'';c:ldocloc:::dOxookkc.                                    .d    //
//                                     ...,,'.',..;ddc'    ;ddooxkxc.                                   .d    //
//                                   .';;;:;.....,,.l:     :ko::oolc'                                   .d    //
//                                   .';;,;,.....;c'::    .xOl,'..,;.                                   .d    //
//                                    .'.....'....,;od.  .ok;     ..                                    .d    //
//                                    .......       .oo::oo.                                            .d    //
//                                     .....         .oKKo.                                             .d    //
//                                        .           :00:                                              .d    //
//                                                    :00:                                              .d    //
//                                                    ,dd,                                              .d    //
//                                                                                                      .d    //
//                                                                                                      .d    //
//                                                                                                      .d    //
//                                                                                                      .d    //
//                                                                                                      .d    //
//                                                                                                      .d    //
//                                                                                                      .d    //
//    x;...............................................................................................'l0    //
//    MWKkddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxOXM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ASHCC is ERC721Creator {
    constructor() ERC721Creator("ASH Collector Card", "ASHCC") {}
}
