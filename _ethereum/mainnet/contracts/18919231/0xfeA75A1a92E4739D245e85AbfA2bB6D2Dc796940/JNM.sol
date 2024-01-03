// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jeron1moments
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                              _                //
//       |                     /|                //
//       | ___  ___  ___  ___ ( |   _ _  ___     //
//       )|___)|   )|   )|   )  | )| | )|   )    //
//     _/ |__  |    |__/ |  /  _|/ |  / |__/     //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract JNM is ERC1155Creator {
    constructor() ERC1155Creator("Jeron1moments", "JNM") {}
}
