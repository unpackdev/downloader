// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UNFOLDING
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//                                                                                               //
//    .s    s.  .s    s.  .s5SSSs. .s5SSSs.  .s        .s5SSSs.  s.  .s    s.  .s5SSSs.          //
//          SS.       SS.                SS.                 SS. SS.       SS.       SS.         //
//    sS    S%S sSs.  S%S sS       sS    S%S sS        sS    S%S S%S sSs.  S%S sS    `:;         //
//    SS    S%S SS`S. S%S SS       SS    S%S SS        SS    S%S S%S SS`S. S%S SS                //
//    SS    S%S SS `S.S%S SSSs.    SS    S%S SS        SS    S%S S%S SS `S.S%S SS                //
//    SS    S%S SS  `sS%S SS       SS    S%S SS        SS    S%S S%S SS  `sS%S SS                //
//    SS    `:; SS    `:; SS       SS    `:; SS        SS    `:; `:; SS    `:; SS   ``:;         //
//    SS    ;,. SS    ;,. SS       SS    ;,. SS    ;,. SS    ;,. ;,. SS    ;,. SS    ;,.         //
//    `:;;;;;:' :;    ;:' :;       `:;;;;;:' `:;;;;;:' ;;;;;;;:' ;:' :;    ;:' `:;;;;;:'         //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


contract UNFLD is ERC1155Creator {
    constructor() ERC1155Creator("UNFOLDING", "UNFLD") {}
}
