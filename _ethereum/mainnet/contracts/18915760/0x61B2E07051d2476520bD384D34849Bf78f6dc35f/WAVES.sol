// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Waves
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//          _                                                 //
//         |_) o  _. ._   _  _.   \  / o  _ _|_  _. |         //
//         |_) | (_| | | (_ (_|    \/  | (_  |_ (_| |         //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract WAVES is ERC721Creator {
    constructor() ERC721Creator("Waves", "WAVES") {}
}
