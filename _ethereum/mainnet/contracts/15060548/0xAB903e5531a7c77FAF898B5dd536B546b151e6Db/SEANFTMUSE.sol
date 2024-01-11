
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Algorithm to Output
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//    In this workshop, you'll take a look at different ways that tweaking your algorithm can produce varying outputs.    //
//                                                                                                                        //
//    You'll start with the code for yungwknd's piece "flashing lights" and see how seemingly simple, 1 line changes,     //
//    can make brand new pieces. The workshop will highlight the need for experimentation in generative art. Often,       //
//    the best results are made from accidental typos in the code. The beauty of generative art is that it is not         //
//    always precise and methodical.                                                                                      //
//                                                                                                                        //
//    Contract for live minting 😎                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SEANFTMUSE is ERC721Creator {
    constructor() ERC721Creator("Algorithm to Output", "SEANFTMUSE") {}
}
