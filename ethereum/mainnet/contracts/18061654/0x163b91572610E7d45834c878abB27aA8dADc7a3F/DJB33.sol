// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DJB VIN TAG Registration
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    VIN: 5XYZU3LA7DG072881    //
//                              //
//    Year: 2013                //
//                              //
//    Make: Hyundai             //
//                              //
//    Model: Santa Fe Sport     //
//                              //
//    Year: 2013                //
//                              //
//    State: FL                 //
//                              //
//    County: Alachua           //
//                              //
//    TAG: 033 RKV              //
//                              //
//                              //
//////////////////////////////////


contract DJB33 is ERC721Creator {
    constructor() ERC721Creator("DJB VIN TAG Registration", "DJB33") {}
}
