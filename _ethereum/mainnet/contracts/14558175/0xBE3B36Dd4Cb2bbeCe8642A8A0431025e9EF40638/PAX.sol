
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PaxRomanArt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    \______   \_____  ___  ___    //
//     |     ___/\__  \ \  \/  /    //
//     |    |     / __ \_>    <     //
//     |____|    (____  /__/\_ \    //
//                    \/      \/    //
//                                  //
//                                  //
//////////////////////////////////////


contract PAX is ERC721Creator {
    constructor() ERC721Creator("PaxRomanArt", "PAX") {}
}
