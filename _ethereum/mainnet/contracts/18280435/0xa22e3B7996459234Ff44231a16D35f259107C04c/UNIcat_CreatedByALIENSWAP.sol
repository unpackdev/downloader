
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



contract UNIcat_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"UNIcat", unicode"UCAT", 0x694E5C6c5092025644172fE2081188333960fe24, 1, 1, "https://createx.art/api/v1/createx/metadata/ETH/dmbtofr0gkr1qguoc5zqf4qzrrip3v2u/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/dmbtofr0gkr1qguoc5zqf4qzrrip3v2u", 0x33b9bB2FecFB937E3ebAEF466108e2aE7c9CE110, 10, 1696461994, 1) {}
}
