// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IERC20.sol";

/**
 * @notice Compound V3's Comet interface
 */
interface IComet is IERC20 {
    function allow(address manager, bool isAllowed) external;
    function isAllowed(address owner, address manager) external view returns (bool);
    function hasPermission(address owner, address manager) external view returns (bool);
    function collateralBalanceOf(address account, address asset) external view returns (uint128);
    function supplyTo(address dst, address asset, uint256 amount) external;
    function withdrawFrom(address src, address dst, address asset, uint256 amount) external;
}
