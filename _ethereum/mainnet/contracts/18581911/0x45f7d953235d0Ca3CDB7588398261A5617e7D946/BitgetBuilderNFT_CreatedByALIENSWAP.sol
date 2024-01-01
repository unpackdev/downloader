
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



contract BitgetBuilderNFT_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"Bitget Builder NFT", unicode"BB", 0x694E5C6c5092025644172fE2081188333960fe24, 500, 500, "https://createx.art/api/v1/createx/metadata/ETH/uumsdi63mr3yu7np0to4g2257y1f4eyk/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/uumsdi63mr3yu7np0to4g2257y1f4eyk", 0x5A6fA88a66fdAFc7d313DD93bbA16F2683eEfA86, 0, 1700136000, 500) {}
}
