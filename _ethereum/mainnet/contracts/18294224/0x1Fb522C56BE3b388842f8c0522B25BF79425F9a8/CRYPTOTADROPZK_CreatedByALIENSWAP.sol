
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



contract CRYPTOTADROPZK_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"CRYPTOTA DROP ZK", unicode"ZKDROP", 0x694E5C6c5092025644172fE2081188333960fe24, 100000, 100000, "https://createx.art/api/v1/createx/metadata/ETH/nc6ocs319078zeqhojaavqvc764j9jfq/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/nc6ocs319078zeqhojaavqvc764j9jfq", 0x28D4EEE28dC86fd9A05CE8808D2b1719F9f15332, 500, 1696628663, 100000) {}
}
