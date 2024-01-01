// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Trick or Treat
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//    Halloween season is here and you can now mint an edition this spooky season. Wishing you a spooky minting day.    //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TORT is ERC721Creator {
    constructor() ERC721Creator("Trick or Treat", "TORT") {}
}
