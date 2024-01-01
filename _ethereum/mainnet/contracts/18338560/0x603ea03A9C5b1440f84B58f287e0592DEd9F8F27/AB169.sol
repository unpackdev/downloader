// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CHAZAK/STRONG
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//     █████  ██████  ███████  █████                                                         //
//    ██   ██ ██   ██ ██      ██   ██                                                        //
//    ███████ ██████  █████   ███████                                                        //
//    ██   ██ ██   ██ ██      ██   ██                                                        //
//    ██   ██ ██████  ██      ██   ██                                                        //
//                                                                                           //
//    // This is a contract for the sale of a photograph/digital                             //
//    representation taken of an original painting created by Annette Back.                  //
//    The painting is titled "Chazak", which means "Strong" in hebrew.                       //
//    This painting was finished a week before the massacre in Israel                        //
//    on October 7, 2023. Proceeds of this sale will go to an                                //
//    organization that takes care of the victims and their families.                        //
//                                                                                           //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract AB169 is ERC1155Creator {
    constructor() ERC1155Creator("CHAZAK/STRONG", "AB169") {}
}
