
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mon Salai
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//      _____             __   .__ .__                //
//      /  _  \  _______ _/  |_ |__||  |    ____      //
//     /  /_\  \ \_  __ \\   __\|  ||  |  _/ __ \     //
//    /    |    \ |  | \/ |  |  |  ||  |__\  ___/     //
//    \____|__  / |__|    |__|  |__||____/ \___  >    //
//            \/                               \/     //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract ASH is ERC721Creator {
    constructor() ERC721Creator("Mon Salai", "ASH") {}
}
