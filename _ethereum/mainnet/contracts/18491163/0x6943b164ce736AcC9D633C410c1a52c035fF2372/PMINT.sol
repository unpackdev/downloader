// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Papermint
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                          o                 //
//       _   __,    _   _   ,_    _  _  _       _  _  _|_     //
//     |/ \_/  |  |/ \_|/  /  |  / |/ |/ |  |  / |/ |  |      //
//     |__/ \_/|_/|__/ |__/   |_/  |  |  |_/|_/  |  |_/|_/    //
//    /|         /|                                           //
//    \|         \|                                           //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract PMINT is ERC721Creator {
    constructor() ERC721Creator("Papermint", "PMINT") {}
}
