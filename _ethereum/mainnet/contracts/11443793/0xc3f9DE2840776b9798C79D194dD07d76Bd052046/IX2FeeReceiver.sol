// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2FeeReceiver {
    function notifyFees(address token, uint256 amount) external;
    function notifyInterest(address token, uint256 amount) external;
}
