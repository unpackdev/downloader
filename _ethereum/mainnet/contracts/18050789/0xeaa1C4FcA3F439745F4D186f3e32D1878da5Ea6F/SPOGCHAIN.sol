// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spogel onchain
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//        _,aaaaaaaaaaaaaaaaaaa,_                _,aaaaaaaaaaaaaaaaaaa,_        //
//      ,P"                     "Y,            ,P"                     "Y,      //
//     d'    ,aaaaaaaaaaaaaaa,    `b          d'    ,aaaaaaaaaaaaaaa,    `b     //
//    d'   ,d"            ,aaabaaaa8aaaaaaaaaa8aaaadaaa,            "b,   `b    //
//    I    I              I                            I      ,adba,  I    I    //
//    Y,   `Y,            `aaaaaaaaaaaaaaaaaaaaaaaaaaaa'      I    I,P'   ,P    //
//     Y,   `baaaaaaaaaaaaaaad'   ,P          Y,   `baaaaaaaaaI    Id'   ,P     //
//      `b,                     ,d'            `b,            I    I   ,d'      //
//        `baaaaaaaaaaaaaaaaaaad'                `baaaaaaaaaaaI    Iaad'        //
//                                                            I    I            //
//                           Spøgelmaskinen onchain           I    I            //
//                                                            I    I            //
//        _,aaaaaaaaaaaaaaaaaaa,_                _,aaaaaaaaaaaI    Iaa,_        //
//      ,P"                     "Y,            ,P"            I    I   "Y,      //
//     d'    ,aaaaaaaaaaaaaaa,    `b          d'    ,aaaaaaaaaI    I,    `b     //
//    d'   ,d"            ,aaabaaaa8aaaaaaaaaa8aaaadaaa,      I    I"b,   `b    //
//    I    I  ,adba,      I                            I      `"YP"'  I    I    //
//    Y,   `Y,I    I      `aaaaaaaaaaaaaaaaaaaaaaaaaaaa'            ,P'   ,P    //
//     Y,   `bI    Iaaaaaaaaad'   ,P          Y,   `baaaaaaaaaaaaaaad'   ,P     //
//      `b,   I    I            ,d'            `b,                     ,d'      //
//        `baaI    Iaaaaaaaaaaad'                `baaaaaaaaaaaaaaaaaaad'        //
//            I    I                                                            //
//            I    I                                                            //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract SPOGCHAIN is ERC721Creator {
    constructor() ERC721Creator("Spogel onchain", "SPOGCHAIN") {}
}
