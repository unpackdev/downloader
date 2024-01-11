
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: grxm
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//      _____ _____  __   ____  __     //
//     / ____|  __ \ \ \ / /  \/  |    //
//    | |  __| |__) | \ V /| \  / |    //
//    | | |_ |  _  /   > < | |\/| |    //
//    | |__| | | \ \  / . \| |  | |    //
//     \_____|_|  \_\/_/ \_\_|  |_|    //
//                                     //
//                                     //
/////////////////////////////////////////


contract grxm is ERC721Creator {
    constructor() ERC721Creator("grxm", "grxm") {}
}
