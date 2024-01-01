// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SAK1337 Open Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//      ___|    \    |  /_ |___ /___ /___  | _ \  ____|     //
//    \___ \   _ \   ' /   |  _ \  _ \    / |   | __|       //
//          | ___ \  . \   |   ) |  ) |  /  |   | |         //
//    _____/_/    _\_|\_\ _|____/____/ _/  \___/ _____|     //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract SAKOE is ERC721Creator {
    constructor() ERC721Creator("SAK1337 Open Editions", "SAKOE") {}
}
