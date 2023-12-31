// SPDX-License-Identifier: MIT

// $Wolve Token
// Website: https://wolve.org
// Telegram: https://t.me/Wolvetoken
// Twitter: https://twitter.com/Wolveorg

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC20.sol";

contract Wolve is ERC20, Ownable
 {
    constructor() ERC20("Wolve.org", "WOLVE") {
        // Total max supply set at 100 Billion
        uint256 maxSupply = 100000000000 * (10 ** decimals());

        // Wallets
        address futures = 0xAd02Ed6fC2A149D22F8Ff81733681cC44DE3585F;
        address marketmaker = 0x5E62218Fc383f538126bd74cF8F577D3D37c5da3;

        // Mint for team and marketing
        _mint(futures, (maxSupply * 5) / 100); // 5%
        _mint(marketmaker, (maxSupply * 10) / 100); // 10%

        // Mint to deployer to be used for Uniswap
        _mint(msg.sender, (maxSupply * 85) / 100); // 85%

        // Renounce ownership
        renounceOwnership();
    }
}

