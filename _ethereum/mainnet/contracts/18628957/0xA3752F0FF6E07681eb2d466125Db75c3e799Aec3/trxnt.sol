// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: trxnt1of1s
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    +-++-++-++-++-+ +-++-++-++-++-+    //
//    |t||r||x||n||t|.|1||o||f||1||s|    //
//    +-++-++-++-++-+ +-++-++-++-++-+    //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract trxnt is ERC721Creator {
    constructor() ERC721Creator("trxnt1of1s", "trxnt") {}
}
