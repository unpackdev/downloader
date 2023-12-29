
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Continued Appreciation
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    Continued Appreciation                     //
//    Phase 2 of 4                               //
//    Phase 1 : Full Appreciation                //
//    Phase 2 : Continued Appreciation           //
//    Phase 3 : ???                              //
//    Phase 4 : ???                              //
//    This is where things start to get fun.     //
//    Will you burn or HODL                      //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract CA is ERC1155Creator {
    constructor() ERC1155Creator("Continued Appreciation", "CA") {}
}
