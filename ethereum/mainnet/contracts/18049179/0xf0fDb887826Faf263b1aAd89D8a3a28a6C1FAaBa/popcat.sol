//https://twitter.com/popcat_erc20
//https://www.popcatcoin.net/
//https://t.me/popcoinETH

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Pausable.sol";
import "./Ownable.sol";

contract popcat is ERC20Pausable, Ownable {
    constructor() ERC20("popcat coin", "pop") {
        uint256 initialSupply = 100000000 * 10 ** 18; // 100,000,000 tokens with 18 decimals
        _mint(msg.sender, initialSupply);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}