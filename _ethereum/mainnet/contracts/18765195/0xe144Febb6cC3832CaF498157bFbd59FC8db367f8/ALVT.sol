// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ALVT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//    O ALAGOA VILLA TOSCANA 001A, símbolo/ticker “ALVT”, é uma coleção NFT com propriedade mediada através de contrato inteligente, registrado na rede blockchain da plataforma Ethereum.     //
//    As transferências de propriedade deste NFT só terão valor efetivo, quando igualmente registradas na rede Blockchain da plataforma Ethereum.                                              //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ALVT is ERC721Creator {
    constructor() ERC721Creator("ALVT", "ALVT") {}
}
