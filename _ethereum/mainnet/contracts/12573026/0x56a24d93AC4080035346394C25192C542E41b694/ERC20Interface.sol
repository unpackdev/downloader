// SPDX-License-Identifier: MIT

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.12;

import "./IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ERC20Interface is IERC20 {
    function decimals() external view returns (uint8);
}
