// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rigby
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    __________.__      ___.              //
//    \______   \__| ____\_ |__ ___.__.    //
//     |       _/  |/ ___\| __ <   |  |    //
//     |    |   \  / /_/  > \_\ \___  |    //
//     |____|_  /__\___  /|___  / ____|    //
//            \/  /_____/     \/\/         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract RGBY is ERC1155Creator {
    constructor() ERC1155Creator("Rigby", "RGBY") {}
}
