// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eva's
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//    ___________               /\            //
//    \_   _____/___  _______   )/  ______    //
//     |    __)_ \  \/ /\__  \     /  ___/    //
//     |        \ \   /  / __ \_   \___ \     //
//    /_______  /  \_/  (____  /  /____  >    //
//            \/             \/        \/     //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract EVA is ERC721Creator {
    constructor() ERC721Creator("Eva's", "EVA") {}
}
