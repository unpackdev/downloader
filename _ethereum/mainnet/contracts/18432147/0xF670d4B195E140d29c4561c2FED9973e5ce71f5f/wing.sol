// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: wingman
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//    w       w  iiii  nnn   nn   gggg  m     m  aaaa  nnn   nn    //
//    w       w   ii   nn n  nn  g   g  mm   mm  a  a  nn n  nn    //
//    w   w   w   ii   nn  n nn  g      m m m m  aaaa  nn  n nn    //
//     w w w w    ii   nn   nnn  g  gg  m  m  m  a  a  nn   nnn    //
//      w   w    iiii  nn    nn   gggg  m     m  a  a  nn    nn    //
//                                                                 //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract wing is ERC1155Creator {
    constructor() ERC1155Creator("wingman", "wing") {}
}
