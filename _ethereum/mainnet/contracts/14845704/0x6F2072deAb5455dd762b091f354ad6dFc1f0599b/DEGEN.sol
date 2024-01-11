
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DEGEN Card
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//          ."`".          //
//      .-./ _=_ \.-.      //
//     {  (,(oYo),) }}     //
//     {{ |   "   |} }     //
//     { { \(---)/  }}     //
//     {{  }'-=-'{ } }     //
//     { { }._:_.{  }}     //
//     {{  } -:- { } }     //
//     {_{ }`===`{  _}     //
//    ((((\)     (/))))    //
//    DEGEN DEGEN DEGEN    //
//    CARD  CARD  CARD     //
//                         //
//                         //
/////////////////////////////


contract DEGEN is ERC721Creator {
    constructor() ERC721Creator("DEGEN Card", "DEGEN") {}
}
