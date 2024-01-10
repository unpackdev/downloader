
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Scarecrow
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
//    Isabella is a Seattle-based artist whose work is often created in a stream of consciousness. The images incorporate patterns, shapes that relate to our sensory experience, while paying homage to the poetic sublime of the infinity of the earth.    //
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SAW is ERC721Creator {
    constructor() ERC721Creator("Scarecrow", "SAW") {}
}
