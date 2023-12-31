// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Memories of the APP Countdown
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//     _   .-')      ('-.                    //
//    ( '.( OO )_   ( OO ).-.                //
//     ,--.   ,--.) / . --. /   .-----.      //
//     |   `.'   |  | \-.  \   '  .--./      //
//     |         |.-'-'  |  |  |  |('-.      //
//     |  |'.'|  | \| |_.'  | /_) |OO  )     //
//     |  |   |  |  |  .-.  | ||  |`-'|      //
//     |  |   |  |  |  | |  |(_'  '--'\      //
//     `--'   `--'  `--' `--'   `-----'      //
//                                           //
//                                           //
///////////////////////////////////////////////


contract MAC is ERC1155Creator {
    constructor() ERC1155Creator("Memories of the APP Countdown", "MAC") {}
}
