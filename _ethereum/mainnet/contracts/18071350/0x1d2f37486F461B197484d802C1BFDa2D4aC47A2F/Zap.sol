// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./IPair.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./Babylonian.sol";

interface IToken {
    function setIsAddingLP(uint) external;
}

contract Zap is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IWETH public WETH;
    IUniswapV2Router02 public router;
    uint256 public constant MAX_INT = 2 ** 256 - 1;
    uint256 public constant MINIMUM_AMOUNT = 1000;
    uint256 public maxZapReverseRatio;
    address private routerAddress;
    address private WETHAddress;
    address public LPAddress;
    address public TokenAddress;

    receive() external payable {
        assert(msg.sender == WETHAddress);
    }

    constructor(
        address _WETHAddress,
        address _router,
        uint256 _maxZapReverseRatio
    ) {
        WETHAddress = _WETHAddress;
        WETH = IWETH(_WETHAddress);
        routerAddress = _router;
        router = IUniswapV2Router02(_router);
        maxZapReverseRatio = _maxZapReverseRatio;
    }

    function start(
        address _LPAddress,
        address _TokenAddress
    ) external onlyOwner {
        assert(LPAddress == address(0));
        LPAddress = _LPAddress;
        TokenAddress = _TokenAddress;
    }

    function updateMaxZapInverseRatio(
        uint256 _maxZapInverseRatio
    ) external onlyOwner {
        maxZapReverseRatio = _maxZapInverseRatio;
    }

    function zapInETH(
        address receiver
    ) external payable nonReentrant returns (uint, uint) {
        require(msg.value >= MINIMUM_AMOUNT, "Zap: Amount too low");

        WETH.deposit{value: msg.value}();

        address _TokenAddress = TokenAddress;
        address _WETHAddress = WETHAddress;

        address[] memory path = new address[](2);
        path[0] = _WETHAddress;
        path[1] = _TokenAddress;

        uint256 swapAmountIn;

        {
            address token0;
            address token1;
            if (_TokenAddress < _WETHAddress) {
                token0 = _TokenAddress;
                token1 = _WETHAddress;
            } else {
                token1 = _TokenAddress;
                token0 = _WETHAddress;
            }

            {
                (uint256 reserveA, uint256 reserveB, ) = IPair(LPAddress)
                    .getReserves();

                require(
                    (reserveA >= MINIMUM_AMOUNT) &&
                        (reserveB >= MINIMUM_AMOUNT),
                    "Zap: Reserves too low"
                );

                if (token0 == _WETHAddress) {
                    swapAmountIn = _calculateAmountToSwap(
                        msg.value,
                        reserveA,
                        reserveB
                    );
                    require(
                        reserveA / swapAmountIn >= maxZapReverseRatio,
                        "Zap: Quantity higher than limit"
                    );
                } else {
                    swapAmountIn = _calculateAmountToSwap(
                        msg.value,
                        reserveB,
                        reserveA
                    );
                    require(
                        reserveB / swapAmountIn >= maxZapReverseRatio,
                        "Zap: Quantity higher than limit"
                    );
                }
            }
        }

        _approveTokenIfNeeded(_WETHAddress);

        router.swapExactTokensForTokens(
            swapAmountIn,
            0,
            path,
            address(this),
            block.timestamp
        );

        _approveTokenIfNeeded(_TokenAddress);

        IToken(_TokenAddress).setIsAddingLP(1);
        (, , uint lpTokenReceived) = router.addLiquidity(
            path[0],
            path[1],
            IERC20(path[0]).balanceOf(address(this)),
            IERC20(path[1]).balanceOf(address(this)),
            1,
            1,
            receiver,
            block.timestamp
        );
        IToken(_TokenAddress).setIsAddingLP(2);

        uint wethBalance = WETH.balanceOf(address(this));
        if (wethBalance > 0) {
            WETH.withdraw(wethBalance);
            (bool success, ) = payable(msg.sender).call{value: wethBalance}("");
            require(
                success,
                "unable to send value, recipient may have reverted"
            );
        }

        return (lpTokenReceived, wethBalance);
    }

    function _approveTokenIfNeeded(address _token) private {
        if (IERC20(_token).allowance(address(this), routerAddress) < 1e24) {
            IERC20(_token).safeApprove(routerAddress, MAX_INT);
        }
    }

    function _calculateAmountToSwap(
        uint256 _token0AmountIn,
        uint256 _reserve0,
        uint256 _reserve1
    ) private view returns (uint256 amountToSwap) {
        uint256 halfToken0Amount = _token0AmountIn / 2;
        uint256 nominator = router.getAmountOut(
            halfToken0Amount,
            _reserve0,
            _reserve1
        );
        uint256 denominator = router.quote(
            halfToken0Amount,
            _reserve0 + halfToken0Amount,
            _reserve1 - nominator
        );

        amountToSwap =
            _token0AmountIn -
            Babylonian.sqrt(
                (halfToken0Amount * halfToken0Amount * nominator) / denominator
            );

        return amountToSwap;
    }
}
