
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aquaregia
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                       //
//                                                                                                       //
//          .o.                                                                       o8o                //
//         .888.                                                                      `"'                //
//        .8"888.      .ooooo oo oooo  oooo   .oooo.   oooo d8b  .ooooo.   .oooooooo oooo   .oooo.       //
//       .8' `888.    d88' `888  `888  `888  `P  )88b  `888""8P d88' `88b 888' `88b  `888  `P  )88b      //
//      .88ooo8888.   888   888   888   888   .oP"888   888     888ooo888 888   888   888   .oP"888      //
//     .8'     `888.  888   888   888   888  d8(  888   888     888    .o `88bod8P'   888  d8(  888      //
//    o88o     o8888o `V8bod888   `V88V"V8P' `Y888""8o d888b    `Y8bod8P' `8oooooo.  o888o `Y888""8o     //
//                          888.                                          d"     YD                      //
//                          8P'                                           "Y88888P'                      //
//                          "                                                                            //
//                                                                                                       //
//                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AQR is ERC721Creator {
    constructor() ERC721Creator("Aquaregia", "AQR") {}
}
