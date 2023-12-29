// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Movement
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    ~/_ ~/_ /\ ]3 [- (_, | |\| [- ~|~ |-|     //
//                                              //
//    |\/| \/ |\/| |\| ~|~                      //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract mvmnt is ERC721Creator {
    constructor() ERC721Creator("Movement", "mvmnt") {}
}
