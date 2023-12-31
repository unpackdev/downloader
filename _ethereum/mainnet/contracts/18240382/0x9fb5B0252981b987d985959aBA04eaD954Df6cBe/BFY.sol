// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Butterfly by Heiko Hellwig
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//    BBBBB           tt    tt                   fff lll             //
//    BB   B  uu   uu tt    tt      eee  rr rr  ff   lll yy   yy     //
//    BBBBBB  uu   uu tttt  tttt  ee   e rrr  r ffff lll yy   yy     //
//    BB   BB uu   uu tt    tt    eeeee  rr     ff   lll  yyyyyy     //
//    BBBBBB   uuuu u  tttt  tttt  eeeee rr     ff   lll      yy     //
//                                                        yyyyy      //
//                                                                   //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract BFY is ERC1155Creator {
    constructor() ERC1155Creator("Butterfly by Heiko Hellwig", "BFY") {}
}
