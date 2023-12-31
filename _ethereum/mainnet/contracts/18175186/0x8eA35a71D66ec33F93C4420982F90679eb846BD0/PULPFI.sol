// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pulp-fi by JeffJag
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//           Pulp-fi            //
//    Digital Art Collection    //
//                              //
//           JeffJag            //
//          9-19-2023           //
//                              //
//                              //
//////////////////////////////////


contract PULPFI is ERC721Creator {
    constructor() ERC721Creator("Pulp-fi by JeffJag", "PULPFI") {}
}
