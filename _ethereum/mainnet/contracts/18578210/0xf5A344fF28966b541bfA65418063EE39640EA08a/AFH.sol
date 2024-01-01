// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art for Humanity
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Art for Humanity    //
//                        //
//                        //
////////////////////////////


contract AFH is ERC721Creator {
    constructor() ERC721Creator("Art for Humanity", "AFH") {}
}
