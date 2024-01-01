// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: shodojin collection
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//             __              __        _ _         //
//       _____/ /_  ____  ____/ /___    (_|_)___     //
//      / ___/ __ \/ __ \/ __  / __ \  / / / __ \    //
//     (__  ) / / / /_/ / /_/ / /_/ / / / / / / /    //
//    /____/_/ /_/\____/\__,_/\____/_/ /_/_/ /_/     //
//                                /___/              //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract shodojin is ERC1155Creator {
    constructor() ERC1155Creator("shodojin collection", "shodojin") {}
}
