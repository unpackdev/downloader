// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: suzuchii
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//                                      .__ .__.__    //
//      ＿＿＿＿＿＿＿＿＿＿＿ | |__ |__|__|                     //
//     /__/ | \___ / | \_/ ___\| | \| | |             //
//     \___ \| | // /| | /\ \___| はい\ | |             //
//    /____ >____//_____ \____/ \___ >___| /__|__|    //
//         \/ \/ \/ \/                                //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract SZC is ERC1155Creator {
    constructor() ERC1155Creator("suzuchii", "SZC") {}
}
