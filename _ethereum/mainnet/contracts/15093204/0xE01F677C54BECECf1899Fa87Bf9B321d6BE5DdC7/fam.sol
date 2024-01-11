
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: famer
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//    ____ __ ____ _ _ __ ____ ____                //
//    ( __)/ _\ ( _ \( \/ ) / _\ ( __)( _ \        //
//     ) _)/ \ ) // \/ \/ \ ) _) ) /               //
//    (__) \_/\_/(__\_)\_)(_/\_/\_/(____)(__\_)    //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract fam is ERC721Creator {
    constructor() ERC721Creator("famer", "fam") {}
}
