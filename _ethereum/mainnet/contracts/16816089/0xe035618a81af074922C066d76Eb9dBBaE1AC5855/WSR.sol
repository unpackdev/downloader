// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wizardsmol Requests
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    //////////////////////////////    //
//    //                          //    //
//    //                          //    //
//    //          /\              //    //
//    //         / *\             //    //
//    //        / *  \            //    //
//    //      ----------          //    //
//    //       | 0   0|           //    //
//    //       |______| - Smol    //    //
//    //                          //    //
//    //                          //    //
//    //////////////////////////////    //
//                                      //
//                                      //
//////////////////////////////////////////


contract WSR is ERC721Creator {
    constructor() ERC721Creator("Wizardsmol Requests", "WSR") {}
}
