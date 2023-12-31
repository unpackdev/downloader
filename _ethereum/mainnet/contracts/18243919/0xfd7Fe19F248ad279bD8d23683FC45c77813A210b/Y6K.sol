// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Y6K Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//     EEEE   TTTTTTT  H   H      Y   Y   666    K  K    //
//     E         T     H   H      Y   Y  6       K K     //
//     EEEE      T     HHHHH       YYY   6666    KK      //
//     E         T     H   H        Y    6   6   K K     //
//     EEEE      T     H   H        Y    6666    K  K    //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract Y6K is ERC1155Creator {
    constructor() ERC1155Creator("Y6K Editions", "Y6K") {}
}
