
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Champions of Light
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//    |                                                 |\                     //
//    |                                                 | \                    //
//    |                                  _           _  |  \                   //
//    |\   | | |\ |\/| |\/ | /\  |  /   |_| /\ |//  |_| |    | \ / | | /|\     //
//    | \  |\| |\ |/\| |   | \/ `|  --      \/ |/       |    |  X  |\|  |      //
//    |  \ | | |  |  | |/\ | /\  |`  /      /\ |        |    | / \ | |  |      //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract CHMPNLGHT is ERC721Creator {
    constructor() ERC721Creator("Champions of Light", "CHMPNLGHT") {}
}
