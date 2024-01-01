// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VN Test contreact
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////
//          //
//          //
//    :)    //
//          //
//          //
//////////////


contract VNTC is ERC1155Creator {
    constructor() ERC1155Creator("VN Test contreact", "VNTC") {}
}
