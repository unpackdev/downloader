
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Everlasting Friends
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//                                                           //
//     ___       ___  __             __  ___         __      //
//    |__  \  / |__  |__) |     /\  /__`  |  | |\ | / _`     //
//    |___  \/  |___ |  \ |___ /~~\ .__/  |  | | \| \__>     //
//                                                           //
//     ___     __           ___             __      __       //
//    |__     |__)    |    |__     |\ |    |  \    /__`      //
//    |       |  \    |    |___    | \|    |__/    .__/      //
//                                                           //
//                                                           //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract SJEF is ERC721Creator {
    constructor() ERC721Creator("Everlasting Friends", "SJEF") {}
}
