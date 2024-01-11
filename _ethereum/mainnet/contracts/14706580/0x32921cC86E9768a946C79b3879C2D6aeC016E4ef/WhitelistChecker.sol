// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./InteractiveNotificationReceiver.sol";
import "./IWhitelistRegistry.sol";

contract WhitelistChecker is InteractiveNotificationReceiver {
    error SenderIsNotWhitelisted();

    IWhitelistRegistry public immutable whitelistRegistry;

    constructor(IWhitelistRegistry _whitelistRegistry) {
        whitelistRegistry = _whitelistRegistry;
    }

    function notifyFillOrder(address taker, address, address, uint256, uint256, bytes memory) external view {
        if (whitelistRegistry.status(taker) != 1) revert SenderIsNotWhitelisted();
    }
}
