
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



contract Steampunkrats_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"Steampunk rats", unicode"RTS", 0x694E5C6c5092025644172fE2081188333960fe24, 1000, 1000, "https://createx.art/api/v1/createx/metadata/ETH/1f9ndwil73m8yvdq1d32lq9sch199e0t/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/1f9ndwil73m8yvdq1d32lq9sch199e0t", 0x68c81Fdf2C21b333495408B83514F4006F6768c4, 500, 1696143720, 1000) {}
}
