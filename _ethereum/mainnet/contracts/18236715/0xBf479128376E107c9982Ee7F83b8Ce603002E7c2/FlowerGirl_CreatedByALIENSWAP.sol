
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



contract FlowerGirl_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"Flower Girl", unicode"FLG", 0x694E5C6c5092025644172fE2081188333960fe24, 777, 777, "https://createx.art/api/v1/createx/metadata/ETH/gqc1zuoutujqryimkkce91k2l9s43am5/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/gqc1zuoutujqryimkkce91k2l9s43am5", 0x81c54645A23049ae2df5616BaC52540b5a83eD79, 500, 1695934094, 777) {}
}
