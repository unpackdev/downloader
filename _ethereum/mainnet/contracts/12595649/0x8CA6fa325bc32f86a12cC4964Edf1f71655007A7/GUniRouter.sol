// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

import "./IGUniRouter.sol";
import "./IGUniPool.sol";
import "./IUniswapV3Pool.sol";
import "./IWETH.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./IUniswapV3SwapCallback.sol";
import "./IUniswapV3Factory.sol";
import "./LiquidityAmounts.sol";
import "./TickMath.sol";

contract GUniRouter is IGUniRouter, IUniswapV3SwapCallback {
    using Address for address payable;
    using SafeERC20 for IERC20;
    using TickMath for int24;
    IWETH public immutable weth;
    IUniswapV3Factory public immutable factory;

    constructor(IUniswapV3Factory _factory, IWETH _weth) {
        weth = _weth;
        factory = _factory;
    }

    // solhint-disable-next-line code-complexity
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external override {
        IUniswapV3Pool pool = IUniswapV3Pool(msg.sender);
        address token0 = pool.token0();
        address token1 = pool.token1();
        uint24 fee = pool.fee();

        require(
            msg.sender == factory.getPool(token0, token1, fee),
            "invalid uniswap pool"
        );

        if (amount0Delta > 0)
            IERC20(token0).safeTransfer(msg.sender, uint256(amount0Delta));
        else if (amount1Delta > 0)
            IERC20(token1).safeTransfer(msg.sender, uint256(amount1Delta));
    }

    function addLiquidity(
        IGUniPool pool,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    )
        external
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        (uint256 amount0In, uint256 amount1In, uint256 _mintAmount) =
            pool.getMintAmounts(amount0Max, amount1Max);
        require(
            amount0In >= amount0Min && amount1In >= amount1Min,
            "below min amounts"
        );
        if (amount0In > 0) {
            pool.token0().safeTransferFrom(
                msg.sender,
                address(this),
                amount0In
            );
        }
        if (amount1In > 0) {
            pool.token1().safeTransferFrom(
                msg.sender,
                address(this),
                amount1In
            );
        }

        return _deposit(pool, amount0In, amount1In, _mintAmount, receiver);
    }

    // solhint-disable-next-line code-complexity, function-max-lines
    function addLiquidityETH(
        IGUniPool pool,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    )
        external
        payable
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        (uint256 amount0In, uint256 amount1In, uint256 _mintAmount) =
            pool.getMintAmounts(amount0Max, amount1Max);
        require(
            amount0In >= amount0Min && amount1In >= amount1Min,
            "below min amounts"
        );

        if (isToken0Weth(address(pool.token0()), address(pool.token1()))) {
            require(
                amount0Max == msg.value,
                "mismatching amount of ETH forwarded"
            );
            if (amount0In > 0) {
                weth.deposit{value: amount0In}();
            }
            if (amount1In > 0) {
                pool.token1().safeTransferFrom(
                    msg.sender,
                    address(this),
                    amount1In
                );
            }
        } else {
            require(
                amount1Max == msg.value,
                "mismatching amount of ETH forwarded"
            );
            if (amount1In > 0) {
                weth.deposit{value: amount1In}();
            }
            if (amount0In > 0) {
                pool.token0().safeTransferFrom(
                    msg.sender,
                    address(this),
                    amount0In
                );
            }
        }

        (amount0, amount1, mintAmount) = _deposit(
            pool,
            amount0In,
            amount1In,
            _mintAmount,
            receiver
        );

        if (isToken0Weth(address(pool.token0()), address(pool.token1()))) {
            if (amount0Max > amount0In) {
                payable(msg.sender).sendValue(amount0Max - amount0In);
            }
        } else {
            if (amount1Max > amount1In) {
                payable(msg.sender).sendValue(amount1Max - amount1In);
            }
        }
    }

    // solhint-disable-next-line function-max-lines
    function rebalanceAndAddLiquidity(
        IGUniPool pool,
        uint256 amount0In,
        uint256 amount1In,
        bool zeroForOne,
        uint256 swapAmount,
        uint160 swapThreshold,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    )
        external
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        (uint256 amount0Use, uint256 amount1Use, uint256 _mintAmount) =
            _prepareRebalanceDeposit(
                pool,
                amount0In,
                amount1In,
                zeroForOne,
                swapAmount,
                swapThreshold
            );
        require(
            amount0Use >= amount0Min && amount1Use >= amount1Min,
            "below min amounts"
        );

        return _deposit(pool, amount0Use, amount1Use, _mintAmount, receiver);
    }

    // solhint-disable-next-line function-max-lines, code-complexity
    function rebalanceAndAddLiquidityETH(
        IGUniPool pool,
        uint256 amount0In,
        uint256 amount1In,
        bool zeroForOne,
        uint256 swapAmount,
        uint160 swapThreshold,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    )
        external
        payable
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        (uint256 amount0Use, uint256 amount1Use, uint256 _mintAmount) =
            _prepareAndRebalanceDepositETH(
                pool,
                amount0In,
                amount1In,
                zeroForOne,
                swapAmount,
                swapThreshold
            );
        require(
            amount0Use >= amount0Min && amount1Use >= amount1Min,
            "below min amounts"
        );

        (amount0, amount1, mintAmount) = _deposit(
            pool,
            amount0Use,
            amount1Use,
            _mintAmount,
            receiver
        );

        uint256 leftoverBalance =
            IERC20(address(weth)).balanceOf(address(this));
        if (leftoverBalance > 0) {
            weth.withdraw(leftoverBalance);
            payable(msg.sender).sendValue(leftoverBalance);
        }
    }

    function removeLiquidity(
        IGUniPool pool,
        uint256 burnAmount,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    )
        external
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        )
    {
        IERC20(address(pool)).safeTransferFrom(
            msg.sender,
            address(this),
            burnAmount
        );
        (amount0, amount1, liquidityBurned) = pool.burn(burnAmount, receiver);
        require(
            amount0 >= amount0Min && amount1 >= amount1Min,
            "received below minimum"
        );
    }

    // solhint-disable-next-line code-complexity, function-max-lines
    function removeLiquidityETH(
        IGUniPool pool,
        uint256 burnAmount,
        uint256 amount0Min,
        uint256 amount1Min,
        address payable receiver
    )
        external
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        )
    {
        bool wethToken0 =
            isToken0Weth(address(pool.token0()), address(pool.token1()));

        IERC20(address(pool)).safeTransferFrom(
            msg.sender,
            address(this),
            burnAmount
        );
        (amount0, amount1, liquidityBurned) = pool.burn(
            burnAmount,
            address(this)
        );
        require(
            amount0 >= amount0Min && amount1 >= amount1Min,
            "received below minimum"
        );

        if (wethToken0) {
            if (amount0 > 0) {
                weth.withdraw(amount0);
                receiver.sendValue(amount0);
            }
            if (amount1 > 0) {
                pool.token1().safeTransfer(receiver, amount1);
            }
        } else {
            if (amount1 > 0) {
                weth.withdraw(amount1);
                receiver.sendValue(amount1);
            }
            if (amount0 > 0) {
                pool.token0().safeTransfer(receiver, amount0);
            }
        }
    }

    function _deposit(
        IGUniPool pool,
        uint256 amount0In,
        uint256 amount1In,
        uint256 _mintAmount,
        address receiver
    )
        internal
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        if (amount0In > 0) {
            pool.token0().safeIncreaseAllowance(address(pool), amount0In);
        }
        if (amount1In > 0) {
            pool.token1().safeIncreaseAllowance(address(pool), amount1In);
        }

        (amount0, amount1, ) = pool.mint(_mintAmount, receiver);
        require(
            amount0 == amount0In && amount1 == amount1In,
            "unexpected amounts deposited"
        );
        mintAmount = _mintAmount;
    }

    function _prepareRebalanceDeposit(
        IGUniPool pool,
        uint256 amount0In,
        uint256 amount1In,
        bool zeroForOne,
        uint256 swapAmount,
        uint160 swapThreshold
    )
        internal
        returns (
            uint256 amount0Use,
            uint256 amount1Use,
            uint256 mintAmount
        )
    {
        if (amount0In > 0) {
            pool.token0().safeTransferFrom(
                msg.sender,
                address(this),
                amount0In
            );
        }
        if (amount1In > 0) {
            pool.token1().safeTransferFrom(
                msg.sender,
                address(this),
                amount1In
            );
        }

        _swap(pool, zeroForOne, int256(swapAmount), swapThreshold);

        uint256 amount0Max = pool.token0().balanceOf(address(this));
        uint256 amount1Max = pool.token1().balanceOf(address(this));

        (amount0Use, amount1Use, mintAmount) = _getAmountsAndRefund(
            pool,
            amount0Max,
            amount1Max
        );
    }

    // solhint-disable-next-line code-complexity, function-max-lines
    function _prepareAndRebalanceDepositETH(
        IGUniPool pool,
        uint256 amount0In,
        uint256 amount1In,
        bool zeroForOne,
        uint256 swapAmount,
        uint160 swapThreshold
    )
        internal
        returns (
            uint256 amount0Use,
            uint256 amount1Use,
            uint256 mintAmount
        )
    {
        bool wethToken0 =
            isToken0Weth(address(pool.token0()), address(pool.token1()));

        if (amount0In > 0) {
            if (wethToken0) {
                require(
                    amount0In == msg.value,
                    "mismatching amount of ETH forwarded"
                );
                weth.deposit{value: amount0In}();
            } else {
                pool.token0().safeTransferFrom(
                    msg.sender,
                    address(this),
                    amount0In
                );
            }
        }

        if (amount1In > 0) {
            if (wethToken0) {
                pool.token1().safeTransferFrom(
                    msg.sender,
                    address(this),
                    amount1In
                );
            } else {
                require(
                    amount1In == msg.value,
                    "mismatching amount of ETH forwarded"
                );
                weth.deposit{value: amount1In}();
            }
        }

        _swap(pool, zeroForOne, int256(swapAmount), swapThreshold);

        uint256 amount0Max = pool.token0().balanceOf(address(this));
        uint256 amount1Max = pool.token1().balanceOf(address(this));

        (amount0Use, amount1Use, mintAmount) = _getAmountsAndRefundExceptETH(
            pool,
            amount0Max,
            amount1Max,
            wethToken0
        );
    }

    function _swap(
        IGUniPool pool,
        bool zeroForOne,
        int256 swapAmount,
        uint160 swapThreshold
    ) internal {
        pool.pool().swap(
            address(this),
            zeroForOne,
            swapAmount,
            swapThreshold,
            ""
        );
    }

    function _getAmountsAndRefund(
        IGUniPool pool,
        uint256 amount0Max,
        uint256 amount1Max
    )
        internal
        returns (
            uint256 amount0In,
            uint256 amount1In,
            uint256 mintAmount
        )
    {
        (amount0In, amount1In, mintAmount) = pool.getMintAmounts(
            amount0Max,
            amount1Max
        );
        if (amount0Max > amount0In) {
            pool.token0().safeTransfer(msg.sender, amount0Max - amount0In);
        }
        if (amount1Max > amount1In) {
            pool.token1().safeTransfer(msg.sender, amount1Max - amount1In);
        }
    }

    function _getAmountsAndRefundExceptETH(
        IGUniPool pool,
        uint256 amount0Max,
        uint256 amount1Max,
        bool wethToken0
    )
        internal
        returns (
            uint256 amount0In,
            uint256 amount1In,
            uint256 mintAmount
        )
    {
        (amount0In, amount1In, mintAmount) = pool.getMintAmounts(
            amount0Max,
            amount1Max
        );

        if (amount0Max > amount0In && !wethToken0) {
            pool.token0().safeTransfer(msg.sender, amount0Max - amount0In);
        } else if (amount1Max > amount1In && wethToken0) {
            pool.token1().safeTransfer(msg.sender, amount1Max - amount1In);
        }
    }

    function isToken0Weth(address token0, address token1)
        public
        view
        returns (bool wethToken0)
    {
        if (token0 == address(weth)) {
            wethToken0 = true;
        } else if (token1 == address(weth)) {
            wethToken0 = false;
        } else {
            revert("one pool token must be WETH");
        }
    }

    function getPoolUnderlyingBalances(IGUniPool pool)
        public
        view
        override
        returns (uint256 amount0, uint256 amount1)
    {
        IUniswapV3Pool uniPool = pool.pool();
        (uint128 liquidity, , , , ) = uniPool.positions(pool.getPositionID());
        (uint160 sqrtPriceX96, , , , , , ) = uniPool.slot0();
        uint160 lowerSqrtPrice = pool.lowerTick().getSqrtRatioAtTick();
        uint160 upperSqrtPrice = pool.upperTick().getSqrtRatioAtTick();
        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96,
                lowerSqrtPrice,
                upperSqrtPrice,
                liquidity
            );
    }

    function getUnderlyingBalances(
        IGUniPool pool,
        address account,
        uint256 balance
    ) external view override returns (uint256 amount0, uint256 amount1) {
        (uint256 gross0, uint256 gross1) = getPoolUnderlyingBalances(pool);
        balance = balance == 0 ? pool.balanceOf(account) : balance;
        uint256 supply = pool.totalSupply();
        amount0 = FullMath.mulDiv(gross0, balance, supply);
        amount1 = FullMath.mulDiv(gross1, balance, supply);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}
