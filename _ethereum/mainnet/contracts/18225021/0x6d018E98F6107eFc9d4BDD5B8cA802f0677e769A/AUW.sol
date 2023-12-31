// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AYKANUMUT.WEB32.2023
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//    SMART CONTRACT BY: AYKAN UMUT                                                  //
//    SMART CONTRACT: AYKANUMUT.WEB32.2023                                           //
//    SMART CONTRACT TYPE: ERC721                                                    //
//    SMART CONTRACT SYMBOL: AUW                                                     //
//    CREATED ON THE OCCASSION OF WEB32 ON SEPTEMBER 27 2023 IN ANTWERP (BELGIUM)    //
//    SUPPORT: A.P./STUDIO X PLUS-ONE GALLERY                                        //
//    MAIL: HELLO@AYKAN.BE                                                           //
//    WEB: AYKAN.BE                                                                  //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract AUW is ERC721Creator {
    constructor() ERC721Creator("AYKANUMUT.WEB32.2023", "AUW") {}
}
