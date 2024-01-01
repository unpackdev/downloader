// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OeBakers
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    Bakers bake an open edition.    //
//                                    //
//                                    //
////////////////////////////////////////


contract OEB is ERC1155Creator {
    constructor() ERC1155Creator("OeBakers", "OEB") {}
}
