// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the limited ERC20PresetMinterPauser.
 */
interface IMinter {
    /**
     * @dev Mint amount of tokens to specific address.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}