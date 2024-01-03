// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Weamboat Stillie
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Weamboat Stillie    //
//                        //
//                        //
////////////////////////////


contract WMBT is ERC721Creator {
    constructor() ERC721Creator("Weamboat Stillie", "WMBT") {}
}
