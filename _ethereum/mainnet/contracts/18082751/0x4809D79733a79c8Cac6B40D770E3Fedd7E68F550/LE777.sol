// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Limited 7's Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//    Maloriginals 'Limited 7's Editions'                                              //
//                                                                                     //
//    This contract was created for Limited Editions that cost a few dollars.          //
//                                                                                     //
//    All proceeds go towards advancing my skillset as a photographer.                 //
//                                                                                     //
//    The other OE or Open Edition contract, "Spread the Love" will always be free.    //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract LE777 is ERC1155Creator {
    constructor() ERC1155Creator("Limited 7's Editions", "LE777") {}
}
