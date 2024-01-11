
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Waywaya LandDAO Certificate of Deposit
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    Mint Pool Address                             //
//    0x1C33333cA41bb245d6A712BABe751B11ffBB285d    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract WLCD is ERC721Creator {
    constructor() ERC721Creator("Waywaya LandDAO Certificate of Deposit", "WLCD") {}
}
