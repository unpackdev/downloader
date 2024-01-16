
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: painting
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//    Oil painting, refers to a painting made with pigments formulated with dry oil    //
//                                                                                     //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract PT is ERC721Creator {
    constructor() ERC721Creator("painting", "PT") {}
}
