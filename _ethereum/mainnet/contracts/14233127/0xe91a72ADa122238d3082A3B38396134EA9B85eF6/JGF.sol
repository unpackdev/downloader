
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Junkie Griz Fiends
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//        JJJ UU   UU NN   NN KK  KK IIIII EEEEEEE    GGGG  RRRRRR  IIIII ZZZZZ  FFFFFFF IIIII EEEEEEE NN   NN DDDDD    SSSSS     //
//        JJJ UU   UU NNN  NN KK KK   III  EE        GG  GG RR   RR  III     ZZ  FF       III  EE      NNN  NN DD  DD  SS         //
//        JJJ UU   UU NN N NN KKKK    III  EEEEE    GG      RRRRRR   III    ZZ   FFFF     III  EEEEE   NN N NN DD   DD  SSSSS     //
//    JJ  JJJ UU   UU NN  NNN KK KK   III  EE       GG   GG RR  RR   III   ZZ    FF       III  EE      NN  NNN DD   DD      SS    //
//     JJJJJ   UUUUU  NN   NN KK  KK IIIII EEEEEEE   GGGGGG RR   RR IIIII ZZZZZ  FF      IIIII EEEEEEE NN   NN DDDDDD   SSSSS     //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JGF is ERC721Creator {
    constructor() ERC721Creator("Junkie Griz Fiends", "JGF") {}
}
