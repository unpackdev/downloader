
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Charms by Jasper A. York
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    50 charms by jasper a york    //
//                                  //
//                                  //
//////////////////////////////////////


contract Charms is ERC721Creator {
    constructor() ERC721Creator("Charms by Jasper A. York", "Charms") {}
}
