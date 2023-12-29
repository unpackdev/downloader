// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lint
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//     __         __     __   __     ______      //
//    /\ \       /\ \   /\ "-.\ \   /\__  _\     //
//    \ \ \____  \ \ \  \ \ \-.  \  \/_/\ \/     //
//     \ \_____\  \ \_\  \ \_\\"\_\    \ \_\     //
//      \/_____/   \/_/   \/_/ \/_/     \/_/     //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract LINT is ERC721Creator {
    constructor() ERC721Creator("Lint", "LINT") {}
}
