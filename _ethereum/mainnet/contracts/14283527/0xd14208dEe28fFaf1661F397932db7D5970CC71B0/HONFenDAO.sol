
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Honorary FenDAO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//      ______ ______ _   _ _____          ____      //
//     |  ____|  ____| \ | |  __ \   /\   / __ \     //
//     | |__  | |__  |  \| | |  | | /  \ | |  | |    //
//     |  __| |  __| | . ` | |  | |/ /\ \| |  | |    //
//     | |    | |____| |\  | |__| / ____ \ |__| |    //
//     |_|    |______|_| \_|_____/_/    \_\____/     //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract HONFenDAO is ERC721Creator {
    constructor() ERC721Creator("Honorary FenDAO", "HONFenDAO") {}
}
