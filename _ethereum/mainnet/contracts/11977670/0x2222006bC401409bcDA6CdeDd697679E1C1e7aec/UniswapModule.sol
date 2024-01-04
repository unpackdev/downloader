pragma solidity 0.6.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router.sol";

contract UniswapModule {
    using SafeERC20 for IERC20;
    function getAmountsOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        address _uniswapRouter) internal view returns (uint256 amountsOut) {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        IUniswapV2Router uniswapRouter = IUniswapV2Router(_uniswapRouter);
        uint256[] memory amountsOutArr = uniswapRouter.getAmountsOut(_amountIn, path);
        return amountsOutArr[1];
    }

    function swapExactTokensForTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _deadline,
        address _uniswapRouter) internal returns (uint256[] memory) {
        uint256[] memory amounts;
        address[] memory path = new address[](2);
        IUniswapV2Router uniswapRouter = IUniswapV2Router(_uniswapRouter);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        IERC20(_tokenIn).safeApprove(_uniswapRouter, _amountIn);
        amounts = uniswapRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            address(this),
            _deadline
        );
        return amounts;
    }

    function swapExactETHForTokens(
        address _tokenOut,
        uint256 _amountOutMin,
        uint256 _deadline,
        address _uniswapRouter) internal returns (uint256[] memory) {
        uint256[] memory amounts;
        address[] memory path = new address[](2);
        IUniswapV2Router uniswapRouter = IUniswapV2Router(_uniswapRouter);
        path[0] = uniswapRouter.WETH();
        path[1] = _tokenOut;
        amounts = uniswapRouter.swapExactETHForTokens{value: msg.value}(
            _amountOutMin,
            path,
            address(this),
            _deadline
        );
        return amounts;
    }

    function swapTokensThroughETH(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _deadline,
        address _uniswapRouter) internal returns (uint256[] memory) {
        uint256[] memory amounts;
        address[] memory path = new address[](3);
        IUniswapV2Router uniswapRouter = IUniswapV2Router(_uniswapRouter);
        path[0] = _tokenIn;
        path[1] = uniswapRouter.WETH();
        path[2] = _tokenOut;
        IERC20(_tokenIn).safeApprove(_uniswapRouter, _amountIn);
        amounts = uniswapRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            address(this),
            _deadline
        );
        return amounts;
    }

    function getAmountOut(uint _amountIn, uint _reserveIn, uint _reserveOut, address _uniswapRouter) internal returns (uint amountOut) {
        IUniswapV2Router uniswapRouter = IUniswapV2Router(_uniswapRouter);
        return uniswapRouter.getAmountOut(_amountIn, _reserveIn, _reserveOut);
    }

    function getAmountIn(uint _amountOut, uint _reserveIn, uint _reserveOut, address _uniswapRouter) internal returns (uint amountIn) {
        IUniswapV2Router uniswapRouter = IUniswapV2Router(_uniswapRouter);
        return uniswapRouter.getAmountIn(_amountOut, _reserveIn, _reserveOut);
    }
}
