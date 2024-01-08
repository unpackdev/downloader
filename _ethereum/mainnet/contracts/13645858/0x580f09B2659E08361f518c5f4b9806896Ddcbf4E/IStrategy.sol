// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IStrategy {
    function name() external pure returns (string memory);

    function version() external pure returns (string memory);

    function underlying() external view returns (address);

    function fund() external view returns (address);

    function creator() external view returns (address);

    function withdrawAllToFund() external;

    function withdrawToFund(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256);

    function doHardWork() external;
}
