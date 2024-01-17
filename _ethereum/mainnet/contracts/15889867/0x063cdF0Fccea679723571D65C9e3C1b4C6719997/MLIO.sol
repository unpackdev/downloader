
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mini Launch IO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//     © Roger Kilimanjaro - Mini Launch IO    //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract MLIO is ERC721Creator {
    constructor() ERC721Creator("Mini Launch IO", "MLIO") {}
}
