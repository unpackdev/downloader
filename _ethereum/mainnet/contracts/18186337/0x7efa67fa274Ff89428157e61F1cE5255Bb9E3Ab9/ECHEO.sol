// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Echeo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//         _  ___  __   _  _  __  __        //
//        | )  _)  _) |_ (_ (_  )(__        //
//        |   /__ /__|__)|  __)  __)        //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract ECHEO is ERC721Creator {
    constructor() ERC721Creator("Echeo", "ECHEO") {}
}
