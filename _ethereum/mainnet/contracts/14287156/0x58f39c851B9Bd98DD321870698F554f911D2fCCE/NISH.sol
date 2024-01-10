
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NOUNISH
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//     .____     ________  ___ ________________.            //
//        |    |   /  _____/ /   |   \__    ___/            //
//        |    |  /   \  ___/    ~    \|    |  \            //
//        |    |__\    \_\  \    Y    /|    |               //
//        |_______ \______  /\___|_  / |____|               //
//                \/      \/       \/                       //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract NISH is ERC721Creator {
    constructor() ERC721Creator("NOUNISH", "NISH") {}
}
