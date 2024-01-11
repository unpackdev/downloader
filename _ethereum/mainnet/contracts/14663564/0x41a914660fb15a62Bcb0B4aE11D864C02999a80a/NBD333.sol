
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 333 Fractions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//     ___  ___  ___     //
//    (__ )(__ )(__ )    //
//     (_ \ (_ \ (_ \    //
//    (___/(___/(___/    //
//                       //
//                       //
///////////////////////////


contract NBD333 is ERC721Creator {
    constructor() ERC721Creator("333 Fractions", "NBD333") {}
}
