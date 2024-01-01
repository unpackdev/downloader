// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Harvest
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Yinkore Contract    //
//                        //
//                        //
////////////////////////////


contract YINH is ERC721Creator {
    constructor() ERC721Creator("The Harvest", "YINH") {}
}
