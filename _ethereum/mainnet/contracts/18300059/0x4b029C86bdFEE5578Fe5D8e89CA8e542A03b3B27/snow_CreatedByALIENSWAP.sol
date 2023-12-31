
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



contract snow_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"snow", unicode"snow", 0x694E5C6c5092025644172fE2081188333960fe24, 5, 5, "https://createx.art/api/v1/createx/metadata/ETH/cr2opz9wc5kre563h14fdfp0f438v6u3/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/cr2opz9wc5kre563h14fdfp0f438v6u3", 0x9202BF22605fB429aF0add0428F7CB4Dd8b6B26C, 1000, 1696699168, 5) {}
}
