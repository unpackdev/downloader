//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ISwapRouter.sol";
import "./IERC20.sol";
import "./ESASXErrors.sol";

/**
 * @title Asymetrix Protocol V2 UniswapWrapper contract
 * @author Asymetrix Protocol Inc Team
 * @notice Implements helper functions for Uniswap V3 interactions.
 */
contract UniswapWrapper {
    ISwapRouter public immutable router;
    address public immutable weth;

    uint16 public constant DEADLINE = 1000;

    /**
     * @notice Сonstructor of this UniswapWrapper contract.
     * @dev Sets _router, uniswap router contract address, and _weth, WETH token contract address.
     * @param _router uniswap router contract address.
     * @param _weth WETH token contract address.
     */
    constructor(address _router, address _weth) {
        if (_router == address(0)) revert ESASXErrors.InvalidAddress();
        if (_weth == address(0)) revert ESASXErrors.InvalidAddress();

        router = ISwapRouter(_router);
        weth = _weth;
    }

    /**
     * @notice Swaps ETH for out tokens using Uniswap V3.
     * @param _tokenOut An address of a token out.
     * @param _fee A fee of the pool.
     * @param _amountIn An amount of ETH to swap.
     * @param _amountOutMinimum A min amount of a token out to receive.
     * @return amountOut An amount of a token out to receive.
     */
    function swapSingle(
        address _tokenOut,
        uint24 _fee,
        uint256 _amountIn,
        uint256 _amountOutMinimum
    ) external payable returns (uint256) {
        if (msg.value != _amountIn) revert ESASXErrors.WrongETHAmount();

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: weth,
            tokenOut: _tokenOut,
            fee: _fee,
            recipient: msg.sender,
            deadline: block.timestamp + DEADLINE,
            amountIn: _amountIn,
            amountOutMinimum: _amountOutMinimum,
            sqrtPriceLimitX96: 0
        });

        return router.exactInputSingle{ value: msg.value }(params);
    }
}
