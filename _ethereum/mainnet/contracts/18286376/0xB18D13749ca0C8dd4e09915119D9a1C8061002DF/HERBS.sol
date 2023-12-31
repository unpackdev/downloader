// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Abstract Herbs 1.2
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    the herbs 1.2 contract is an intermediate contract and secures the "herbrelease" process                //
//    This has been running for 18 months as of the date of this letter.                                      //
//    This contract will be used until the correct herb contract is written and the BIG MIGRATION occurs.     //
//    #herbish                                                                                                //
//    #herbfam                                                                                                //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HERBS is ERC1155Creator {
    constructor() ERC1155Creator("Abstract Herbs 1.2", "HERBS") {}
}
