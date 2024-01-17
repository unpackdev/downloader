
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: and other stories
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    ┌┐ ┬ ┬  ┌─┐┬ ┬┌─┐┌─┐┌┐ ┌─┐┬┌─┌─┐    //
//    ├┴┐└┬┘  ├─┘│ │├─┘└─┐├┴┐├┤ ├┴┐├─┤    //
//    └─┘ ┴   ┴  └─┘┴  └─┘└─┘└─┘┴ ┴┴ ┴    //
//                                        //
//                                        //
////////////////////////////////////////////


contract PUPS is ERC721Creator {
    constructor() ERC721Creator("and other stories", "PUPS") {}
}
