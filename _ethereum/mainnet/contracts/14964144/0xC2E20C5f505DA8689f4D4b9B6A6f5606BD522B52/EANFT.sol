
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eagle NFTs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//    All of the Eagles sold have been specially thought and designed, they are planning to implement the free Eagles organizations that we will create around the world thanks to you, but we are trying to move forward to take the company to higher levels with a wider audience and we are moving forward with patience. EAGLE NFT will have the beautiful Eagle avatar which you will give our domain users a special place in the custom build.    //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EANFT is ERC721Creator {
    constructor() ERC721Creator("Eagle NFTs", "EANFT") {}
}
