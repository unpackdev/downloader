// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

/**
 * @dev Interface of the the optional methods of the ERC20 standard as defined in the EIP.
 */
interface IERC20Optional {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
