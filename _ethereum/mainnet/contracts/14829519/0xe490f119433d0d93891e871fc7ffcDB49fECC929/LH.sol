
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Liladam Houses
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//        \│/\│/\│/\│/        //
//        ─ ── ── ── ─        //
//    ────/│\/│\/│\/│\────    //
//    ╦  ╦╦  ╔═╗╔╦╗╔═╗╔╦╗     //
//    ║  ║║  ╠═╣ ║║╠═╣║║║     //
//    ╩═╝╩╩═╝╩ ╩═╩╝╩ ╩╩ ╩     //
//    ╦ ╦╔═╗╦ ╦╔═╗╔═╗╔═╗      //
//    ╠═╣║ ║║ ║╚═╗║╣ ╚═╗      //
//    ╩ ╩╚═╝╚═╝╚═╝╚═╝╚═╝      //
//                            //
//                            //
//    ooooooooooooooooooo     //
//                            //
//                            //
//                            //
////////////////////////////////


contract LH is ERC721Creator {
    constructor() ERC721Creator("Liladam Houses", "LH") {}
}
