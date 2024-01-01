// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Retrovision
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//           __                  _           __    //
//          / /___ __   ______  (_)  _____  / /    //
//     __  / / __ `/ | / / __ \/ / |/_/ _ \/ /     //
//    / /_/ / /_/ /| |/ / /_/ / />  </  __/ /      //
//    \____/\__,_/ |___/ .___/_/_/|_|\___/_/       //
//                    /_/                          //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract RVSN is ERC1155Creator {
    constructor() ERC1155Creator("Retrovision", "RVSN") {}
}
