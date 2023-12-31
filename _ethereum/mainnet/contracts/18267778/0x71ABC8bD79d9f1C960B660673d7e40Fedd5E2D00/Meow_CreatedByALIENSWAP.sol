
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



contract Meow_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"Meow", unicode"$Meow", 0x694E5C6c5092025644172fE2081188333960fe24, 100, 100, "https://createx.art/api/v1/createx/metadata/ETH/9924ehamhi6vrw965nz7bfdl9hvnq1wi/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/9924ehamhi6vrw965nz7bfdl9hvnq1wi", 0x78e09Dc6496C698c95fFE59E47c7D353439d41f8, 100, 1696308776, 100) {}
}
