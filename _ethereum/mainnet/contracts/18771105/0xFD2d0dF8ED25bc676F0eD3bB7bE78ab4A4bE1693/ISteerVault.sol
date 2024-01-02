// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./IERC20.sol";

interface ISteerVault is IERC20 {
    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function getTotalAmounts() external view returns (uint256 total0, uint256 total1);
}
