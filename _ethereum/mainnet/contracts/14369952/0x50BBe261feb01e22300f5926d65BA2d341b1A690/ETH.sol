
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Diva
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//      o__ __o       __o__   o              o     o             //
//     <|     v\        |    <|>            <|>   <|>            //
//     / \     <\      / \   < >            < >   / \            //
//     \o/       \o    \o/    \o            o/  o/   \o          //
//      |         |>    |      v\          /v  <|__ __|>         //
//     / \       //    < >      <\        />   /       \         //
//     \o/      /       |         \o    o/   o/         \o       //
//      |      o        o          v\  /v   /v           v\      //
//     / \  __/>      __|>_         <\/>   />             <\     //
//                                                               //
//                                                               //
//                                                               //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract ETH is ERC721Creator {
    constructor() ERC721Creator("Diva", "ETH") {}
}
