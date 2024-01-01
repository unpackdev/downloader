// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dark Knight
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//        d8b                     d8b                           //
//          88P                     ?88                         //
//         d88                       88b                        //
//     d888888   d888b8b    88bd88b  888  d88'                  //
//    d8P' ?88  d8P' ?88    88P'  `  888bd8P'                   //
//    88b  ,88b 88b  ,88b  d88      d88888b                     //
//    `?88P'`88b`?88P'`88bd88'     d88' `?88b,                  //
//                                                              //
//                                                              //
//                                                              //
//     d8b                   d8,           d8b                  //
//     ?88                  `8P            ?88         d8P      //
//      88b                                 88b     d888888P    //
//      888  d88'  88bd88b   88b d888b8b    888888b   ?88'      //
//      888bd8P'   88P' ?8b  88Pd8P' ?88    88P `?8b  88P       //
//     d88888b    d88   88P d88 88b  ,88b  d88   88P  88b       //
//    d88' `?88b,d88'   88bd88' `?88P'`88bd88'   88b  `?8b      //
//                                     )88                      //
//                                    ,88P                      //
//                                `?8888P                       //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract DK is ERC1155Creator {
    constructor() ERC1155Creator("Dark Knight", "DK") {}
}
