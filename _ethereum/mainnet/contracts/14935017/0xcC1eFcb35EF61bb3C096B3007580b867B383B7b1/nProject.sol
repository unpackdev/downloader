
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The n project #001
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//    The n project es una promesa.                                                                                                         //
//    Cada NFT de este cryptoproyecto artístico forma parte de la evidencia de un sueño.                                                    //
//    Cada poema, cada canción, son las huellas cryptográficas del patrimonio humano cultural vivo más joven de la historia de mi mundo.    //
//                                                                                                                                          //
//    n could be everything & everyone.                                                                                                     //
//    n is you, n is me, n is all of us.                                                                                                    //
//                                                                                                                                          //
//    Create your reality...                                                                                                                //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract nProject is ERC721Creator {
    constructor() ERC721Creator("The n project #001", "nProject") {}
}
