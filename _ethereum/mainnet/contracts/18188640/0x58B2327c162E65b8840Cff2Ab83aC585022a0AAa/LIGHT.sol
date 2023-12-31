// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Light in the Darkness
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    .____    .___  ________  ___ ______________    //
//    |    |   |   |/  _____/ /   |   \__    ___/    //
//    |    |   |   /   \  ___/    ~    \|    |       //
//    |    |___|   \    \_\  \    Y    /|    |       //
//    |_______ \___|\______  /\___|_  / |____|       //
//            \/           \/       \/               //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract LIGHT is ERC1155Creator {
    constructor() ERC1155Creator("Light in the Darkness", "LIGHT") {}
}
