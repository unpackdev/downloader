
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Everyday Strange
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    A Solemn Stranger Production    //
//                                    //
//                                    //
////////////////////////////////////////


contract EDS is ERC721Creator {
    constructor() ERC721Creator("Everyday Strange", "EDS") {}
}
