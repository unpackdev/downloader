// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20BaseInternal.sol";
import "./ReentrancyGuard.sol";

import "./MagicWhitelistStorage.sol";

contract MagicMintReentrancyFix is ERC20BaseInternal, ReentrancyGuard {
    function mint(address account, uint256 amount) external nonReentrant {
        require(
            MagicWhitelistStorage.layout().whitelist[msg.sender],
            'Magic: sender must be whitelisted'
        );
        _mint(account, amount);
    }
}
