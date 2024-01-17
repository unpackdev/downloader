
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CMCBfanart by Aotakana
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//    This is a NFT collection of the fanart of Crypto Maids and Butlers made by Aotakana.    //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract CMCBA is ERC721Creator {
    constructor() ERC721Creator("CMCBfanart by Aotakana", "CMCBA") {}
}
