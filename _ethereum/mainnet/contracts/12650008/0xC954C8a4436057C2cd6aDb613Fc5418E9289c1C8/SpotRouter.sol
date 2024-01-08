// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./UniswapStyleLib.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./IWETH.sol";
import "./BaseRouter.sol";

/// @title Router for spot trading on uniswap and sushiswap jointly
/// the paramater amms represents the choice of amm pair along the route
/// it is a bytes32 value where amms[i] == 0 for uniswap and amms[i] == 1 for sushi
contract SpotRouter is BaseRouter {
    using SafeERC20 for IERC20;
    address public immutable WETH;
    event SpotTrade(
        address indexed trader,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount
    );

    constructor(
        address _WETH,
        address _amm1Factory,
        address _amm2Factory,
        address _amm3Factory,
        bytes32 _amm1InitHash,
        bytes32 _amm2InitHash,
        bytes32 _amm3InitHash
    )
        UniswapStyleLib(
            _amm1Factory,
            _amm2Factory,
            _amm3Factory,
            _amm1InitHash,
            _amm2InitHash,
            _amm3InitHash
        )
    {
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        bytes32 amms,
        address[] calldata tokens,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        address[] memory pairs;
        (amounts, pairs) = UniswapStyleLib._getAmountsOut(
            amountIn,
            amms,
            tokens
        );

        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "SpotRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        IERC20(tokens[0]).safeTransferFrom(msg.sender, pairs[0], amounts[0]);

        _swap(amounts, pairs, tokens, to);
        emit SpotTrade(msg.sender, tokens[0], tokens[tokens.length - 1], amounts[0], amounts[amounts.length - 1]);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        bytes32 amms,
        address[] calldata tokens,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        address[] memory pairs;
        (amounts, pairs) = UniswapStyleLib._getAmountsIn(
            amountOut,
            amms,
            tokens
        );

        require(
            amounts[0] <= amountInMax,
            "SpotRouter: EXCESSIVE_INPUT_AMOUNT"
        );

        IERC20(tokens[0]).safeTransferFrom(msg.sender, pairs[0], amounts[0]);

        _swap(amounts, pairs, tokens, to);
        emit SpotTrade(msg.sender, tokens[0], tokens[tokens.length - 1], amounts[0], amounts[amounts.length - 1]);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        bytes32 amms,
        address[] calldata tokens,
        address to,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256[] memory amounts) {
        require(tokens[0] == WETH, "SpotRouter: INVALID_PATH");

        address[] memory pairs;
        (amounts, pairs) = UniswapStyleLib._getAmountsOut(
            msg.value,
            amms,
            tokens
        );
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "SpotRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(pairs[0], msg.value));

        _swap(amounts, pairs, tokens, to);
        emit SpotTrade(msg.sender, tokens[0], tokens[tokens.length - 1], amounts[0], amounts[amounts.length - 1]);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        bytes32 amms,
        address[] calldata tokens,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        require(tokens[tokens.length - 1] == WETH, "SpotRouter: INVALID_PATH");

        address[] memory pairs;
        (amounts, pairs) = UniswapStyleLib._getAmountsIn(
            amountOut,
            amms,
            tokens
        );

        require(
            amounts[0] <= amountInMax,
            "SpotRouter: EXCESSIVE_INPUT_AMOUNT"
        );

        IERC20(tokens[0]).safeTransferFrom(msg.sender, pairs[0], amounts[0]);

        _swap(amounts, pairs, tokens, address(this));

        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        Address.sendValue(payable(to), amounts[amounts.length - 1]);
        emit SpotTrade(msg.sender, tokens[0], tokens[tokens.length - 1], amounts[0], amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        bytes32 amms,
        address[] calldata tokens,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        require(tokens[tokens.length - 1] == WETH, "SpotRouter: INVALID_PATH");

        address[] memory pairs;
        (amounts, pairs) = UniswapStyleLib._getAmountsOut(
            amountIn,
            amms,
            tokens
        );

        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "SpotRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        IERC20(tokens[0]).safeTransferFrom(msg.sender, pairs[0], amounts[0]);
        _swap(amounts, pairs, tokens, address(this));

        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        Address.sendValue(payable(to), amounts[amounts.length - 1]);
        emit SpotTrade(msg.sender, tokens[0], tokens[tokens.length - 1], amounts[0], amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        bytes32 amms,
        address[] calldata tokens,
        address to,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256[] memory amounts) {
        require(tokens[0] == WETH, "SpotRouter: INVALID_PATH");

        address[] memory pairs;
        (amounts, pairs) = UniswapStyleLib._getAmountsIn(
            amountOut,
            amms,
            tokens
        );

        require(amounts[0] <= msg.value, "SpotRouter: EXCESSIVE_INPUT_AMOUNT");

        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(pairs[0], amounts[0]));

        _swap(amounts, pairs, tokens, to);
        // refund dust eth, if any
        if (msg.value > amounts[0])
            Address.sendValue(payable(msg.sender), msg.value - amounts[0]);
        emit SpotTrade(msg.sender, tokens[0], tokens[tokens.length - 1], amounts[0], amounts[amounts.length - 1]);
    }

    function getAmountsOut(
        uint256 inAmount,
        bytes32 amms,
        address[] calldata tokens
    ) external view returns (uint256[] memory amounts) {
        (amounts, ) = UniswapStyleLib._getAmountsOut(inAmount, amms, tokens);
    }

    function getAmountsIn(
        uint256 outAmount,
        bytes32 amms,
        address[] calldata tokens
    ) external view returns (uint256[] memory amounts) {
        (amounts, ) = UniswapStyleLib._getAmountsIn(outAmount, amms, tokens);
    }
}
