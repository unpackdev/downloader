
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: lucclop abstract digital glitch
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//    L    U   U  CCC  CCC L     OOO  PPPP    AA  BBBB   SSS  TTTTTT RRRR   AA   CCC TTTTTT  DDD  III  GGG  III TTTTTT  AA  L      GGG  L    III TTTTTT  CCC H  H     //
//    L    U   U C    C    L    O   O P   P  A  A B   B S       TT   R   R A  A C      TT    D  D  I  G      I    TT   A  A L     G     L     I    TT   C    H  H     //
//    L    U   U C    C    L    O   O PPPP   AAAA BBBB   SSS    TT   RRRR  AAAA C      TT    D  D  I  G  GG  I    TT   AAAA L     G  GG L     I    TT   C    HHHH     //
//    L    U   U C    C    L    O   O P      A  A B   B     S   TT   R R   A  A C      TT    D  D  I  G   G  I    TT   A  A L     G   G L     I    TT   C    H  H     //
//    LLLL  UUU   CCC  CCC LLLL  OOO  P      A  A BBBB  SSSS    TT   R  RR A  A  CCC   TT    DDD  III  GGG  III   TT   A  A LLLL   GGG  LLLL III   TT    CCC H  H     //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LUC is ERC721Creator {
    constructor() ERC721Creator("lucclop abstract digital glitch", "LUC") {}
}
