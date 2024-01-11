// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IAccessControlEnumerableUpgradeable} from "IAccessControlEnumerableUpgradeable.sol";
import {IERC20} from "IERC20.sol";

interface IBasePortfolio is IAccessControlEnumerableUpgradeable {
    function MANAGER_ROLE() external view returns (bytes32);

    function endDate() external view returns (uint256);

    function underlyingToken() external view returns (IERC20);

    function deposit(uint256 amount, address sender) external;

    function withdraw(uint256 shares, address sender) external;

    function value() external view returns (uint256);
}
