
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xECDSA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//      _      _  _  _   __          //
//     / \    |_ /  | \ (_   /\      //
//     \_/ >< |_ \_ |_/ __) /--\     //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract ECDSA is ERC721Creator {
    constructor() ERC721Creator("0xECDSA", "ECDSA") {}
}
