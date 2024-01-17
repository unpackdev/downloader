
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Absolute Minimum
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//                                                                     //
//      /\  |_   _  _  |    _|_  _    |\/| o ._  o ._ _      ._ _      //
//     /--\ |_) _> (_) | |_| |_ (/_   |  | | | | | | | | |_| | | |     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract AM is ERC721Creator {
    constructor() ERC721Creator("Absolute Minimum", "AM") {}
}
