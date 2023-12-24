// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Deity in the City
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//     __ ___ __ __  _____  _____     //
//    |  |  //  |  \/  _  \/  _  \    //
//    |  _ < |  |  ||  _  <|  _  |    //
//    |__|__\\_____/\__|\_/\__|__/    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract KURA is ERC1155Creator {
    constructor() ERC1155Creator("Deity in the City", "KURA") {}
}
