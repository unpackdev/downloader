
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: jakeneves
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    Le temps n'existe pas tu verras: c'est un présent perpétuel.    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract JAKE is ERC721Creator {
    constructor() ERC721Creator("jakeneves", "JAKE") {}
}
