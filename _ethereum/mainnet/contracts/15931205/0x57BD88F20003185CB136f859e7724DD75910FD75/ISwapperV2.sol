// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ISwapRouter.sol";

interface ISwapperV2 {

    ///////////////////////////////////////
    /// external function
    //////////////////////////////////////


    /**
     * @dev                TON -> WTON swap
     * @param _amount      TON amount to be swapped (input ton uint)
     */
    function tonToWton(uint256 _amount) external;

    /**
     * @dev                WTON -> TON swap
     * @param _amount      WTON amount to be swapped (input wton uint)
     */
    function wtonToTon(uint256 _amount) external;

    /**
     * @dev
     * @param params            params is swap information (recipient, path, amountIn, minimumAmountOut) More details are in the link. https://docs.uniswap.org/protocol/reference/periphery/interfaces/ISwapRouter
     * @param _wrapEth          if input the ETH, _wrapEth is true
     * @param _outputUnwrapEth  if output the ETH, _outputWrapEth is true
     * @param _inputWrapWTON    if input the TON, _inputWrapWTON is true
     * @param _outputUnwrapTON  if output get TON, _outputUnwrapTON is true
     */
    function exactInput(
        ISwapRouter.ExactInputParams memory params,
        bool _wrapEth,
        bool _outputUnwrapEth,
        bool _inputWrapWTON,
        bool _outputUnwrapTON
    )
        external
        payable
        returns (uint256 amountOut);

    /**
     * @dev
     * @param params            params is swap information (recipient, path, amountInMaximum, amountOut) More details are in the link. https://docs.uniswap.org/protocol/reference/periphery/interfaces/ISwapRouter
     * @param _wrapEth          if input the ETH, _wrapEth is true
     * @param _outputUnwrapEth  if output the ETH, _outputWrapEth is true
     * @param _inputWrapWTON    if input the TON, _inputWrapWTON is true
     * @param _outputUnwrapTON  if output get TON, _outputUnwrapTON is true
     */
    function exactOutput(
        ISwapRouter.ExactOutputParams memory params,
        bool _wrapEth,
        bool _outputUnwrapEth,
        bool _inputWrapWTON,
        bool _outputUnwrapTON
    )
        external
        payable
        returns (uint256 amountIn);

    /**
     * @dev
     * @param path             path indicates the path of the token being swapped.
     */
    function decodeLastPool(bytes memory path)
        external
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        );
}