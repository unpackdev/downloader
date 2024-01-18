
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BEAU MONDE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//                                         //
//      ___  ___    _   _   _              //
//     | _ )| __|  /_\ | | | |             //
//     | _ \| _|  / _ \| |_| |             //
//     |___/|___|/_/ \_\\___/              //
//      __  __   ___   _  _  ___   ___     //
//     |  \/  | / _ \ | \| ||   \ | __|    //
//     | |\/| || (_) || .` || |) || _|     //
//     |_|  |_| \___/ |_|\_||___/ |___|    //
//                                         //
//                                         //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract BEAUMONDE is ERC721Creator {
    constructor() ERC721Creator("BEAU MONDE", "BEAUMONDE") {}
}
