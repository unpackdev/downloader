
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



contract Pixels_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"Pixels", unicode"PIX", 0x694E5C6c5092025644172fE2081188333960fe24, 1000000, 1000000, "https://createx.art/api/v1/createx/metadata/ETH/j0l8mrtcclr5a40yv2x4h9qgy49k311b/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/j0l8mrtcclr5a40yv2x4h9qgy49k311b", 0xc29067833665820b3505953a87F8265C9f1A517b, 500, 1695813847, 1000000) {}
}
