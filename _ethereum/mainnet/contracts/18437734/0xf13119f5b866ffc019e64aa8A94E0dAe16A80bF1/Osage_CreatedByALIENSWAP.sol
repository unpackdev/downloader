
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



contract Osage_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"Osage", unicode"OSG", 0x694E5C6c5092025644172fE2081188333960fe24, 165, 165, "https://createx.art/api/v1/createx/metadata/ETH/6x2cvuupely3st5y70zcsznrwkfl4u7u/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/6x2cvuupely3st5y70zcsznrwkfl4u7u", 0xB4dC4C7460c58E7652Cd615675a1F707EbB67E9a, 500, 1698374307, 165) {}
}
