// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IFee {
    function calculate(uint256 amount) external view returns (uint256);
}
