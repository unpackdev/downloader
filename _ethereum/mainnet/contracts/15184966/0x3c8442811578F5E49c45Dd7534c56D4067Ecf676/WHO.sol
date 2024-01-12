
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Who am I?
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    W     W H  H  OOO    AA  M   M  III  ???      //
//    W     W H  H O   O  A  A MM MM   I  ?   ?     //
//    W  W  W HHHH O   O  AAAA M M M   I     ?      //
//     W W W  H  H O   O  A  A M   M   I    ?       //
//      W W   H  H  OOO   A  A M   M  III   ?       //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract WHO is ERC721Creator {
    constructor() ERC721Creator("Who am I?", "WHO") {}
}
