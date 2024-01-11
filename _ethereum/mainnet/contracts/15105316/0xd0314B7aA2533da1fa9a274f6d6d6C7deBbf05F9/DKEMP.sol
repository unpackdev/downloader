
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Digital Kinetics
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//     ____ __   __ _____ __  __  _____     //
//    |  _  \ | / /|  ___|  \/  || ___ \    //
//    | | | | |/ / | |__ | .  . || |_/ /    //
//    | | | |    \ |  __|| |\/| ||  __/     //
//    | |/ /| |\  \| |___| |  | || |        //
//    |___/ \_| \_/\____/\_|  |_/\_|        //
//                                          //
//                                          //
//////////////////////////////////////////////


contract DKEMP is ERC721Creator {
    constructor() ERC721Creator("Digital Kinetics", "DKEMP") {}
}
