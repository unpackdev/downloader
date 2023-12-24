// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Goldchainz Collective
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//    .------..------..------.           //
//    |T.--. ||G.--. ||C.--. |.-.        //
//    | :/\: || :/\: || :/\: ((5))       //
//    | (__) || :\/: || :\/: |'-.-.      //
//    | '--'T|| '--'G|| '--'C| ((1))     //
//    `------'`------'`------'  '-'      //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract TGC is ERC721Creator {
    constructor() ERC721Creator("The Goldchainz Collective", "TGC") {}
}
