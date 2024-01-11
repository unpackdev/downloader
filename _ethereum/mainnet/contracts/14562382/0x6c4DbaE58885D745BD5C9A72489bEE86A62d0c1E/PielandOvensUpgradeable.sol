// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* 
-----------------------------------
  _____ _      _                 _ 
 |  __ (_)    | |               | |
 | |__) |  ___| | __ _ _ __   __| |
 |  ___/ |/ _ \ |/ _` | '_ \ / _` |
 | |   | |  __/ | (_| | | | | (_| |
 |_|   |_|\___|_|\__,_|_| |_|\__,_|

         https://pieland.io
            @PielandNFT
===================================
*/ 

// Smart contract by Bonfire
import "./ERC721BonfireBaseUpgradeable.sol";

contract PielandOvensUpgradeable is ERC721BonfireBaseUpgradeable {
    // name, symbol, bURI, maxTotalSupply, maxPerTx, maxPerWallet, mintPrice
    function initialize() initializer public {
      ERC721BonfireBaseUpgradeable.init("Pieland Ovens", "PIELAND_OVENS", "https://", 0, 1, 1, 0 ether);
    }
}
