
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alohi Writes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//                         //
//     /\  |  _  |_  o     //
//    /--\ | (_) | | |     //
//                         //
//    xoxoxoxoxoxoooo      //
//                         //
//                         //
/////////////////////////////


contract Alohi is ERC721Creator {
    constructor() ERC721Creator("Alohi Writes", "Alohi") {}
}
