// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";

interface IWrappedToken {
    event Wrap(address indexed sender, uint256 amount);
    event Unwrap(address indexed recipient, uint256 amount);
    event Withdraw(uint256 amount);

    /**
     * @dev Wrap underlying tokens
     * @param _value The amount of token to wrap in this contract
     */
    function wrap(uint256 _value) external;

    /**
     * @dev Unwrap the underlying token
     * @param _value The amount of tokens to unwrap
     */
    function unwrap(uint256 _value) external;

    /**
     * @dev Replenish the contract balance with additional tokens in the underlying asset
     * @param _value The amount of tokens to replenish
     */
    function replenish(uint256 _value) external;

    /**
     * @dev Withdraw extra funds by owner, in case when contract win the lottery
     */
    function withdrawExtraFunds() external;

    /**
     * @dev Show address of underlying token
     * @return Address of underlying token
     */
    function getUnderlyingToken() external view returns (IERC20);

    /**
     * @dev Show total wrapped balance
     * @return amount of wrapped tokens balance
     */
    function getTotalWrapped() external view returns (uint256);
}
