// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 夏の女神 -Natsu no Megami-
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    ﾟﾟ｡･ﾟ｡☆ﾟ　　 ∴+ *    //
//    　　　　　*∴+∴*         //
//    　　+…∵：∵*           //
//    *∵：：+ ∵ +          //
//    +∴ *∵ ：            //
//    ｡…　*               //
//                       //
//                       //
///////////////////////////


contract NNM is ERC721Creator {
    constructor() ERC721Creator(unicode"夏の女神 -Natsu no Megami-", "NNM") {}
}
