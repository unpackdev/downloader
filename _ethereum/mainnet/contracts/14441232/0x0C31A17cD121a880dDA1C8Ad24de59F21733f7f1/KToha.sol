
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kopitoha Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    Kopitoha    //
//                //
//                //
////////////////////


contract KToha is ERC721Creator {
    constructor() ERC721Creator("Kopitoha Collection", "KToha") {}
}
