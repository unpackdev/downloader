// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./IERC20.sol";

interface IWstETH is IERC20 {
    function wrap(uint256 _stETHAmount) external returns (uint256);

    function unwrap(uint256 _wstETHAmount) external returns (uint256);
}
