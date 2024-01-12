
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TRIPPEE ART S1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//     ______  ______   __   ______  ______  ______   ______        //
//    /\__  _\/\  == \ /\ \ /\  == \/\  == \/\  ___\ /\  ___\       //
//    \/_/\ \/\ \  __< \ \ \\ \  _-/\ \  _-/\ \  __\ \ \  __\       //
//       \ \_\ \ \_\ \_\\ \_\\ \_\   \ \_\   \ \_____\\ \_____\     //
//        \/_/  \/_/ /_/ \/_/ \/_/    \/_/    \/_____/ \/_____/     //
//                                                                  //
//              The first collection of Trippee Art.                //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract TRIPPEE1 is ERC721Creator {
    constructor() ERC721Creator("TRIPPEE ART S1", "TRIPPEE1") {}
}
