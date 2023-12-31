
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



contract SingularNFT_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"Singular-NFT", unicode"S-Alien", 0x694E5C6c5092025644172fE2081188333960fe24, 1000, 1000, "https://createx.art/api/v1/createx/metadata/ETH/o4vontqn7l2dydvoofq6qihwvypyqmms/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/o4vontqn7l2dydvoofq6qihwvypyqmms", 0x224eDa363781b3494f44fE1272dbCa1e0E3C75A0, 0, 1696913087, 1000) {}
}
