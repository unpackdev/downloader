// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dada Fidget Toy Orchestra
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//    Formado pelos artistas Adriano Motta e Cadu, Dada Fidget* Toy Orchestra (DFTO)    //
//    explora tecnologias de modelagem e animação digital para realização               //
//    de obras de arte.                                                                 //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract DFTO is ERC721Creator {
    constructor() ERC721Creator("Dada Fidget Toy Orchestra", "DFTO") {}
}
