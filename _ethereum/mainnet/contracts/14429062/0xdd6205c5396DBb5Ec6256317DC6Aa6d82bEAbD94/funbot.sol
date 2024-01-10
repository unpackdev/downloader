
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: funbot
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//      __             _           _       //
//     / _|           | |         | |      //
//    | |_ _   _ _ __ | |__   ___ | |_     //
//    |  _| | | | '_ \| '_ \ / _ \| __|    //
//    | | | |_| | | | | |_) | (_) | |_     //
//    |_|  \__,_|_| |_|_.__/ \___/ \__|    //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract funbot is ERC721Creator {
    constructor() ERC721Creator("funbot", "funbot") {}
}
