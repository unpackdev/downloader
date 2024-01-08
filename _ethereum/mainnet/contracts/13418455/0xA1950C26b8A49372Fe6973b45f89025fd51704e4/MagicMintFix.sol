// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20BaseInternal.sol";
import "./ReentrancyGuard.sol";

import "./MagicWhitelistStorage.sol";

contract MagicMintFix is ERC20BaseInternal, ReentrancyGuard {
    event MintSignal(address minter, address account, uint256 amount);

    function mint(address account, uint256 amount) external nonReentrant {
        require(
            MagicWhitelistStorage.layout().whitelist[msg.sender],
            'Magic: sender must be whitelisted'
        );

        emit MintSignal(msg.sender, account, amount);
    }
}
