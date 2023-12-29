// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Fug Pack
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    ░▀█▀░█░█░█▀▀░░░█▀▀░█░█░█▀▀░█░░░▀█▀░█▀▀░█▀▀    //
//    ░░█░░█▀█░█▀▀░░░█▀▀░█░█░█░█░█░░░░█░░█▀▀░▀▀█    //
//    ░░▀░░▀░▀░▀▀▀░░░▀░░░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract FP is ERC1155Creator {
    constructor() ERC1155Creator("The Fug Pack", "FP") {}
}
