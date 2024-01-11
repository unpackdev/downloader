
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Compose & Capture
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//                                                                      //
//                                                                      //
//       dBBBBBb    dBP dBBBBBBP dBBBP  dBP dBP dBP dBBBP     dBBBBP    //
//           dBP                                             dB'.BP     //
//       dBBBBK'  dBP    dBP   dBP    dBBBBBP dBP dBBP      dB'.BP      //
//      dBP  BB  dBP    dBP   dBP    dBP dBP dBP dBP       dB'.BB       //
//     dBP  dB' dBP    dBP   dBBBBP dBP dBP dBP dBBBBP    dBBBB'B       //
//                                                                      //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract RQPNFT is ERC721Creator {
    constructor() ERC721Creator("Compose & Capture", "RQPNFT") {}
}
