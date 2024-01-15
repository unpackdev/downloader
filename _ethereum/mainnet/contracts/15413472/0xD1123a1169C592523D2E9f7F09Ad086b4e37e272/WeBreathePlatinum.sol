
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: We Breathe | Platinum Prints
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//       _   _     _   _   _   _   _   _   _                          //
//      / \ / \   / \ / \ / \ / \ / \ / \ / \                         //
//     ( w | e ) ( b | r | e | a | t | h | e )                        //
//      \_/ \_/   \_/ \_/ \_/ \_/ \_/ \_/ \_/                         //
//       _   _   _   _   _   _   _   _     _   _   _   _   _   _      //
//      / \ / \ / \ / \ / \ / \ / \ / \   / \ / \ / \ / \ / \ / \     //
//     ( p | l | a | t | i | n | u | m ) ( p | r | i | n | t | s )    //
//      \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/   \_/ \_/ \_/ \_/ \_/ \_/     //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract WeBreathePlatinum is ERC721Creator {
    constructor() ERC721Creator("We Breathe | Platinum Prints", "WeBreathePlatinum") {}
}
