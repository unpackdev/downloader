pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./TransferHelper.sol";
import "./ISwapRouter.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";

contract Swap is Initializable, OwnableUpgradeable {
    uint256 public swapFee;
    address public feeWallet;

    event SwappedV2(
        address indexed sender,
        address indexed tokenIn,
        address indexed tokenOut,
        address router,
        uint256 amountIn,
        uint256 amountOut
    );

    event SwappedToETHV2(
        address indexed sender,
        address indexed tokenIn,
        address router,
        uint256 amountIn,
        uint256 amountOut
    );

    event SwappedFromETHV2(
        address indexed sender,
        address indexed tokenOut,
        address router,
        uint256 amountIn,
        uint256 amountOut
    );

    receive() external payable {}

    function initialize(address _feeWallet, uint256 _swapFee)
        public
        initializer
    {
        __Ownable_init();
        feeWallet = _feeWallet;
        swapFee = _swapFee;
    }

    function changeFeeWallet(address _feeWallet) external onlyOwner {
        require(_feeWallet != address(0), "Fee wallet cannot be zero address");
        feeWallet = _feeWallet;
    }

    function changeSwapFee(uint256 _feePercent) external onlyOwner {
        require(_feePercent <= 10000, "Fee percent cannot be greater than 100");
        swapFee = _feePercent;
    }

    function singleSwapV2(
        address router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 slippage
    ) external {
        require(
            tokenIn != tokenOut,
            "Token in and token out cannot be the same"
        );
        require(amountIn > 0, "Amount in cannot be zero");
        require(
            slippage <= 10000,
            "Slippage cannot be greater than 100% (10000)"
        );
        require(
            tokenIn != address(0) ||
                tokenOut != address(0) ||
                router != address(0),
            "Token in, token out or router cannot be zero address"
        );
        TransferHelper.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            amountIn
        );
        TransferHelper.safeApprove(tokenIn, router, amountIn);

        uint256 fee = (amountIn * swapFee) / 10000;
        uint256 amountInFinal = amountIn - fee;

        uint256 amountOutMin = _slippageCalcV2(
            router,
            tokenIn,
            tokenOut,
            amountInFinal,
            slippage
        );

        address[] memory path = _makePathV2(router, tokenIn, tokenOut);
        uint256 initialBalance = IERC20(tokenOut).balanceOf(address(this));
        IUniswapV2Router02(router).swapExactTokensForTokens(
            amountInFinal,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
        uint256 finalBalance = IERC20(tokenOut).balanceOf(address(this));
        TransferHelper.safeTransfer(
            tokenOut,
            msg.sender,
            finalBalance - initialBalance
        );
        if (fee > 0) {
            if (tokenIn == IUniswapV2Router02(router).WETH()) {
                TransferHelper.safeTransfer(
                    IUniswapV2Router02(router).WETH(),
                    feeWallet,
                    fee
                );
            } else {
                address[] memory path2 = _makePathV2(
                    router,
                    tokenIn,
                    IUniswapV2Router02(router).WETH()
                );
                uint256[] memory amounts = IUniswapV2Router02(router)
                    .swapExactTokensForETH(
                        fee,
                        0,
                        path2,
                        address(this),
                        block.timestamp
                    );
                TransferHelper.safeTransferETH(feeWallet, amounts[1]);
            }
        }

        emit SwappedV2(
            msg.sender,
            tokenIn,
            tokenOut,
            router,
            amountIn,
            finalBalance - initialBalance
        );
    }

    function singleSwapV2FromETH(
        address router,
        address tokenOut,
        uint256 slippage
    ) external payable {
        require(msg.value > 0, "Amount in cannot be zero");
        require(
            slippage <= 10000,
            "Slippage cannot be greater than 100% (10000)"
        );
        require(
            tokenOut != address(0) || router != address(0),
            "Token in, token out or router cannot be zero address"
        );

        uint256 fee = (msg.value * swapFee) / 10000;
        uint256 amountIn = msg.value - fee;
        TransferHelper.safeTransferETH(feeWallet, fee);

        if (tokenOut == IUniswapV2Router02(router).WETH()) {
            IWETH(IUniswapV2Router02(router).WETH()).deposit{value: amountIn}();
            TransferHelper.safeTransfer(
                IUniswapV2Router02(router).WETH(),
                msg.sender,
                amountIn
            );
            emit SwappedFromETHV2(
                msg.sender,
                tokenOut,
                router,
                msg.value,
                amountIn
            );
        } else {
            uint256 amountOutMin = _slippageCalcV2(
                router,
                IUniswapV2Router02(router).WETH(),
                tokenOut,
                amountIn,
                slippage
            );
            address[] memory path = _makePathV2(
                router,
                IUniswapV2Router02(router).WETH(),
                tokenOut
            );
            uint256 initialBalance = IERC20(tokenOut).balanceOf(address(this));
            IUniswapV2Router02(router).swapExactETHForTokens{value: amountIn}(
                amountOutMin,
                path,
                address(this),
                block.timestamp
            );
            uint256 finalBalance = IERC20(tokenOut).balanceOf(address(this));
            TransferHelper.safeTransfer(
                tokenOut,
                msg.sender,
                finalBalance - initialBalance
            );
            emit SwappedFromETHV2(
                msg.sender,
                tokenOut,
                router,
                msg.value,
                finalBalance - initialBalance
            );
        }
    }

    function singleSwapV2ToETH(
        address router,
        address tokenIn,
        uint256 amountIn,
        uint256 slippage
    ) external {
        require(amountIn > 0, "Amount in cannot be zero");
        require(
            slippage <= 10000,
            "Slippage cannot be greater than 100% (10000)"
        );
        require(
            tokenIn != address(0) || router != address(0),
            "Token in, token out or router cannot be zero address"
        );

        TransferHelper.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            amountIn
        );

        if (tokenIn == IUniswapV2Router02(router).WETH()) {
            IWETH(IUniswapV2Router02(router).WETH()).withdraw(amountIn);
            uint256 fee = (amountIn * swapFee) / 10000;
            TransferHelper.safeTransferETH(feeWallet, fee);
            TransferHelper.safeTransferETH(msg.sender, amountIn - fee);
            emit SwappedToETHV2(
                msg.sender,
                tokenIn,
                router,
                amountIn,
                amountIn - fee
            );
        } else {
            uint256 amountOutMin = _slippageCalcV2(
                router,
                tokenIn,
                IUniswapV2Router02(router).WETH(),
                amountIn,
                slippage
            );

            TransferHelper.safeApprove(tokenIn, router, amountIn);

            address[] memory path = _makePathV2(
                router,
                tokenIn,
                IUniswapV2Router02(router).WETH()
            );

            uint256[] memory amounts = IUniswapV2Router02(router)
                .swapExactTokensForETH(
                    amountIn,
                    amountOutMin,
                    path,
                    address(this),
                    block.timestamp
                );

            uint256 fee = (amounts[1] * swapFee) / 10000;
            TransferHelper.safeTransferETH(feeWallet, fee);
            TransferHelper.safeTransferETH(msg.sender, amounts[1] - fee);
            emit SwappedToETHV2(
                msg.sender,
                tokenIn,
                router,
                amountIn,
                amounts[1] - fee
            );
        }
    }

    function estimateSwapV2(
        address router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256, uint256) {
        uint256 amountOutEstimated = _estimateSwapV2(
            router,
            tokenIn,
            tokenOut,
            amountIn
        );

        uint256 fee = (amountOutEstimated * swapFee) / 10000;
        uint256 amountOut = amountOutEstimated - fee;

        return (fee, amountOut);
    }

    function getWETHV2(address router) external pure returns (address) {
        require(router != address(0), "Router cannot be zero address");
        return IUniswapV2Router02(router).WETH();
    }

    function _slippageCalcV2(
        address router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 slippage
    ) internal view returns (uint256) {
        uint256 estimatedAmountOut = _estimateSwapV2(
            router,
            tokenIn,
            tokenOut,
            amountIn
        );
        return estimatedAmountOut - (estimatedAmountOut * slippage) / 10000;
    }

    function _estimateSwapV2(
        address router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal view returns (uint256) {
        address[] memory path;
        if (
            tokenIn == IUniswapV2Router02(router).WETH() ||
            tokenOut == IUniswapV2Router02(router).WETH()
        ) {
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
            uint256[] memory amounts = IUniswapV2Router02(router).getAmountsOut(
                amountIn,
                path
            );
            return amounts[1];
        } else {
            path = new address[](3);
            path[0] = tokenIn;
            path[1] = IUniswapV2Router02(router).WETH();
            path[2] = tokenOut;
            uint256[] memory amounts = IUniswapV2Router02(router).getAmountsOut(
                amountIn,
                path
            );
            return amounts[2];
        }
    }

    function _makePathV2(
        address router,
        address tokenIn,
        address tokenOut
    ) internal pure returns (address[] memory) {
        address[] memory path;
        if (
            tokenIn == IUniswapV2Router02(router).WETH() ||
            tokenOut == IUniswapV2Router02(router).WETH()
        ) {
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
        } else {
            path = new address[](3);
            path[0] = tokenIn;
            path[1] = IUniswapV2Router02(router).WETH();
            path[2] = tokenOut;
        }
        return path;
    }
}
