// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IWrappedToken {
    function withdraw(uint256 wad) external;

    function deposit() external payable;
}
