
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: An Ordinary Life
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWNXKXXKKXXXXKXNWWWWWWWWWWWWWWWWWWWWWWWWNK0OkkkxxkkO0XNWWWWWWWWWWWWWWWWNXXXXXXXXKXNWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWO,..........,OWWWWWWWWWWWWWWWWWWWWKkl:'..         ..':okKWWWWWWWWWWWWk,........'xWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWK,            ,KWWWWWWWWWWWWWWWWNkc.                     .ckNWWWWWWWWWx.         dWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWXc              cXWWWWWWWWWWWWWNO;                           ;OWWWWWWWWx.         dWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWNd.              .dNWWWWWWWWWWWNd.           ...''..           .xNWWWWWWx.         dWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWk.       .        .kWWWWWWWWWWWd.         .ckKXXNNX0x:.         .xWWWWWWx.         dWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWK,       .oc        ,KWWWWWWWWW0'         'kWWWWWWWWWWNx.         ,KWWWWWx.         dWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWXc        :X0'        cXWWWWWWWWo         .dWWWWWWWWWWWWWo         .dWWWWWx.         dWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWNo.       .OWWd.       .dNWWWWWWX:         '0WWWWWWWWWWWWWO.         cNWWWWx.         dWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWk.        lNWWX:        .kWWWWWWX;         ,KWWWWWWWWWWWWW0'         :NWWWWx.         dWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWW0,        ,KWWWWO.        ,KWWWWWX:         '0WWWWWWWWWWWWWO.         cNWWWWx.         dWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWXc         ,oooooo.         cXWWWWNl         .kWWWWWWWWWWWWWd          dWWWWWx.         dWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWNo.                          .oNWWWWO.         ;KWWWWWWWWWWW0,         '0WWWWWx.         oWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWk.                            .kWWWWNo          'dKNWWWWWNKd'         .dNWWWWWx.         cOOOOOOOOOOOOOOOKNWWWWW    //
//    WWWWWWW0,                              ,0WWWWXl.          .,;:cc:,.          .oNWWWWWWx.                         :XWWWWW    //
//    WWWWWWXc         'ddddddddddxl.         cXWWWWNx'                           'xNWWWWWWWx.                         ;KWWWWW    //
//    WWWWWNo.        .kWWWWWWWWWWWNl         .oNWWWWWKd,                       ,dKWWWWWWWWWx.                         ;KWWWWW    //
//    WWWWWO'        .lNWWWWWWWWWWWWK;         'OWWWWWWWXOo;'.             .':oONWWWWWWWWWWWk.                         :XWWWWW    //
//    WWWWWKOOOOOOOOO0XWWWWWWWWWWWWWWKOOOOOOOOOOXWWWWWWWWWWWXKOxddoooooddxO0XWWWWWWWWWWWWWWWX0OOOOOOOOOOOOOOOOOOOOOOOOOKNWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AOL is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
