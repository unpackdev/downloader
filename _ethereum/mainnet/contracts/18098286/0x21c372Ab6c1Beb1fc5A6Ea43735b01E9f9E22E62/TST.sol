// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bored Ape Lugano x TST
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////
//              //
//              //
//    /~\       //
//     C oo     //
//     _( ^)    //
//    /   ~\    //
//              //
//              //
//////////////////


contract TST is ERC1155Creator {
    constructor() ERC1155Creator("Bored Ape Lugano x TST", "TST") {}
}
