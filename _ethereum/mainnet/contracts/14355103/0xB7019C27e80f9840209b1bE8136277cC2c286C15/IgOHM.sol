// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./IERC20.sol";

interface IgOHM is IERC20 {
    function index() external view returns (uint256);
}
