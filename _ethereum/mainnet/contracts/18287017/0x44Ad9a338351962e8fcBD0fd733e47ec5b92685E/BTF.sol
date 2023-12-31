// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Butterfly
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//    A metallic blue and pastel pink abstract figure of a butterfly, "Happiness is a butterfly" gets its name from a Lana Del Rey song.    //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BTF is ERC721Creator {
    constructor() ERC721Creator("Butterfly", "BTF") {}
}
