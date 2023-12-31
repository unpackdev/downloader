// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PHOTON
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//                                                              //
//     ______   _     _   _____   _______   _____   ______      //
//    (_____ \ | |   | | / ___ \ (_______) / ___ \ |  ___ \     //
//     _____) )| |__ | || |   | | _       | |   | || |   | |    //
//    |  ____/ |  __)| || |   | || |      | |   | || |   | |    //
//    | |      | |   | || |___| || |_____ | |___| || |   | |    //
//    |_|      |_|   |_| \_____/  \______) \_____/ |_|   |_|    //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract PHOTON is ERC1155Creator {
    constructor() ERC1155Creator("PHOTON", "PHOTON") {}
}
