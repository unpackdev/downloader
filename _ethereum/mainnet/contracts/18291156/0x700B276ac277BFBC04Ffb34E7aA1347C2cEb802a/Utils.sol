// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Utils {
    function topUpAllocation(uint256 availableBalance, uint256 amount, uint256 currentAllocation) internal pure returns (uint256) {
        require(amount <= availableBalance, "Exceeds available balance");
        return currentAllocation + amount;
    }
}
