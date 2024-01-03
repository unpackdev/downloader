// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tigger Public Domain 2024
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    As the clock struck midnight ET on January 1st, 2024, another beloved character from the world of children's literature and animation joined the public domain: Tigger from A.A. Milne's "Winnie the Pooh" series. This event marked a significant turning point, as Tigger, known for his exuberant personality and distinctive stripes, became available for public use without the need for licensing or permission from the original rights holders.    //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TIGGER is ERC1155Creator {
    constructor() ERC1155Creator("Tigger Public Domain 2024", "TIGGER") {}
}
