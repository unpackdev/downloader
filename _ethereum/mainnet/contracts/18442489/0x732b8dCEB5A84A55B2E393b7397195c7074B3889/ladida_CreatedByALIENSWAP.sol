
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



contract ladida_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"ladida", unicode"lad", 0x694E5C6c5092025644172fE2081188333960fe24, 1000000, 1000000, "https://createx.art/api/v1/createx/metadata/ETH/b6zwzc34ck3kr483t19p3ymrirw5ar7y/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/b6zwzc34ck3kr483t19p3ymrirw5ar7y", 0x3382A156b02032395473442f357aECbBA16C415C, 2000, 1698420504, 1000000) {}
}
