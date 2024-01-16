
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: sketch
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//    Sketching is a visual art and plastic art that uses drawing tools to express it on two-dimensional materials. Its purpose is to create three-dimensional three-dimensional shapes on two-dimensional drawing paper. Tools used include pencil, graphite, crayon, ink, charcoal, chalk, marker, eraser, etc., as well as electronic drawing. The most common carrier for sketching is paper, other materials such as cardboard, plastic, leather, wood, canvas, etc. can be used    //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SC is ERC721Creator {
    constructor() ERC721Creator("sketch", "SC") {}
}
