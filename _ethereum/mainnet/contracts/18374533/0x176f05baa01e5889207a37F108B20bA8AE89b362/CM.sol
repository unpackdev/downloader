// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cartão de Melhoras
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    Cartão de melhoras onchain hahah.     //
//                                          //
//                                          //
//////////////////////////////////////////////


contract CM is ERC721Creator {
    constructor() ERC721Creator(unicode"Cartão de Melhoras", "CM") {}
}
