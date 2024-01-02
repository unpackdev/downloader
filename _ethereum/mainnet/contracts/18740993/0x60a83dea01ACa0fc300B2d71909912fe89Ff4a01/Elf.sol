// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Elf
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//              .-  .     .-.     //
//      .---;`-'   /     / -'     //
//     (   (_)    /    -/--       //
//      )--      /     /          //
//     (      /_/_.-`.'           //
//     `\___.'                    //
//                                //
//                                //
//    Creator ChepaDenis          //
//                                //
//                                //
////////////////////////////////////


contract Elf is ERC721Creator {
    constructor() ERC721Creator("Elf", "Elf") {}
}
