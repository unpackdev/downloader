// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IDepositor {
    function deposit(uint256 _amount, bool _lock, bool _stake, address _user) external;
    function incentiveToken() external view returns (uint256);
}
