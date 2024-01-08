
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kyt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//                                                                           //
//                                                                           //
//    kkkkkkkk                                             tttt              //
//    k::::::k                                          ttt:::t              //
//    k::::::k                                          t:::::t              //
//    k::::::k                                          t:::::t              //
//     k:::::k    kkkkkkkyyyyyyy           yyyyyyyttttttt:::::ttttttt        //
//     k:::::k   k:::::k  y:::::y         y:::::y t:::::::::::::::::t        //
//     k:::::k  k:::::k    y:::::y       y:::::y  t:::::::::::::::::t        //
//     k:::::k k:::::k      y:::::y     y:::::y   tttttt:::::::tttttt        //
//     k::::::k:::::k        y:::::y   y:::::y          t:::::t              //
//     k:::::::::::k          y:::::y y:::::y           t:::::t              //
//     k:::::::::::k           y:::::y:::::y            t:::::t              //
//     k::::::k:::::k           y:::::::::y             t:::::t    tttttt    //
//    k::::::k k:::::k           y:::::::y              t::::::tttt:::::t    //
//    k::::::k  k:::::k           y:::::y               tt::::::::::::::t    //
//    k::::::k   k:::::k         y:::::y                  tt:::::::::::tt    //
//    kkkkkkkk    kkkkkkk       y:::::y                     ttttttttttt      //
//                             y:::::y                                       //
//                            y:::::y                                        //
//                           y:::::y                                         //
//                          y:::::y                                          //
//                         yyyyyyy                                           //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract KYT is ERC721Creator {
    constructor() ERC721Creator("kyt", "KYT") {}
}
