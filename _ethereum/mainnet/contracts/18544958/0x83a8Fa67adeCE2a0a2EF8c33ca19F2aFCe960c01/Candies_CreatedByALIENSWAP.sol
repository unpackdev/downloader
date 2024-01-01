
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



contract Candies_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"$Candies ", unicode"CANDIES", 0x694E5C6c5092025644172fE2081188333960fe24, 10000, 10000, "https://createx.art/api/v1/createx/metadata/ETH/u4qvpohflr43d6edbnr3pt63dxeu6u10/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/u4qvpohflr43d6edbnr3pt63dxeu6u10", 0x98189b35a3A8B736EC9A12Da5767B9d1F58eD886, 0, 1699660407, 10000) {}
}
