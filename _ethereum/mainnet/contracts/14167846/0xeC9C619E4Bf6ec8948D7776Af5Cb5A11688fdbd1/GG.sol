
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gooniez Gang
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Gooniez Gang    //
//                    //
//                    //
////////////////////////


contract GG is ERC721Creator {
    constructor() ERC721Creator("Gooniez Gang", "GG") {}
}
