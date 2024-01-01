// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: REFLECTING-D
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//                                                                                   //
//    ///////////////////////////////////////////////////////////////////////////    //
//    //                                                                       //    //
//    //                                                                       //    //
//    //                                                                       //    //
//    //     █████  ██████  ███████  █████                                     //    //
//    //    ██   ██ ██   ██ ██      ██   ██                                    //    //
//    //    ███████ ██████  █████   ███████                                    //    //
//    //    ██   ██ ██   ██ ██      ██   ██                                    //    //
//    //    ██   ██ ██████  ██      ██   ██                                    //    //
//    //                                                                       //    //
//    //                                                                       //    //
//    //    //This is a contract for the sale of digital animated art          //    //
//    //    created by Annette Back, based on the original painting            //    //
//    //    by Annette Back "Reflecting". The painting was created in 2019.    //    //
//    //    The digital art/annimation was created in 2023.                    //    //
//    //                                                                       //    //
//    //                                                                       //    //
//    //                                                                       //    //
//    //                                                                       //    //
//    ///////////////////////////////////////////////////////////////////////////    //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract AB167 is ERC1155Creator {
    constructor() ERC1155Creator("REFLECTING-D", "AB167") {}
}
