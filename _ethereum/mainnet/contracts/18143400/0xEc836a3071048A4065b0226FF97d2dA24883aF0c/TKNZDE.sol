// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tokenized PDF Key
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    Dein Schlüssel zur digitalen Version des Buches "Tokenized"     //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract TKNZDE is ERC1155Creator {
    constructor() ERC1155Creator("Tokenized PDF Key", "TKNZDE") {}
}
