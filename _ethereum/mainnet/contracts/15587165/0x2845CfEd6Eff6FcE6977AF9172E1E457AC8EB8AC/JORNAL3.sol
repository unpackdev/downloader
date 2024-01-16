
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Podcast Jornalista 3.0
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//                               Podcast Jornalista 3.0                                      //
//                                                                                           //
//    Trabalho de Conclusão de Curso de Jornalismo - Universidade Prebisteriana Mackenzie    //
//                                                                                           //
//                    Leonardo Rubinstein Cavalcanti - TIA 31932002                          //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract JORNAL3 is ERC721Creator {
    constructor() ERC721Creator("Podcast Jornalista 3.0", "JORNAL3") {}
}
