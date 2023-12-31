
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



contract yokoono_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"yoko ono", unicode"yoko ono", 0x694E5C6c5092025644172fE2081188333960fe24, 100, 100, "https://createx.art/api/v1/createx/metadata/ETH/ladpf2qg16gs8suhilm13eawjr22r9lm/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/ladpf2qg16gs8suhilm13eawjr22r9lm", 0x4504b3ae1ea60E837c6FF98938DfCB8969e3944f, 100, 1696685317, 100) {}
}
