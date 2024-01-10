
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BGS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    __________  ________  _________    //
//    \______   \/  _____/ /   _____/    //
//     |    |  _/   \  ___ \_____  \     //
//     |    |   \    \_\  \/        \    //
//     |______  /\______  /_______  /    //
//            \/        \/        \/     //
//                                       //
//                                       //
///////////////////////////////////////////


contract BGS is ERC721Creator {
    constructor() ERC721Creator("BGS", "BGS") {}
}
