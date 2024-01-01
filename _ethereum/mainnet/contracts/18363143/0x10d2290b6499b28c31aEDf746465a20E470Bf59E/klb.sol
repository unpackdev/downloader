// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KILLABEARS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                                                                                                                                   //
//    Download all your assets (pfp, video, gif and more) in our Dashboard                                                                                                                                                                                                                                                                                           //
//    KILLABEARS is a collection of 3333 thoughtfully designed, animated and randomly generated NFTs on the Ethereum Blockchain by Mexican artist Memo Angeles. KILLABEARS holders can participate in exclusive events, such as: NFT claims, raffles, giveaways and much, much more. Don't forget, all KILLABEARS are special -- but some are especially special.    //
//    ... and the best is yet to come, check out our website www.killabears.com                                                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract klb is ERC721Creator {
    constructor() ERC721Creator("KILLABEARS", "klb") {}
}
