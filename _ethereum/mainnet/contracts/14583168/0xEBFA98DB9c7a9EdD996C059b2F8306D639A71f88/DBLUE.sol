
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Delft Blue
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//    oooooooooo.             oooo   .o88o.     .        oooooooooo.  oooo                            //
//    `888'   `Y8b            `888   888 `"   .o8        `888'   `Y8b `888                            //
//     888      888  .ooooo.   888  o888oo  .o888oo       888     888  888  oooo  oooo   .ooooo.      //
//     888      888 d88' `88b  888   888      888         888oooo888'  888  `888  `888  d88' `88b     //
//     888      888 888ooo888  888   888      888         888    `88b  888   888   888  888ooo888     //
//     888     d88' 888    .o  888   888      888 .       888    .88P  888   888   888  888    .o     //
//    o888bood8P'   `Y8bod8P' o888o o888o     "888"      o888bood8P'  o888o  `V88V"V8P' `Y8bod8P'     //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DBLUE is ERC721Creator {
    constructor() ERC721Creator("Delft Blue", "DBLUE") {}
}
