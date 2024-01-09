
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MightyMooseART
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//               ..       :           ..       :             //
//              ,W,     .Et          ,W,     .Et             //
//             t##,    ,W#t         t##,    ,W#t             //
//            L###,   j###t        L###,   j###t             //
//          .E#j##,  G#fE#t      .E#j##,  G#fE#t             //
//         ;WW; ##,:K#i E#t     ;WW; ##,:K#i E#t             //
//        j#E.  ##f#W,  E#t    j#E.  ##f#W,  E#t             //
//      .D#L    ###K:   E#t  .D#L    ###K:   E#t             //
//     :K#t     ##D.    E#t :K#t     ##D.    E#t             //
//     ...      #G      ..  ...      #G      ..              //
//                                                           //
//                                                           //
//                   j.                                      //
//                .. EW,         GEEEEEEEL                   //
//               ;W, E##j        ,;;L#K;;.                   //
//              j##, E###D.         t#E                      //
//             G###, E#jG#W;        t#E                      //
//           :E####, E#t t##f       t#E                      //
//          ;W#DG##, E#t  :K#E:     t#E                      //
//         j###DW##, E#KDDDD###i    t#E                      //
//        G##i,,G##, E#f,t#Wi,,,    t#E                      //
//      :K#K:   L##, E#t  ;#W:      t#E                      //
//     ;##D.    L##, DWi   ,KK:      fE                      //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract MMART is ERC721Creator {
    constructor() ERC721Creator("MightyMooseART", "MMART") {}
}
