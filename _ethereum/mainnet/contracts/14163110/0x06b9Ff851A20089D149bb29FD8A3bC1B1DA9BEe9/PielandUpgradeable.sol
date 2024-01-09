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
import "./ERC721BonfireWithPreSaleBasedOnWhitelistUpgradeable.sol";

contract PielandUpgradeable is ERC721BonfireWithPreSaleBasedOnWhitelistUpgradeable {
    // name, symbol, bURI, maxTotalSupply, maxPerTx, maxPerWallet, mintPrice, maxPreSaleSupply
    function initialize() initializer public {
      ERC721BonfireWithPreSaleBasedOnWhitelistUpgradeable.init("Pieland", "PIELAND", "https://metadata.livetoken.co/api/metadata/PIELAND/", 10314, 10, 30, 0.088 ether, 0);
    }
}
