
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aesthetics of the Immaterial
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//    No ASCII Art here (¬‿¬)                                             //
//                                                                        //
//    Aesthetics of the Immaterial                                        //
//    by David Loh                                                        //
//                                                                        //
//    My obsession in seeking meaning from photographing vague spaces.    //
//    They are immaterial until you find what lies beyond.                //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract AESRIAL is ERC721Creator {
    constructor() ERC721Creator("Aesthetics of the Immaterial", "AESRIAL") {}
}
