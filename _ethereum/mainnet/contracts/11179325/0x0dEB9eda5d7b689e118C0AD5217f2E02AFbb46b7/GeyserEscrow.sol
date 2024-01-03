// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Ownable.sol";

import "./EnokiGeyser.sol";

contract GeyserEscrow is Ownable {
    EnokiGeyser public geyser;

    constructor(EnokiGeyser geyser_) public {
        geyser = geyser_;
    }

    function lockTokens(
        uint256 amount,
        uint256 durationSec
    ) external onlyOwner {
        IERC20 distributionToken = geyser.getDistributionToken();
        distributionToken.approve(address(geyser), amount);

        geyser.lockTokens(amount, durationSec);
    }
}
