
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COMB
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    _  _  _  _  ____    __  __   __       //
//    ( \/ )( \/ )(  __) _(  )(  ) / _\     //
//    / \/ \/ \/ \ ) _) / \) \ )( /    \    //
//    \_)(_/\_)(_/(____)\____/(__)\_/\_/    //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract comb is ERC721Creator {
    constructor() ERC721Creator("COMB", "comb") {}
}
