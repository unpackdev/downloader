// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IErc20WithDecimals {
    function decimals() external view returns (uint256);
}
