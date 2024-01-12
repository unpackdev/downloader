
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jerry's first time
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//                                             _                              _      //
//     o  _   _|_ |_  o  _       _      ._   _|_ o ._ _ _|_   _|_ o ._ _   _   )     //
//     | _>    |_ | | | _>   \/ (_) |_| |     |  | | _>  |_    |_ | | | | (/_ o      //
//                           /                                                       //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract Jft is ERC721Creator {
    constructor() ERC721Creator("Jerry's first time", "Jft") {}
}
