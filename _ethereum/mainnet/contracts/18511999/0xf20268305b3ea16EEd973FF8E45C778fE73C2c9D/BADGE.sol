// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Badges by Fabrik
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//       _______   ___  ___  ______ __     //
//      / __/ _ | / _ )/ _ \/  _/ //_/     //
//     / _// __ |/ _  / , _// // ,<        //
//    /_/ /_/ |_/____/_/|_/___/_/|_|       //
//                                 LABS    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract BADGE is ERC1155Creator {
    constructor() ERC1155Creator("Badges by Fabrik", "BADGE") {}
}
