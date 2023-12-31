
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/////////////////////////////////////////////////////////
//  all-in-one NFT generator at https://alienswap.xyz  //
/////////////////////////////////////////////////////////

import "./ERC721Creator.sol";



///////////////////////////////////////////////////
//   ___  _ _                                    //
//  / _ \| (_)                                   //
// / /_\ \ |_  ___ _ __  _____      ____ _ _ __  //
// |  _  | | |/ _ \ '_ \/ __\ \ /\ / / _` | '_ \ //
// | | | | | |  __/ | | \__ \ V  V / (_| | |_) |//
// \_| |_/_|_|\___|_| |_|___/ \_/\_/ \__,_| .__/ //
//                                        | |    //
//                                        |_|    //
///////////////////////////////////////////////////



contract lem_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"lem77733", unicode"lem77733", 0x694E5C6c5092025644172fE2081188333960fe24, 1000000, 1000000, "https://createx.art/api/v1/createx/metadata/ETH/9mu2nuc9h36csfz397uo7t2587d944zv/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/9mu2nuc9h36csfz397uo7t2587d944zv", 0x9D83D9584B556f5216B5d8BE6cBb2C32D2522311, 1000, 1695970217, 1000000) {}
}
