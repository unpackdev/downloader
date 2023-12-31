// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: In The Wake Of Madness
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//      ___         _____ _           __        __    _           ___   __   __  __           _                         //
//     |_ _|_ __   |_   _| |__   ___  \ \      / /_ _| | _____   / _ \ / _| |  \/  | __ _  __| |_ __   ___  ___ ___     //
//      | || '_ \    | | | '_ \ / _ \  \ \ /\ / / _` | |/ / _ \ | | | | |_  | |\/| |/ _` |/ _` | '_ \ / _ \/ __/ __|    //
//      | || | | |   | | | | | |  __/   \ V  V / (_| |   <  __/ | |_| |  _| | |  | | (_| | (_| | | | |  __/\__ \__ \    //
//     |___|_| |_|   |_| |_| |_|\___|    \_/\_/ \__,_|_|\_\___|  \___/|_|   |_|  |_|\__,_|\__,_|_| |_|\___||___/___/    //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WOM is ERC721Creator {
    constructor() ERC721Creator("In The Wake Of Madness", "WOM") {}
}
