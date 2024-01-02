// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.19;

contract MockFeesManager {
    event FeeDeposited(address asset, uint256 amount);

    function depositFee(address asset, uint256 amount) external {
        emit FeeDeposited(asset, amount);
    }
}
