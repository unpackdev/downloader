// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./IERC20.sol";
import "./TokenLockup.sol";

contract BatchTransfer {
    function batchTransfer(IERC20 token,
        address[] memory recipients,
        uint[] memory amounts) external returns (bool) {

        require(recipients.length == amounts.length, "recipient & amount arrays must be the same length");

        for (uint i; i < recipients.length; i++) {
            require(token.transferFrom(msg.sender, recipients[i], amounts[i]));
        }

        return true;
    }
}