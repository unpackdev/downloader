// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";

import "./IUniswapV3MintCallback.sol";
import "./IUniswapV3SwapCallback.sol";
import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./FullMath.sol";

import "./TransferHelper.sol";
import "./ISwapRouter.sol";
import "./LiquidityAmounts.sol";
import "./OracleLibrary.sol";

import "./ICHIManager.sol";
import "./ICHIDepositCallBack.sol";

contract CHIVault is
    ICHIVault,
    IUniswapV3MintCallback,
    IUniswapV3SwapCallback,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event Deposit(
        uint256 indexed yangId,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    event Withdraw(
        uint256 indexed yangId,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    event CollectFee(uint256 feesFromPool0, uint256 feesFromPool1);

    event Swap(
        address from,
        address to,
        uint256 amountIn,
        uint256 amountOut,
        uint256 amountOutMin
    );

    IUniswapV3Pool public pool;
    ICHIManager public CHIManager;

    ISwapRouter public immutable router;
    IERC20 public immutable token0;
    IERC20 public immutable token1;
    uint24 public immutable fee;
    int24 public immutable tickSpacing;

    uint256 private _accruedProtocolFees0;
    uint256 private _accruedProtocolFees1;
    uint256 private _protocolFee;
    uint256 private FEE_BASE = 1e6;
    uint256 private scaleRate = 1e18;

    // total shares
    uint256 private _totalSupply;

    using EnumerableSet for EnumerableSet.Bytes32Set;
    EnumerableSet.Bytes32Set private _rangeSet;

    // vault accruedfees
    uint256 private _accruedCollectFees0;
    uint256 private _accruedCollectFees1;

    constructor(
        address _pool,
        address _manager,
        uint256 _protocolFee_
    ) {
        pool = IUniswapV3Pool(_pool);
        token0 = IERC20(pool.token0());
        token1 = IERC20(pool.token1());
        fee = pool.fee();
        tickSpacing = pool.tickSpacing();

        CHIManager = ICHIManager(_manager);
        router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

        _protocolFee = _protocolFee_;

        require(_protocolFee < FEE_BASE, "f");
    }

    modifier onlyManager() {
        require(msg.sender == address(CHIManager), "m");
        _;
    }

    function accruedProtocolFees0()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _accruedProtocolFees0;
    }

    function accruedProtocolFees1()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _accruedProtocolFees1;
    }

    function accruedCollectFees0() external view override returns (uint256) {
        return _accruedCollectFees0;
    }

    function accruedCollectFees1() external view override returns (uint256) {
        return _accruedCollectFees1;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function getRangeCount() external view virtual override returns (uint256) {
        return _rangeSet.length();
    }

    function feeTier() public view override returns (uint24) {
        return fee;
    }

    function positionAmounts(int24 tickLower, int24 tickUpper)
        public
        view
        returns (uint256 amount0, uint256 amount1)
    {
        bytes32 positionKey = keccak256(
            abi.encodePacked(address(this), tickLower, tickUpper)
        );
        (uint128 liquidity, , , uint128 tokensOwed0, uint128 tokensOwed1) = pool
            .positions(positionKey);
        (amount0, amount1) = _amountsForLiquidity(
            tickLower,
            tickUpper,
            liquidity
        );
        amount0 = amount0.add(uint256(tokensOwed0));
        amount1 = amount1.add(uint256(tokensOwed1));
    }

    function _encode(int24 _a, int24 _b) internal pure returns (bytes32 x) {
        assembly {
            mstore(0x10, _b)
            mstore(0x0, _a)
            x := mload(0x10)
        }
    }

    function _decode(bytes32 x) internal pure returns (int24 a, int24 b) {
        assembly {
            b := x
            mstore(0x10, x)
            a := mload(0)
        }
    }

    function getRange(uint256 index)
        external
        view
        virtual
        override
        returns (int24 tickLower, int24 tickUpper)
    {
        (tickLower, tickUpper) = _decode(_rangeSet.at(index));
    }

    function addRange(int24 tickLower, int24 tickUpper)
        external
        override
        onlyManager
    {
        _checkTicks(tickLower, tickUpper);
        (uint256 amount0, uint256 amount1) = positionAmounts(
            tickLower,
            tickUpper
        );
        require(amount0 == 0, "a0");
        require(amount1 == 0, "a0");
        _rangeSet.add(_encode(tickLower, tickUpper));
    }

    function removeRange(int24 tickLower, int24 tickUpper)
        external
        override
        onlyManager
    {
        _checkTicks(tickLower, tickUpper);
        (uint256 amount0, uint256 amount1) = positionAmounts(
            tickLower,
            tickUpper
        );
        require(amount0 == 0, "a0");
        require(amount1 == 0, "a0");
        _rangeSet.remove(_encode(tickLower, tickUpper));
    }

    function getTotalLiquidityAmounts()
        public
        view
        override
        returns (uint256 total0, uint256 total1)
    {
        for (uint256 i = 0; i < _rangeSet.length(); i++) {
            (int24 _tickLower, int24 _tickUpper) = _decode(_rangeSet.at(i));
            (uint256 amount0, uint256 amount1) = positionAmounts(
                _tickLower,
                _tickUpper
            );
            total0 = total0.add(amount0);
            total1 = total1.add(amount1);
        }
    }

    function getTotalAmounts()
        public
        view
        override
        returns (uint256 total0, uint256 total1)
    {
        (total0, total1) = getTotalLiquidityAmounts();
        total0 = total0.add(balanceToken0());
        total1 = total1.add(balanceToken1());
    }

    /// @dev Deposit with single token
    /// @param yangId YANG ID
    /// @param zeroForOne Deposit is token0 or token1
    /// @param exactAmount Exact amount that swap to another token
    /// @param maxTokenAmount The maximum value of user cost
    /// @param minShares The Minimum value of shares that user obtain
    function depositSingle(
        uint256 yangId,
        bool zeroForOne,
        uint256 exactAmount,
        uint256 maxTokenAmount,
        uint256 minShares
    )
        external
        override
        nonReentrant
        onlyManager
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        )
    {
        IERC20 tokenIn = zeroForOne ? token0 : token1;
        (int256 swapAmount0, int256 swapAmount1) = _swapTokenSingle(
            true,
            tokenIn,
            zeroForOne,
            exactAmount
        );
        // update pool
        _updateLiquidity();

        uint256 leftTokenIn = maxTokenAmount.sub(exactAmount);

        (uint256 total0, uint256 total1) = getTotalAmounts();

        if (zeroForOne) {
            (shares, amount0, amount1) = _calcSharesAndAmounts(
                total0,
                total1.sub(uint256(-swapAmount1)),
                leftTokenIn,
                uint256(-swapAmount1)
            );
        } else {
            (shares, amount0, amount1) = _calcSharesAndAmounts(
                total0.sub(uint256(-swapAmount0)),
                total1,
                uint256(-swapAmount0),
                leftTokenIn
            );
        }

        // require the swap amount is exact
        require(
            (zeroForOne && amount1 == uint256(-swapAmount1)) ||
                (!zeroForOne && amount0 == uint256(-swapAmount0)),
            "stm"
        );

        require(
            zeroForOne ? (amount0 <= leftTokenIn) : (amount1 <= leftTokenIn),
            "over"
        );
        require(shares >= minShares, "s");

        ICHIDepositCallBack(msg.sender).CHIDepositCallback(
            tokenIn,
            zeroForOne ? amount0 : amount1,
            IERC20(0),
            0,
            address(this)
        );

        _mint(shares);
        emit Deposit(yangId, shares, amount0, amount1);
    }

    function _swapTokenSingle(
        bool isDeposit,
        IERC20 tokenIn,
        bool zeroForOne,
        uint256 exactAmount
    ) internal returns (int256 swapAmount0, int256 swapAmount1) {
        // swap token.
        (swapAmount0, swapAmount1) = pool.swap(
            address(this),
            zeroForOne,
            toInt256(exactAmount),
            zeroForOne
                ? TickMath.MIN_SQRT_RATIO + 1
                : TickMath.MAX_SQRT_RATIO - 1,
            abi.encode(
                SwapCallbackData({
                    isDeposit: isDeposit,
                    tokenIn: address(tokenIn),
                    tokenOut: tokenIn == token0
                        ? address(token1)
                        : address(token0)
                })
            )
        );
    }

    function deposit(
        uint256 yangId,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min
    )
        external
        override
        nonReentrant
        onlyManager
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        )
    {
        require(amount0Desired > 0 || amount1Desired > 0, "a0a1");

        // update pool
        _updateLiquidity();

        (uint256 total0, uint256 total1) = getTotalAmounts();
        (shares, amount0, amount1) = _calcSharesAndAmounts(
            total0,
            total1,
            amount0Desired,
            amount1Desired
        );
        require(shares > 0, "s");
        require(amount0 >= amount0Min, "A0M");
        require(amount1 >= amount1Min, "A1M");

        // Pull in tokens from sender
        ICHIDepositCallBack(msg.sender).CHIDepositCallback(
            token0,
            amount0,
            token1,
            amount1,
            address(this)
        );

        _mint(shares);
        emit Deposit(yangId, shares, amount0, amount1);
    }

    /// @dev Withdraw with single token
    /// @param yangId YANG ID
    /// @param zeroForOne Withdraw token0 or token1
    /// @param shares The share amount user want
    /// @param amountOutMin The Minimum amount of token withdrawal
    /// @param to The receiver of token
    function withdrawSingle(
        uint256 yangId,
        bool zeroForOne,
        uint256 shares,
        uint256 amountOutMin,
        address to
    ) external override nonReentrant onlyManager returns (uint256 amount) {
        require(shares > 0, "s");
        require(to != address(0) && to != address(this), "to");

        (uint256 withdrawal0, uint256 withdrawal1) = _withdrawShare(
            shares,
            0,
            0
        );

        IERC20 tokenIn = zeroForOne ? token0 : token1;
        (int256 swapAmount0, int256 swapAmount1) = _swapTokenSingle(
            false,
            tokenIn,
            zeroForOne,
            zeroForOne ? withdrawal0 : withdrawal1
        );

        amount = zeroForOne
            ? withdrawal1.add(uint256(-swapAmount1))
            : withdrawal0.add(uint256(-swapAmount0));

        require(amount > amountOutMin, "m");

        if (zeroForOne) {
            token1.safeTransfer(to, amount);
        } else {
            token0.safeTransfer(to, amount);
        }

        emit Withdraw(yangId, to, shares, withdrawal0, withdrawal1);
    }

    function withdraw(
        uint256 yangId,
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    )
        external
        override
        nonReentrant
        onlyManager
        returns (uint256 withdrawal0, uint256 withdrawal1)
    {
        require(shares > 0, "s");
        require(to != address(0) && to != address(this), "to");

        (withdrawal0, withdrawal1) = _withdrawShare(
            shares,
            amount0Min,
            amount1Min
        );

        if (withdrawal0 > 0) token0.safeTransfer(to, withdrawal0);
        if (withdrawal1 > 0) token1.safeTransfer(to, withdrawal1);

        emit Withdraw(yangId, to, shares, withdrawal0, withdrawal1);
    }

    function _withdrawShare(
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal returns (uint256 withdrawal0, uint256 withdrawal1) {
        // collect fee
        _harvestFee();

        (uint256 total0, uint256 total1) = getTotalAmounts();

        withdrawal0 = total0.mul(shares).div(_totalSupply);
        withdrawal1 = total1.mul(shares).div(_totalSupply);

        require(withdrawal0 >= amount0Min, "A0M");
        require(withdrawal1 >= amount1Min, "A1M");

        uint256 balance0 = balanceToken0();
        uint256 balance1 = balanceToken1();

        if (balance0 < withdrawal0 || balance1 < withdrawal1) {
            uint256 shouldWithdrawal0 = balance0 < withdrawal0
                ? withdrawal0.sub(balance0)
                : 0;
            uint256 shouldWithdrawal1 = balance1 < withdrawal1
                ? withdrawal1.sub(balance1)
                : 0;

            (
                uint256 _liquidityAmount0,
                uint256 _liquidityAmount1
            ) = getTotalLiquidityAmounts();

            uint256 shouldLiquidity = 0;
            if (_liquidityAmount0 != 0 && _liquidityAmount1 == 0) {
                shouldLiquidity = shouldWithdrawal0.mul(scaleRate).div(
                    _liquidityAmount0
                );
            } else if (_liquidityAmount0 == 0 && _liquidityAmount1 != 0) {
                shouldLiquidity = shouldWithdrawal1.mul(scaleRate).div(
                    _liquidityAmount1
                );
            } else if (_liquidityAmount0 != 0 && _liquidityAmount1 != 0) {
                shouldLiquidity = Math.max(
                    shouldWithdrawal0.mul(scaleRate).div(_liquidityAmount0),
                    shouldWithdrawal1.mul(scaleRate).div(_liquidityAmount1)
                );
            }
            // avoid round down
            shouldLiquidity = shouldLiquidity.mul(10100).div(10000);
            if (shouldLiquidity > scaleRate) {
                shouldLiquidity = scaleRate;
            }

            (uint256 burnTotal0, uint256 burnTotal1) = _burnMultLiquidityScale(
                shouldLiquidity,
                address(this)
            );
            require(
                burnTotal0 >= shouldWithdrawal0 &&
                    burnTotal1 >= shouldWithdrawal1,
                "SW"
            );
        }
        // Burn shares
        _burn(shares);
    }

    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata
    ) external override {
        require(msg.sender == address(pool));
        if (amount0Owed > 0) token0.safeTransfer(msg.sender, amount0Owed);
        if (amount1Owed > 0) token1.safeTransfer(msg.sender, amount1Owed);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        require(msg.sender == address(pool));
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));

        address _tokenIn = data.tokenIn;
        uint256 amountToPay = amount0Delta > 0
            ? uint256(amount0Delta)
            : uint256(amount1Delta);
        if (data.isDeposit) {
            ICHIDepositCallBack(CHIManager).CHIDepositCallback(
                IERC20(_tokenIn),
                amountToPay,
                IERC20(0),
                0,
                address(pool)
            );
        } else {
            IERC20(_tokenIn).safeTransfer(address(pool), amountToPay);
        }
    }

    function balanceToken0() public view override returns (uint256) {
        return token0.balanceOf(address(this)).sub(_accruedProtocolFees0);
    }

    function balanceToken1() public view override returns (uint256) {
        return token1.balanceOf(address(this)).sub(_accruedProtocolFees1);
    }

    function _calcSharesAndAmounts(
        uint256 total0,
        uint256 total1,
        uint256 amount0Desired,
        uint256 amount1Desired
    )
        internal
        view
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        )
    {
        // If total supply > 0, vault can't be empty
        assert(_totalSupply == 0 || total0 > 0 || total1 > 0);

        if (_totalSupply == 0) {
            // For first deposit, just use the amounts desired
            amount0 = amount0Desired;
            amount1 = amount1Desired;
            shares = Math.max(amount0, amount1);
        } else if (total0 == 0) {
            amount1 = amount1Desired;
            shares = amount1.mul(_totalSupply).div(total1);
        } else if (total1 == 0) {
            amount0 = amount0Desired;
            shares = amount0.mul(_totalSupply).div(total0);
        } else {
            uint256 cross = Math.min(
                amount0Desired.mul(total1),
                amount1Desired.mul(total0)
            );
            if (cross != 0) {
                // Round up amounts
                amount0 = cross.sub(1).div(total1).add(1);
                amount1 = cross.sub(1).div(total0).add(1);
                shares = cross.mul(_totalSupply).div(total0).div(total1);
            }
        }
    }

    function harvestFee() external {
        _harvestFee();
    }

    function _harvestFee() internal {
        uint256 collect0 = 0;
        uint256 collect1 = 0;
        // update pool
        _updateLiquidity();
        for (uint256 i = 0; i < _rangeSet.length(); i++) {
            (int24 _tickLower, int24 _tickUpper) = _decode(_rangeSet.at(i));
            (uint256 _collect0, uint256 _collect1) = _collect(
                _tickLower,
                _tickUpper
            );
            collect0 = collect0.add(_collect0);
            collect1 = collect1.add(_collect1);
        }
        emit CollectFee(collect0, collect1);
    }

    function collectProtocol(
        uint256 amount0,
        uint256 amount1,
        address to
    ) external override onlyManager {
        _accruedProtocolFees0 = _accruedProtocolFees0.sub(amount0);
        _accruedProtocolFees1 = _accruedProtocolFees1.sub(amount1);
        if (amount0 > 0) token0.safeTransfer(to, amount0);
        if (amount1 > 0) token1.safeTransfer(to, amount1);
    }

    function addLiquidityToPosition(
        uint256 rangeIndex,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external override nonReentrant onlyManager {
        (int24 _tickLower, int24 _tickUpper) = _decode(
            _rangeSet.at(rangeIndex)
        );

        require(amount0Desired <= balanceToken0(), "IB0");
        require(amount1Desired <= balanceToken1(), "IB1");

        // Place order on UniswapV3
        uint128 liquidity = _liquidityForAmounts(
            _tickLower,
            _tickUpper,
            amount0Desired,
            amount1Desired
        );
        if (liquidity > 0) {
            pool.mint(
                address(this),
                _tickLower,
                _tickUpper,
                liquidity,
                new bytes(0)
            );
        }
    }

    function removeLiquidityFromPosition(uint256 rangeIndex, uint128 liquidity)
        external
        override
        nonReentrant
        onlyManager
        returns (uint256 amount0, uint256 amount1)
    {
        (int24 _tickLower, int24 _tickUpper) = _decode(
            _rangeSet.at(rangeIndex)
        );

        require(liquidity <= _positionLiquidity(_tickLower, _tickUpper), "L");

        if (liquidity > 0) {
            (amount0, amount1) = pool.burn(_tickLower, _tickUpper, liquidity);

            if (amount0 > 0 || amount1 > 0) {
                (amount0, amount1) = pool.collect(
                    address(this),
                    _tickLower,
                    _tickUpper,
                    toUint128(amount0),
                    toUint128(amount1)
                );
            }
        }
    }

    function removeAllLiquidityFromPosition(uint256 rangeIndex)
        external
        override
        nonReentrant
        onlyManager
        returns (uint256 amount0, uint256 amount1)
    {
        (int24 _tickLower, int24 _tickUpper) = _decode(
            _rangeSet.at(rangeIndex)
        );
        uint128 liquidity = _positionLiquidity(_tickLower, _tickUpper);
        if (liquidity > 0) {
            (amount0, amount1) = pool.burn(_tickLower, _tickUpper, liquidity);

            if (amount0 > 0 || amount1 > 0) {
                (amount0, amount1) = pool.collect(
                    address(this),
                    _tickLower,
                    _tickUpper,
                    toUint128(amount0),
                    toUint128(amount1)
                );
            }
        }
    }

    function _collect(int24 tickLower, int24 tickUpper)
        internal
        returns (uint256 collect0, uint256 collect1)
    {
        bytes32 positionKey = keccak256(
            abi.encodePacked(address(this), tickLower, tickUpper)
        );
        (, , , uint128 tokensOwed0, uint128 tokensOwed1) = pool.positions(
            positionKey
        );
        (collect0, collect1) = pool.collect(
            address(this),
            tickLower,
            tickUpper,
            tokensOwed0,
            tokensOwed1
        );
        uint256 feesToProtocol0 = 0;
        uint256 feesToProtocol1 = 0;

        // Update accrued protocol fees
        if (_protocolFee > 0) {
            feesToProtocol0 = collect0.mul(_protocolFee).div(FEE_BASE);
            feesToProtocol1 = collect1.mul(_protocolFee).div(FEE_BASE);
            _accruedProtocolFees0 = _accruedProtocolFees0.add(feesToProtocol0);
            _accruedProtocolFees1 = _accruedProtocolFees1.add(feesToProtocol1);
        }
        _accruedCollectFees0 = _accruedCollectFees0.add(
            collect0.sub(feesToProtocol0)
        );
        _accruedCollectFees1 = _accruedCollectFees1.add(
            collect1.sub(feesToProtocol1)
        );
    }

    function _amountsForLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal view returns (uint256 amount0, uint256 amount1) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            liquidity
        );
    }

    function _amountsForShares(
        int24 tickLower,
        int24 tickUpper,
        uint256 shares
    ) internal view returns (uint256 amount0, uint256 amount1) {
        uint128 position = _positionLiquidity(tickLower, tickUpper);
        uint128 liquidity = toUint128(
            uint256(position).mul(shares).div(_totalSupply)
        );
        (amount0, amount1) = _amountsForLiquidity(
            tickLower,
            tickUpper,
            liquidity
        );
    }

    function _liquidityForAmounts(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) internal view returns (uint128 liquidity) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            amount0,
            amount1
        );
    }

    function _checkTicks(int24 tickLower, int24 tickUpper) private view {
        require(tickLower < tickUpper, "TLU");
        require(tickLower >= TickMath.MIN_TICK, "TLM");
        require(tickUpper <= TickMath.MAX_TICK, "TUM");
        require(tickLower % tickSpacing == 0, "TLF");
        require(tickUpper % tickSpacing == 0, "TUF");
    }

    function _updateLiquidity() internal {
        for (uint256 i = 0; i < _rangeSet.length(); i++) {
            (int24 _tickLower, int24 _tickUpper) = _decode(_rangeSet.at(i));
            if (_positionLiquidity(_tickLower, _tickUpper) > 0) {
                pool.burn(_tickLower, _tickUpper, 0);
            }
        }
    }

    function _burnMultLiquidityScale(uint256 lqiuidityScale, address to)
        internal
        returns (uint256 total0, uint256 total1)
    {
        for (uint256 i = 0; i < _rangeSet.length(); i++) {
            (int24 _tickLower, int24 _tickUpper) = _decode(_rangeSet.at(i));
            if (_positionLiquidity(_tickLower, _tickUpper) > 0) {
                (uint256 amount0, uint256 amount1) = _burnLiquidityScale(
                    _tickLower,
                    _tickUpper,
                    lqiuidityScale,
                    to
                );
                total0 = total0.add(amount0);
                total1 = total1.add(amount1);
            }
        }
    }

    function _burnLiquidityScale(
        int24 tickLower,
        int24 tickUpper,
        uint256 lqiuidityScale,
        address to
    ) internal returns (uint256 amount0, uint256 amount1) {
        uint128 position = _positionLiquidity(tickLower, tickUpper);
        uint256 liquidity = uint256(position).mul(lqiuidityScale).div(
            scaleRate
        );

        if (liquidity > 0) {
            (amount0, amount1) = pool.burn(
                tickLower,
                tickUpper,
                toUint128(liquidity)
            );

            if (amount0 > 0 || amount1 > 0) {
                (amount0, amount1) = pool.collect(
                    to,
                    tickLower,
                    tickUpper,
                    toUint128(amount0),
                    toUint128(amount1)
                );
            }
        }
    }

    /// @dev Get position liquidity
    function _positionLiquidity(int24 tickLower, int24 tickUpper)
        internal
        view
        returns (uint128 liquidity)
    {
        bytes32 positionKey = keccak256(
            abi.encodePacked(address(this), tickLower, tickUpper)
        );
        (liquidity, , , , ) = pool.positions(positionKey);
    }

    /// @dev Increasing the total supply.
    function _mint(uint256 amount) internal {
        _totalSupply += amount;
    }

    /// @dev Decreasing the total supply.
    function _burn(uint256 amount) internal {
        _totalSupply -= amount;
    }

    function sweep(address token, address to) external override onlyManager {
        require(token != address(token0) && token != address(token1), "t");
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, amount);
    }

    /// @dev Burn all liquidity with ticks.
    function emergencyBurn(int24 tickLower, int24 tickUpper)
        external
        override
        onlyManager
    {
        uint128 liquidity = _positionLiquidity(tickLower, tickUpper);
        pool.burn(tickLower, tickUpper, liquidity);
        pool.collect(
            address(this),
            tickLower,
            tickUpper,
            type(uint128).max,
            type(uint128).max
        );
    }

    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < (1 << 255));
        z = int256(y);
    }

    function swapPercentage(SwapParams memory params)
        external
        override
        onlyManager
        returns (uint256 amountOut)
    {
        address tokenIn = params.tokenIn;
        address tokenOut = params.tokenOut;

        require(address(router) != address(0), "zero router");
        require(params.percentage < FEE_BASE, "percentage");
        require(
            params.slippageTolerance >= 500 &&
                params.slippageTolerance <= 10000,
            "slippage invalid"
        );
        require(
            (tokenIn == address(token0) || tokenIn == address(token1)) &&
                (tokenOut == address(token1) || tokenOut == address(token0)),
            "invalid address"
        );
        uint256 amountIn = (
            tokenIn == address(token0) ? balanceToken0() : balanceToken1()
        ).mul(params.percentage).div(FEE_BASE);
        uint256 amountOutMin;
        {
            int24 tick = OracleLibrary.consult(address(pool), params.interval);
            uint256 amountOutQuote = OracleLibrary.getQuoteAtTick(
                tick,
                toUint128(amountIn.sub(amountIn.mul(fee).div(FEE_BASE))),
                tokenIn,
                tokenOut
            );
            amountOutMin = amountOutQuote.sub(
                amountOutQuote.mul(params.slippageTolerance).div(FEE_BASE)
            );
        }
        {
            // Approve and Swap
            TransferHelper.safeApprove(tokenIn, address(router), amountIn);
            amountOut = router.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    fee: fee,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amountIn,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: params.sqrtRatioX96
                })
            );
            TransferHelper.safeApprove(tokenIn, address(router), 0);
        }
        require(amountOut >= amountOutMin, "minimum");
        emit Swap(tokenIn, tokenOut, amountIn, amountOut, amountOutMin);
    }
}
