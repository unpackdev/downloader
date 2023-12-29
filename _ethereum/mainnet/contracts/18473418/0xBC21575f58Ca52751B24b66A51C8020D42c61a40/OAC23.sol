// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Onigiri Artwork Collection 2023
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    Onigiri Artwork Collection 2023 by mangaka7    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract OAC23 is ERC1155Creator {
    constructor() ERC1155Creator("Onigiri Artwork Collection 2023", "OAC23") {}
}
