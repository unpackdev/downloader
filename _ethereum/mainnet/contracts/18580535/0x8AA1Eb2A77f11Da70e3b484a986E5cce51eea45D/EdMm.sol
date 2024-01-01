// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EdgeMemories
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//     _____      _ ___  ___                //
//    |  ___|    | ||  \/  |                //
//    | |__    __| || .  . | _ __ ___       //
//    |  __|  / _` || |\/| || '_ ` _ \      //
//    | |___ | (_| || |  | || | | | | |     //
//    \____/  \__,_|\_|  |_/|_| |_| |_|     //
//                                          //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract EdMm is ERC721Creator {
    constructor() ERC721Creator("EdgeMemories", "EdMm") {}
}
