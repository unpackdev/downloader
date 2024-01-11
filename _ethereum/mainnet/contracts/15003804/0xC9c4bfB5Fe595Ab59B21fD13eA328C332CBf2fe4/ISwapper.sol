// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IOracle.sol";
import "./IExchange.sol";

/**
 * @notice Swapper interface
 * @dev This contract doesn't support native coins (e.g. ETH, AVAX, MATIC, etc) use wrapper tokens instead
 */
interface ISwapper {
    /**
     * @notice The list of supported DEXes
     * @dev This function is gas intensive
     */
    function getAllExchanges() external view returns (address[] memory);

    /**
     * @notice The list of main DEXes
     * @dev This function is gas intensive
     */
    function getMainExchanges() external view returns (address[] memory);

    /**
     * @notice Oracle to get prices from
     * @dev Is used combined with `slippage` in order to check swaps outcomes and reject if aren't acceptable
     */
    function oracle() external view returns (IOracle);

    /**
     * @notice Get max acceptable slippage
     * @dev Swaps will revert if actual output from swap is too far from oracle price
     */
    function maxSlippage() external view returns (uint256);

    /**
     * @notice Get *spot* quote
     * It will return the swap amount based on the current reserves of the best pair/path found (i.e. spot price).
     * @dev It shouldn't be used as oracle!!!
     */
    function getBestAmountIn(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_
    )
        external
        returns (
            uint256 _amountInMax,
            IExchange _exchange,
            bytes memory _path
        );

    /**
     * @notice Get *spot* quote
     * It will return the swap amount based on the current reserves of the best pair/path found (i.e. spot price).
     * @dev It shouldn't be used as oracle!!!
     */
    function getBestAmountOut(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    )
        external
        returns (
            uint256 _amountOutMin,
            IExchange _exchange,
            bytes memory _path
        );

    /**
     * @notice Perform an exact input swap
     */
    function swapExactInput(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        address _receiver
    ) external returns (uint256 _amountOut);

    /**
     * @notice Perform an exact input swap - will revert if there is no default routing
     */
    function swapExactInputWithDefaultRouting(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address _receiver
    ) external returns (uint256 _amountOut);

    /**
     * @notice Perform an exact output swap
     */
    function swapExactOutput(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_,
        address _receiver
    ) external returns (uint256 _amountIn);

    /**
     * @notice Perform an exact output swap - will revert if there is no default routing
     */
    function swapExactOutputWithDefaultRouting(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address receiver_
    ) external returns (uint256 _amountIn);
}
