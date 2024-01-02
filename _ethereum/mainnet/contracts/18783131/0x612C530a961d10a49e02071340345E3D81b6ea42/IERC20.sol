// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IERC20 {
    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Unwrap WETH to ETH`.
     */
    function withdraw(uint256 amount) external;
}
