// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @dev Some old tokens are implemented without the `returns` keyword (this was prior to the ERC20 standart change).
 * That's why we are using our own ERC20 interface.
 */
interface IERC20Cutted {
    
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    
}
