
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stengel
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//      _____  _                              _     //
//     / ____|| |                            | |    //
//    | (___  | |_   ___  _ __    __ _   ___ | |    //
//     \___ \ | __| / _ \| '_ \  / _` | / _ \| |    //
//     ____) || |_ |  __/| | | || (_| ||  __/| |    //
//    |_____/  \__| \___||_| |_| \__, | \___||_|    //
//                                __/ |             //
//                               |___/              //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract STENGEL is ERC721Creator {
    constructor() ERC721Creator("Stengel", "STENGEL") {}
}
