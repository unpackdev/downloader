// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ムッヂ
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//    8b    d8 88   88 8888b.   dP""b8 888888 .dP"Y8     //
//    88b  d88 88   88  8I  Yb dP   `" 88__   `Ybo."     //
//    88YbdP88 Y8   8P  8I  dY Yb  "88 88""   o.`Y8b     //
//    88 YY 88 `YbodP' 8888Y"   YboodP 888888 8bodP'     //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract MDG is ERC1155Creator {
    constructor() ERC1155Creator(unicode"ムッヂ", "MDG") {}
}
