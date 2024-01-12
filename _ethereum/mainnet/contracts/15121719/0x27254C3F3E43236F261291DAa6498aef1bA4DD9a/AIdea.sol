
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Abstract Ideartist
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//                                                                  //
//    88 8888b.  888888    db    88""Yb 888888 88 .dP"Y8 888888     //
//    88  8I  Yb 88__     dPYb   88__dP   88   88 `Ybo."   88       //
//    88  8I  dY 88""    dP__Yb  88"Yb    88   88 o.`Y8b   88       //
//    88 8888Y"  888888 dP""""Yb 88  Yb   88   88 8bodP'   88       //
//                                                                  //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract AIdea is ERC721Creator {
    constructor() ERC721Creator("Abstract Ideartist", "AIdea") {}
}
