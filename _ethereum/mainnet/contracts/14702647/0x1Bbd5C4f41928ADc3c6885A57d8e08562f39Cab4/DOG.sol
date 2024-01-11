
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DOGTRACT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//                    __         //
//                   /\/'-,      //
//           ,--'''''   /"       //
//     ____,'.  )       \___     //
//    '"""""------'"""`-----'    //
//                               //
//                               //
///////////////////////////////////


contract DOG is ERC721Creator {
    constructor() ERC721Creator("DOGTRACT", "DOG") {}
}
