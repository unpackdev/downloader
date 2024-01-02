// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface ISDLPool {
    function effectiveBalanceOf(address _account) external view returns (uint256);
}
