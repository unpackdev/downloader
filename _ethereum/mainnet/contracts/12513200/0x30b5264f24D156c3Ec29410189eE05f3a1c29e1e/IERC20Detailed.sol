// SPDX-License-Identifier: MIT

import "./IERC20.sol";

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP including optional functions.
 */
interface IERC20Detailed is IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function name() external view returns (string memory);
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function symbol() external view returns (string memory);
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function decimals() external view returns (uint8);
}