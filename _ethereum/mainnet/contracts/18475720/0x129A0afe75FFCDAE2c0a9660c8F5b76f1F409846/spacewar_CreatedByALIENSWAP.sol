
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



contract spacewar_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"spacewar", unicode"sw", 0x694E5C6c5092025644172fE2081188333960fe24, 9999, 9999, "https://createx.art/api/v1/createx/metadata/ETH/njkpu83lsmp8u1csb27lozjncyx8djc7/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/njkpu83lsmp8u1csb27lozjncyx8djc7", 0x066003C1493A346357Af15158cD985b4A6e29D3F, 100, 1698822822, 9999) {}
}
