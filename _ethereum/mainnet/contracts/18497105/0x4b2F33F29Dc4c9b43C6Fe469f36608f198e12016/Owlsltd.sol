// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Owls of Fortune - Limited Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//      _                   _    _                           //
//     / \      |  _    _ _|_   |_ _  ._ _|_     ._   _      //
//     \_/ \/\/ | _>   (_) |    | (_) |   |_ |_| | | (/_     //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract Owlsltd is ERC1155Creator {
    constructor() ERC1155Creator("Owls of Fortune - Limited Editions", "Owlsltd") {}
}
