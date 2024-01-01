// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bella Misele
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//     ,ggggggggggg,                                      ,ggg, ,ggg,_,ggg,                                               //
//    dP"""88""""""Y8,         ,dPYb, ,dPYb,             dP""Y8dP""Y88P""Y8b                           ,dPYb,             //
//    Yb,  88      `8b         IP'`Yb IP'`Yb             Yb, `88'  `88'  `88                           IP'`Yb             //
//     `"  88      ,8P         I8  8I I8  8I              `"  88    88    88   gg                      I8  8I             //
//         88aaaad8P"          I8  8' I8  8'                  88    88    88   ""                      I8  8'             //
//         88""""Y8ba  ,ggg,   I8 dP  I8 dP    ,gggg,gg       88    88    88   gg     ,g,      ,ggg,   I8 dP   ,ggg,      //
//         88      `8bi8" "8i  I8dP   I8dP    dP"  "Y8I       88    88    88   88    ,8'8,    i8" "8i  I8dP   i8" "8i     //
//         88      ,8PI8, ,8I  I8P    I8P    i8'    ,8I       88    88    88   88   ,8'  Yb   I8, ,8I  I8P    I8, ,8I     //
//         88_____,d8'`YbadP' ,d8b,_ ,d8b,_ ,d8,   ,d8b,      88    88    Y8,_,88,_,8'_   8)  `YbadP' ,d8b,_  `YbadP'     //
//        88888888P" 888P"Y8888P'"Y888P'"Y88P"Y8888P"`Y8      88    88    `Y88P""Y8P' "YY8P8P888P"Y8888P'"Y88888P"Y888    //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BM is ERC721Creator {
    constructor() ERC721Creator("Bella Misele", "BM") {}
}
