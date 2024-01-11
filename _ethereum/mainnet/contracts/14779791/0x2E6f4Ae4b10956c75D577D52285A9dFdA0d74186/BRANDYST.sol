
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BRANDYST Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    The most exquisite Styrian vintage wines     //
//    gently distilled and matured                 //
//    in Austrian oak barrels to                   //
//    the highest quality brandy.                  //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract BRANDYST is ERC721Creator {
    constructor() ERC721Creator("BRANDYST Collection", "BRANDYST") {}
}
