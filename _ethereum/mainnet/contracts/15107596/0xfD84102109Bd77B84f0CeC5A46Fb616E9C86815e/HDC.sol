
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hidden Codes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//    88  88 88 8888b.  8888b.  888888 88b 88      dP""b8  dP"Yb  8888b.  888888 .dP"Y8     //
//    88  88 88  8I  Yb  8I  Yb 88__   88Yb88     dP   `" dP   Yb  8I  Yb 88__   `Ybo."     //
//    888888 88  8I  dY  8I  dY 88""   88 Y88     Yb      Yb   dP  8I  dY 88""   o.`Y8b     //
//    88  88 88 8888Y"  8888Y"  888888 88  Y8      YboodP  YbodP  8888Y"  888888 8bodP'     //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract HDC is ERC721Creator {
    constructor() ERC721Creator("Hidden Codes", "HDC") {}
}
