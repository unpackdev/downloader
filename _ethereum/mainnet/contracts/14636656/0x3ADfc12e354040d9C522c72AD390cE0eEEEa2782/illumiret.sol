
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: illumiret
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//     _  _  _                    _             _       //
//    (_)| || | _   _  _ __ ___  (_) _ __  ___ | |_     //
//    | || || || | | || '_ ` _ \ | || '__|/ _ \| __|    //
//    | || || || |_| || | | | | || || |  |  __/| |_     //
//    |_||_||_| \__,_||_| |_| |_||_||_|   \___| \__|    //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract illumiret is ERC721Creator {
    constructor() ERC721Creator("illumiret", "illumiret") {}
}
