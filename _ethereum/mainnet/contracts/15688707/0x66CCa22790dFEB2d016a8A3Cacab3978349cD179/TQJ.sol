
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Journeys
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//         |                                            //
//         |  _ \  |   |  __| __ \   _ \ |   |  __|     //
//     \   | (   | |   | |    |   |  __/ |   |\__ \     //
//    \___/ \___/ \__,_|_|   _|  _|\___|\__, |____/     //
//                                      ____/           //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract TQJ is ERC721Creator {
    constructor() ERC721Creator("Journeys", "TQJ") {}
}
