
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Weedy Pops World
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//    his collection of 10000 NFTs aims to bring together all those who love weed.    //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract WP420 is ERC721Creator {
    constructor() ERC721Creator("Weedy Pops World", "WP420") {}
}
