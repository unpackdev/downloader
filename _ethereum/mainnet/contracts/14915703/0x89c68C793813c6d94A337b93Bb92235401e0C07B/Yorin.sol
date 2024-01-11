
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yorin
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//     __     __        _           //
//     \ \   / /       (_)          //
//      \ \_/ /__  _ __ _ _ __      //
//       \   / _ \| '__| | '_ \     //
//        | | (_) | |  | | | | |    //
//        |_|\___/|_|  |_|_| |_|    //
//                                  //
//                                  //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract Yorin is ERC721Creator {
    constructor() ERC721Creator("Yorin", "Yorin") {}
}
