
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gift Shop at the Inn
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    STAY WITH US FOREVER    //
//                            //
//                            //
////////////////////////////////


contract GSATI is ERC721Creator {
    constructor() ERC721Creator("Gift Shop at the Inn", "GSATI") {}
}
