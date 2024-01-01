// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ida Belle PFP Project
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//      __  ____   __     ____  ____  __    __    ____     //
//     (  )(    \ / _\   (  _ \(  __)(  )  (  )  (  __)    //
//      )(  ) D (/    \   ) _ ( ) _) / (_/\/ (_/\ ) _)     //
//     (__)(____/\_/\_/  (____/(____)\____/\____/(____)    //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract IDA is ERC721Creator {
    constructor() ERC721Creator("Ida Belle PFP Project", "IDA") {}
}
