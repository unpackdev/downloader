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
        address operations = 0x56eE3F22331426dcA30Bf8CBbD738704b0f4526A;
        address marketmaker = 0x556979171Aa8C305a63eBc50b0624Ae9556E3bAc;

        // Mint for team and marketing
        _mint(operations, (maxSupply * 5) / 100); // 5%
        _mint(marketmaker, (maxSupply * 10) / 100); // 10%

        // Mint to deployer to be used for Uniswap
        _mint(msg.sender, (maxSupply * 85) / 100); // 85%

        // Renounce ownership
        renounceOwnership();
    }
}

