// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ode to the Masters
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//                 ___         ___  ___   ___                  //
//      .'|=|`.    `._|=|`.   `._|=|   |=|_.'   .'|\/|`.       //
//    .'  | |  `.       |  `.      |   |      .'  |  |  `.     //
//    |   | |   |   .'|=|___|      |   |      |   |  |   |     //
//    `.  | |  .' .'  |  ___       `.  |      |   |  |   |     //
//      `.|=|.'   |___|=|_.'         `.|      |___|  |___|     //
//                                                             //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract O2TM is ERC721Creator {
    constructor() ERC721Creator("Ode to the Masters", "O2TM") {}
}
