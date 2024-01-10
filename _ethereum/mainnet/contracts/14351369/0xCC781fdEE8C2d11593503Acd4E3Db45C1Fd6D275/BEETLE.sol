
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Volpe's Crypto Beetles
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    _--=._              /|_/|          //
//      `-.}   `=._-.-=-._.'  @ @._,     //
//         `._ _--.   )      _,.-'       //
//            `    Gm-"""^Gm'            //
//                    .                  //
//    ..-.     .-.    /                  //
//       )   /.-._. /  .-.   .-.         //
//      /   /(   ) /   /  )./.-'_        //
//     (  .'  `-'_/_.-/`-' (__.'         //
//      \/           /                   //
//                                       //
//                                       //
///////////////////////////////////////////


contract BEETLE is ERC721Creator {
    constructor() ERC721Creator("Volpe's Crypto Beetles", "BEETLE") {}
}
