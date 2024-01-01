// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Theatre of Absurd
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    conte_digital    //
//                     //
//                     //
/////////////////////////


contract TOA is ERC721Creator {
    constructor() ERC721Creator("Theatre of Absurd", "TOA") {}
}
