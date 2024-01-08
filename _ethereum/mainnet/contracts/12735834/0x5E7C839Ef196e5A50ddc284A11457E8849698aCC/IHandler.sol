// "SPDX-License-Identifier: GPL-3.0"
pragma solidity 0.8.4;

import "./IERC20.sol";

interface IHandler {
    /// @notice receive ETH
    receive() external payable;

    /**
     * @notice Handle an order execution
     * @param _inToken - Address of the input token
     * @param _outToken - Address of the output token
     * @param _amountIn - uint256 of the input token amount
     * @param _amountOutMin - uint256 of the min return amount of output token
     * @param _data - Bytes of arbitrary data
     * @return bought - Amount of output token bought
     */
    function handle(
        IERC20 _inToken,
        IERC20 _outToken,
        uint256 _amountIn,
        uint256 _amountOutMin,
        bytes calldata _data
    ) external payable returns (uint256 bought);

    /**
     * @notice Check whether can handle an order execution
     * @param _inToken - Address of the input token
     * @param _outToken - Address of the output token
     * @param _amountIn - uint256 of the input token amount
     * @param _amountOutMin - uint256 of the min return amount of output token
     * @param _data - Bytes of arbitrary data
     * @return bool - Whether the execution can be handled or not
     */
    function canHandle(
        IERC20 _inToken,
        IERC20 _outToken,
        uint256 _amountIn,
        uint256 _amountOutMin,
        bytes calldata _data
    ) external view returns (bool);
}
