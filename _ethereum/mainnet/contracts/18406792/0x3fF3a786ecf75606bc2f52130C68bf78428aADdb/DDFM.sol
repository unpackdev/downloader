// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DDF MECHA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//     ___  ___  ___   __  __ ___ ___ _  _   _        //
//    |   \|   \| __| |  \/  | __/ __| || | /_\       //
//    | |) | |) | _|  | |\/| | _| (__| __ |/ _ \      //
//    |___/|___/|_|   |_|  |_|___\___|_||_/_/ \_\     //
//    =============--------------                     //
//                    -----===============- -----     //
//                                                    //
//    Dope Dead Frog fully on-chain mecha edition.    //
//                                                    //
//    On-chain art through Efficax.                   //
//                                                    //
//    Created by obxium & AI.                         //
//                                                    //
//    2023                                            //
//    obxium                                          //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract DDFM is ERC721Creator {
    constructor() ERC721Creator("DDF MECHA", "DDFM") {}
}
