
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Red Moon Masquerade
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//                                                               //
//       Welcome back my friends, to the show that never ends    //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract RMM is ERC721Creator {
    constructor() ERC721Creator("The Red Moon Masquerade", "RMM") {}
}
