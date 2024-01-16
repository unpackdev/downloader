
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fin de Siècle
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//     +-+-+-+ +-+-+ +-+-+-+-+-+-+    //
//     |F|I|N| |D|E| |S|I|E|C|L|E|    //
//     +-+-+-+ +-+-+ +-+-+-+-+-+-+    //
//                                    //
//                                    //
////////////////////////////////////////


contract FIN is ERC721Creator {
    constructor() ERC721Creator(unicode"Fin de Siècle", "FIN") {}
}
