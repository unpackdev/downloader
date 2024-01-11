
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OneETHGame
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//      1111111   EEEEEEEEEEEEEEEEEEEEEE       GGGGGGGGGGGGG    //
//     1::::::1   E::::::::::::::::::::E    GGG::::::::::::G    //
//    1:::::::1   E::::::::::::::::::::E  GG:::::::::::::::G    //
//    111:::::1   EE::::::EEEEEEEEE::::E G:::::GGGGGGGG::::G    //
//       1::::1     E:::::E       EEEEEEG:::::G       GGGGGG    //
//       1::::1     E:::::E            G:::::G                  //
//       1::::1     E::::::EEEEEEEEEE  G:::::G                  //
//       1::::l     E:::::::::::::::E  G:::::G    GGGGGGGGGG    //
//       1::::l     E:::::::::::::::E  G:::::G    G::::::::G    //
//       1::::l     E::::::EEEEEEEEEE  G:::::G    GGGGG::::G    //
//       1::::l     E:::::E            G:::::G        G::::G    //
//       1::::l     E:::::E       EEEEEEG:::::G       G::::G    //
//    111::::::111EE::::::EEEEEEEE:::::E G:::::GGGGGGGG::::G    //
//    1::::::::::1E::::::::::::::::::::E  GG:::::::::::::::G    //
//    1::::::::::1E::::::::::::::::::::E    GGG::::::GGG:::G    //
//    111111111111EEEEEEEEEEEEEEEEEEEEEE       GGGGGG   GGGG    //
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


contract OEG is ERC721Creator {
    constructor() ERC721Creator("OneETHGame", "OEG") {}
}
