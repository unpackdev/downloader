// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC721PresetMinterPauserAutoId.sol";

contract FlokiInuNFTReward is ERC721PresetMinterPauserAutoId, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    )
        ERC721PresetMinterPauserAutoId(name, symbol, baseTokenURI)
        Ownable()
    {

    }
}
