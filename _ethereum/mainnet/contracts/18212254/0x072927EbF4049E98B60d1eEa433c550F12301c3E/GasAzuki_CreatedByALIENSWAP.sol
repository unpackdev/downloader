
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



contract GasAzuki_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"0GasAzuki", unicode"0GasAzuki", 0x694E5C6c5092025644172fE2081188333960fe24, 10000, 10000, "https://createx.art/api/v1/createx/metadata/ETH/9cegr9l8j82vwzjewgca6d0mt34egzv3/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/9cegr9l8j82vwzjewgca6d0mt34egzv3", 0x0Ff8530Ba3a4A92c9cB3aB6cFA75E48C561f1D86, 500, 1695637503, 10000) {}
}
