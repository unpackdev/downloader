
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



contract SuiPunksHomage_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"Sui Punks Homage", unicode"DKN", 0x694E5C6c5092025644172fE2081188333960fe24, 10, 10, "https://createx.art/api/v1/createx/metadata/ETH/in6m397k91zswc63euvez5wrg6hd5llf/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/in6m397k91zswc63euvez5wrg6hd5llf", 0x104140a0344c0f41c135aAAef9fA7153769dC1ca, 1000, 1696130036, 10) {}
}
