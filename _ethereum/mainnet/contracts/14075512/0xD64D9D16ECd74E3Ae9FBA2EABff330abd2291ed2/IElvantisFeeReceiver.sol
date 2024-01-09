// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IElvantisFeeReceiver {
    function onFeeReceived(address token, uint256 amount) external;
}
