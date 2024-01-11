
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: When Will We Make It
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//    ██     ██ ██     ██ ██     ██ ███    ███ ██     //
//    ██     ██ ██     ██ ██     ██ ████  ████ ██     //
//    ██  █  ██ ██  █  ██ ██  █  ██ ██ ████ ██ ██     //
//    ██ ███ ██ ██ ███ ██ ██ ███ ██ ██  ██  ██ ██     //
//     ███ ███   ███ ███   ███ ███  ██      ██ ██     //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract WWWMI is ERC721Creator {
    constructor() ERC721Creator("When Will We Make It", "WWWMI") {}
}
