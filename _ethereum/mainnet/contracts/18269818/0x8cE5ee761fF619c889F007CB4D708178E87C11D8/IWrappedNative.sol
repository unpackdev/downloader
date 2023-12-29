// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

interface IWrappedNative {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

