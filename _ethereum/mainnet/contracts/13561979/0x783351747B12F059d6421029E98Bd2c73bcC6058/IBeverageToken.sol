// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBeverageToken is IERC20 {
    function mint(address to, uint256 amount) external;
}