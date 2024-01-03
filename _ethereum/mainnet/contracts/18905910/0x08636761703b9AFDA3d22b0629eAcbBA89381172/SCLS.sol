// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SCALES⚖️
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//    SCALES (SCLS) BY CARLO                                         //
//                                                                   //
//    <SCALING CRYPTO CULTURE--ONE MEME AT A TIME>                   //
//                                                                   //
//    CRYPTO SYMBOLIZES THE FREEDOM TO TRANSACT                      //
//    SCALES SYMBOLIZE FAIRNESS, JUSTICE AND EQUITY                  //
//    MEMES SYMBOLIZE THE ULTIMATE FREEDOM OF ARTISTIC EXPRESSION    //
//                                                                   //
//                                                                   //
//    SO, SCALE IT,                                                  //
//    MEME IT                                                        //
//    AND SHARE IT.                                                  //
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract SCLS is ERC721Creator {
    constructor() ERC721Creator(unicode"SCALES⚖️", "SCLS") {}
}
