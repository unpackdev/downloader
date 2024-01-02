// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: On-Chain Satellites
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                 //
//                                                                                                                                                 //
//       .aMMMb  dMMMMb  .aMMMb  dMP dMP .aMMMb  dMP dMMMMb        .dMMMb  .aMMMb dMMMMMMP dMMMMMP dMP     dMP     dMP dMMMMMMP dMMMMMP .dMMMb     //
//      dMP"dMP dMP dMP dMP"VMP dMP dMP dMP"dMP amr dMP dMP       dMP" VP dMP"dMP   dMP   dMP     dMP     dMP     amr    dMP   dMP     dMP" VP     //
//     dMP dMP dMP dMP dMP     dMMMMMP dMMMMMP dMP dMP dMP        VMMMb  dMMMMMP   dMP   dMMMP   dMP     dMP     dMP    dMP   dMMMP    VMMMb       //
//    dMP.aMP dMP dMP dMP.aMP dMP dMP dMP dMP dMP dMP dMP       dP .dMP dMP dMP   dMP   dMP     dMP     dMP     dMP    dMP   dMP     dP .dMP       //
//    VMMMP" dMP dMP  VMMMP" dMP dMP dMP dMP dMP dMP dMP        VMMMP" dMP dMP   dMP   dMMMMMP dMMMMMP dMMMMMP dMP    dMP   dMMMMMP  VMMMP"        //
//                                                                                                                                                 //
//                                                                                                                                                 //
//                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OCS is ERC721Creator {
    constructor() ERC721Creator("On-Chain Satellites", "OCS") {}
}
