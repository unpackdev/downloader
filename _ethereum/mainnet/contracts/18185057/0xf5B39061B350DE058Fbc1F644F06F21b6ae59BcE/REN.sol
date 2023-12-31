// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: REN
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                       _ |\_      //
//                       \` ..\     //
//                  __,.-" =__Y=    //
//                ."        )       //
//          _    /   ,    \/\_      //
//         ((____|    )_-\ \_-`     //
//          `-----'`-----` `--`     //
//                                  //
//                                  //
//////////////////////////////////////


contract REN is ERC721Creator {
    constructor() ERC721Creator("REN", "REN") {}
}
