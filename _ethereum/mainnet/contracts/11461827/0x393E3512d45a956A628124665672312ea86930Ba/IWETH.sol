// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @dev Simple WETH interface.
 */
interface IWETH {
    function withdraw(uint256 wad) external;
    function deposit() external payable;
    function balanceOf(address query) external returns (uint256);
}