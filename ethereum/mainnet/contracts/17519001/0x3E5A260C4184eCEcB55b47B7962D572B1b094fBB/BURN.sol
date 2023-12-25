// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BurningSouls
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//                                                                        //
//    ______                  _               _____             _         //
//    | ___ \                (_)             /  ___|           | |        //
//    | |_/ /_   _ _ __ _ __  _ _ __   __ _  \ `--.  ___  _   _| |___     //
//    | ___ \ | | | '__| '_ \| | '_ \ / _` |  `--. \/ _ \| | | | / __|    //
//    | |_/ / |_| | |  | | | | | | | | (_| | /\__/ / (_) | |_| | \__ \    //
//    \____/ \__,_|_|  |_| |_|_|_| |_|\__, | \____/ \___/ \__,_|_|___/    //
//                                     __/ |                              //
//                                    |___/                               //
//                                                                        //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract BURN is ERC721Creator {
    constructor() ERC721Creator("BurningSouls", "BURN") {}
}
