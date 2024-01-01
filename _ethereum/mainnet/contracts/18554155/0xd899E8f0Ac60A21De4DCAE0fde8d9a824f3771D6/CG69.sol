// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: granneberg on-chain
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//                                   _                      //
//     ___  ___  ___  ___  ___  ___ | |_  ___  ___  ___     //
//    | . ||  _|| .'||   ||   || -_|| . || -_||  _|| . |    //
//    |_  ||_|  |__,||_|_||_|_||___||___||___||_|  |_  |    //
//    |___|                                        |___|    //
//                                                          //
//                         on-chain                         //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract CG69 is ERC721Creator {
    constructor() ERC721Creator("granneberg on-chain", "CG69") {}
}
