
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Re(kt)Memes
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Rektmemes by pepegm    //
//                           //
//                           //
///////////////////////////////


contract RKME is ERC1155Creator {
    constructor() ERC1155Creator("Re(kt)Memes", "RKME") {}
}
