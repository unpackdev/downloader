
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Door To Nowhere
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    Do not judge anyone who enters a door you would never open.     //
//                                                                    //
//    Santorini - Greece                                              //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract DTN is ERC721Creator {
    constructor() ERC721Creator("Door To Nowhere", "DTN") {}
}
