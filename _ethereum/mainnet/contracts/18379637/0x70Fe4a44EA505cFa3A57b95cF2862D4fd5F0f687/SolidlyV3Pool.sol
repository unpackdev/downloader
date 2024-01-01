// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "./ISolidlyV3Pool.sol";

import "./LowGasSafeMath.sol";
import "./SafeCast.sol";
import "./Tick.sol";
import "./TickBitmap.sol";
import "./Position.sol";
import "./Validation.sol";

import "./FullMath.sol";
import "./FixedPoint128.sol";
import "./TransferHelper.sol";
import "./TickMath.sol";
import "./LiquidityMath.sol";
import "./SqrtPriceMath.sol";
import "./SwapMath.sol";

import "./ISolidlyV3PoolDeployer.sol";
import "./ISolidlyV3Factory.sol";
import "./IERC20Minimal.sol";
import "./ISolidlyV3SwapCallback.sol";
import "./ISolidlyV3MintCallback.sol";
import "./ISolidlyV3FlashCallback.sol";

contract SolidlyV3Pool is ISolidlyV3Pool, Validation {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    using Tick for mapping(int24 => Tick.Info);
    using TickBitmap for mapping(int16 => uint256);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;

    /// @inheritdoc ISolidlyV3PoolImmutables
    address public immutable override factory;
    /// @inheritdoc ISolidlyV3PoolImmutables
    address public immutable override token0;
    /// @inheritdoc ISolidlyV3PoolImmutables
    address public immutable override token1;

    /// @inheritdoc ISolidlyV3PoolImmutables
    int24 public immutable override tickSpacing;

    /// @inheritdoc ISolidlyV3PoolImmutables
    uint128 public immutable override maxLiquidityPerTick;

    struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the pool's current fee in hundredths of a bip, i.e. 1e-6
        uint24 fee;
        // whether the pool is locked
        bool unlocked;
    }
    /// @inheritdoc ISolidlyV3PoolState
    Slot0 public override slot0;

    // accumulated pool fees in token0/token1 units
    struct PoolFees {
        uint128 token0;
        uint128 token1;
    }
    /// @inheritdoc ISolidlyV3PoolState
    PoolFees public override poolFees;

    /// @inheritdoc ISolidlyV3PoolState
    uint128 public override liquidity;

    /// @inheritdoc ISolidlyV3PoolState
    mapping(int24 => Tick.Info) public override ticks;
    /// @inheritdoc ISolidlyV3PoolState
    mapping(int16 => uint256) public override tickBitmap;
    /// @inheritdoc ISolidlyV3PoolState
    mapping(bytes32 => Position.Info) public override positions;

    /// @dev Mutually exclusive reentrancy protection into the pool to/from a method. This method also prevents entrance
    /// to a function before the pool is initialized. The reentrancy guard is required throughout the contract because
    /// we use balance checks to determine the payment status of interactions such as mint, swap and flash.
    modifier lock() {
        require(slot0.unlocked, 'LOK');
        slot0.unlocked = false;
        _;
        slot0.unlocked = true;
    }

    constructor() {
        int24 _tickSpacing;
        uint24 _fee;
        (factory, token0, token1, _fee, _tickSpacing) = ISolidlyV3PoolDeployer(msg.sender).parameters();
        slot0.fee = _fee;
        tickSpacing = _tickSpacing;

        maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(_tickSpacing);
    }

    /// @dev Common checks for valid tick inputs.
    function checkTicks(int24 tickLower, int24 tickUpper) private pure {
        require(tickLower < tickUpper, 'TLU');
        require(tickLower >= TickMath.MIN_TICK, 'TLM');
        require(tickUpper <= TickMath.MAX_TICK, 'TUM');
    }

    /// @dev Get the pool's balance of token0
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// check
    function balance0() private view returns (uint256) {
        (bool success, bytes memory data) = token0.staticcall(
            abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    /// @dev Get the pool's balance of token1
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// check
    function balance1() private view returns (uint256) {
        (bool success, bytes memory data) = token1.staticcall(
            abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    /// @inheritdoc ISolidlyV3PoolActions
    /// @dev not locked because it initializes unlocked
    function initialize(uint160 sqrtPriceX96) external override {
        require(slot0.sqrtPriceX96 == 0, 'AI');

        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        slot0.sqrtPriceX96 = sqrtPriceX96;
        slot0.tick = tick;
        slot0.unlocked = true;

        emit Initialize(sqrtPriceX96, tick);
    }

    struct ModifyPositionParams {
        // the address that owns the position
        address owner;
        // the lower and upper tick of the position
        int24 tickLower;
        int24 tickUpper;
        // any change in liquidity
        int128 liquidityDelta;
    }

    /// @dev Effect some changes to a position
    /// @param params the position details and the change to the position's liquidity to effect
    /// @return position a storage pointer referencing the position with the given owner and tick range
    /// @return amount0 the amount of token0 owed to the pool, negative if the pool should pay the recipient
    /// @return amount1 the amount of token1 owed to the pool, negative if the pool should pay the recipient
    function _modifyPosition(
        ModifyPositionParams memory params
    ) private returns (Position.Info storage position, int256 amount0, int256 amount1) {
        checkTicks(params.tickLower, params.tickUpper);

        Slot0 memory _slot0 = slot0; // SLOAD for gas optimization

        position = _updatePosition(params.owner, params.tickLower, params.tickUpper, params.liquidityDelta);

        if (params.liquidityDelta != 0) {
            if (_slot0.tick < params.tickLower) {
                // current tick is below the passed range; liquidity can only become in range by crossing from left to
                // right, when we'll need _more_ token0 (it's becoming more valuable) so user must provide it
                amount0 = SqrtPriceMath.getAmount0Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                );
            } else if (_slot0.tick < params.tickUpper) {
                // current tick is inside the passed range
                uint128 liquidityBefore = liquidity; // SLOAD for gas optimization

                amount0 = SqrtPriceMath.getAmount0Delta(
                    _slot0.sqrtPriceX96,
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                );
                amount1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    _slot0.sqrtPriceX96,
                    params.liquidityDelta
                );

                liquidity = LiquidityMath.addDelta(liquidityBefore, params.liquidityDelta);
            } else {
                // current tick is above the passed range; liquidity can only become in range by crossing from right to
                // left, when we'll need _more_ token1 (it's becoming more valuable) so user must provide it
                amount1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                );
            }
        }
    }

    /// @dev Gets and updates a position with the given liquidity delta
    /// @param owner the owner of the position
    /// @param tickLower the lower tick of the position's tick range
    /// @param tickUpper the upper tick of the position's tick range
    function _updatePosition(
        address owner,
        int24 tickLower,
        int24 tickUpper,
        int128 liquidityDelta
    ) private returns (Position.Info storage position) {
        position = positions.get(owner, tickLower, tickUpper);

        // if we need to update the ticks, do it
        bool flippedLower;
        bool flippedUpper;
        if (liquidityDelta != 0) {
            flippedLower = ticks.update(tickLower, liquidityDelta, false, maxLiquidityPerTick);
            flippedUpper = ticks.update(tickUpper, liquidityDelta, true, maxLiquidityPerTick);

            if (flippedLower) {
                tickBitmap.flipTick(tickLower, tickSpacing);
            }
            if (flippedUpper) {
                tickBitmap.flipTick(tickUpper, tickSpacing);
            }
        }

        position.update(liquidityDelta);

        // clear any tick data that is no longer needed
        if (liquidityDelta < 0) {
            if (flippedLower) {
                ticks.clear(tickLower);
            }
            if (flippedUpper) {
                ticks.clear(tickUpper);
            }
        }
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external override returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = _mint(recipient, tickLower, tickUpper, amount);
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external override returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = _mint(recipient, tickLower, tickUpper, amount, data);
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 deadline
    ) external override checkDeadline(deadline) returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = _mint(recipient, tickLower, tickUpper, amount);
        require(amount0 >= amount0Min && amount1 >= amount1Min, 'AL');
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 deadline,
        bytes calldata data
    ) external override checkDeadline(deadline) returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = _mint(recipient, tickLower, tickUpper, amount, data);
        require(amount0 >= amount0Min && amount1 >= amount1Min, 'AL');
    }

    function _mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) private lock returns (uint256 amount0, uint256 amount1) {
        require(amount > 0);
        (, int256 amount0Int, int256 amount1Int) = _modifyPosition(
            ModifyPositionParams({
                owner: recipient,
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: int256(amount).toInt128()
            })
        );
        amount0 = uint256(amount0Int);
        amount1 = uint256(amount1Int);

        if (amount0 > 0) TransferHelper.safeTransferFrom(token0, msg.sender, address(this), amount0);
        if (amount1 > 0) TransferHelper.safeTransferFrom(token1, msg.sender, address(this), amount1);

        emit Mint(msg.sender, recipient, tickLower, tickUpper, amount, amount0, amount1);
    }

    function _mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) private lock returns (uint256 amount0, uint256 amount1) {
        require(amount > 0);
        (, int256 amount0Int, int256 amount1Int) = _modifyPosition(
            ModifyPositionParams({
                owner: recipient,
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: int256(amount).toInt128()
            })
        );
        amount0 = uint256(amount0Int);
        amount1 = uint256(amount1Int);

        uint256 balance0Before;
        uint256 balance1Before;
        if (amount0 > 0) balance0Before = balance0();
        if (amount1 > 0) balance1Before = balance1();
        ISolidlyV3MintCallback(msg.sender).solidlyV3MintCallback(amount0, amount1, data);
        if (amount0 > 0) require(balance0Before.add(amount0) <= balance0(), 'M0');
        if (amount1 > 0) require(balance1Before.add(amount1) <= balance1(), 'M1');

        emit Mint(msg.sender, recipient, tickLower, tickUpper, amount, amount0, amount1);
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function burnAndCollect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amountToBurn,
        uint128 amount0ToCollect,
        uint128 amount1ToCollect
    )
        external
        override
        returns (uint256 amount0FromBurn, uint256 amount1FromBurn, uint128 amount0Collected, uint128 amount1Collected)
    {
        (amount0FromBurn, amount1FromBurn) = _burn(tickLower, tickUpper, amountToBurn);
        (amount0Collected, amount1Collected) = _collect(
            recipient,
            tickLower,
            tickUpper,
            amount0ToCollect,
            amount1ToCollect
        );
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function burnAndCollect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amountToBurn,
        uint256 amount0FromBurnMin,
        uint256 amount1FromBurnMin,
        uint128 amount0ToCollect,
        uint128 amount1ToCollect,
        uint256 deadline
    )
        external
        override
        checkDeadline(deadline)
        returns (uint256 amount0FromBurn, uint256 amount1FromBurn, uint128 amount0Collected, uint128 amount1Collected)
    {
        (amount0FromBurn, amount1FromBurn) = _burn(tickLower, tickUpper, amountToBurn);
        require(amount0FromBurn >= amount0FromBurnMin && amount1FromBurn >= amount1FromBurnMin, 'AL');
        (amount0Collected, amount1Collected) = _collect(
            recipient,
            tickLower,
            tickUpper,
            amount0ToCollect,
            amount1ToCollect
        );
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override returns (uint128 amount0, uint128 amount1) {
        (amount0, amount1) = _collect(recipient, tickLower, tickUpper, amount0Requested, amount1Requested);
    }

    function _collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) private lock returns (uint128 amount0, uint128 amount1) {
        // we don't need to checkTicks here, because invalid positions will never have non-zero tokensOwed{0,1}
        Position.Info storage position = positions.get(msg.sender, tickLower, tickUpper);

        amount0 = amount0Requested > position.tokensOwed0 ? position.tokensOwed0 : amount0Requested;
        amount1 = amount1Requested > position.tokensOwed1 ? position.tokensOwed1 : amount1Requested;

        if (amount0 > 0) {
            position.tokensOwed0 -= amount0;
            TransferHelper.safeTransfer(token0, recipient, amount0);
        }
        if (amount1 > 0) {
            position.tokensOwed1 -= amount1;
            TransferHelper.safeTransfer(token1, recipient, amount1);
        }

        emit Collect(msg.sender, recipient, tickLower, tickUpper, amount0, amount1);
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external override returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = _burn(tickLower, tickUpper, amount);
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 deadline
    ) external override checkDeadline(deadline) returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = _burn(tickLower, tickUpper, amount);
        require(amount0 >= amount0Min && amount1 >= amount1Min, 'AL');
    }

    function _burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) private lock returns (uint256 amount0, uint256 amount1) {
        (Position.Info storage position, int256 amount0Int, int256 amount1Int) = _modifyPosition(
            ModifyPositionParams({
                owner: msg.sender,
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: -int256(amount).toInt128()
            })
        );

        amount0 = uint256(-amount0Int);
        amount1 = uint256(-amount1Int);

        if (amount0 > 0 || amount1 > 0) {
            (position.tokensOwed0, position.tokensOwed1) = (
                position.tokensOwed0 + uint128(amount0),
                position.tokensOwed1 + uint128(amount1)
            );
        }

        emit Burn(msg.sender, tickLower, tickUpper, amount, amount0, amount1);
    }

    // the top level state of the swap, the results of which are recorded in storage at the end
    struct SwapState {
        // the amount remaining to be swapped in/out of the input/output asset
        int256 amountSpecifiedRemaining;
        // the amount already swapped out/in of the output/input asset
        int256 amountCalculated;
        // current sqrt(price)
        uint160 sqrtPriceX96;
        // the tick associated with the current price
        int24 tick;
        // the current liquidity in range
        uint128 liquidity;
        // the pool fee
        uint128 poolFee;
    }

    struct StepComputations {
        // the price at the beginning of the step
        uint160 sqrtPriceStartX96;
        // the next tick to swap to from the current tick in the swap direction
        int24 tickNext;
        // whether tickNext is initialized or not
        bool initialized;
        // sqrt(price) for the next tick (1/0)
        uint160 sqrtPriceNextX96;
        // how much is being swapped in in this step
        uint256 amountIn;
        // how much is being swapped out
        uint256 amountOut;
        // how much fee is being paid in
        uint256 feeAmount;
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) external override returns (int256 amount0, int256 amount1) {
        (amount0, amount1) = _swap(recipient, zeroForOne, amountSpecified, sqrtPriceLimitX96);
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external override returns (int256 amount0, int256 amount1) {
        (amount0, amount1) = _swap(recipient, zeroForOne, amountSpecified, sqrtPriceLimitX96, data);
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        uint256 amountLimit,
        uint256 deadline
    ) external override checkDeadline(deadline) returns (int256 amount0, int256 amount1) {
        (amount0, amount1) = _swap(recipient, zeroForOne, amountSpecified, sqrtPriceLimitX96);
        if (zeroForOne) {
            require(uint256(-amount1) >= amountLimit, 'AL');
        } else {
            require(uint256(-amount0) >= amountLimit, 'AL');
        }
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        uint256 amountLimit,
        uint256 deadline,
        bytes calldata data
    ) external override checkDeadline(deadline) returns (int256 amount0, int256 amount1) {
        (amount0, amount1) = _swap(recipient, zeroForOne, amountSpecified, sqrtPriceLimitX96, data);
        if (zeroForOne) {
            require(uint256(-amount1) >= amountLimit, 'AL');
        } else {
            require(uint256(-amount0) >= amountLimit, 'AL');
        }
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        uint256 trackingCode
    ) external override returns (int256 amount0, int256 amount1) {
        (amount0, amount1) = _swap(recipient, zeroForOne, amountSpecified, sqrtPriceLimitX96);
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data,
        uint256 trackingCode
    ) external override returns (int256 amount0, int256 amount1) {
        (amount0, amount1) = _swap(recipient, zeroForOne, amountSpecified, sqrtPriceLimitX96, data);
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        uint256 amountLimit,
        uint256 deadline,
        uint256 trackingCode
    ) external override checkDeadline(deadline) returns (int256 amount0, int256 amount1) {
        (amount0, amount1) = _swap(recipient, zeroForOne, amountSpecified, sqrtPriceLimitX96);
        if (zeroForOne) {
            require(uint256(-amount1) >= amountLimit, 'AL');
        } else {
            require(uint256(-amount0) >= amountLimit, 'AL');
        }
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        uint256 amountLimit,
        uint256 deadline,
        bytes calldata data,
        uint256 trackingCode
    ) external override checkDeadline(deadline) returns (int256 amount0, int256 amount1) {
        (amount0, amount1) = _swap(recipient, zeroForOne, amountSpecified, sqrtPriceLimitX96, data);
        if (zeroForOne) {
            require(uint256(-amount1) >= amountLimit, 'AL');
        } else {
            require(uint256(-amount0) >= amountLimit, 'AL');
        }
    }

    function _swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) private returns (int256 amount0, int256 amount1) {
        (amount0, amount1) = _swapBase(recipient, zeroForOne, amountSpecified, sqrtPriceLimitX96);

        // do the transfers and collect payment
        if (zeroForOne) {
            if (amount0 > 0) TransferHelper.safeTransferFrom(token0, msg.sender, address(this), uint256(amount0));
            if (amount1 < 0) TransferHelper.safeTransfer(token1, recipient, uint256(-amount1));
        } else {
            if (amount1 > 0) TransferHelper.safeTransferFrom(token1, msg.sender, address(this), uint256(amount1));
            if (amount0 < 0) TransferHelper.safeTransfer(token0, recipient, uint256(-amount0));
        }

        slot0.unlocked = true;
    }

    function _swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) private returns (int256 amount0, int256 amount1) {
        (amount0, amount1) = _swapBase(recipient, zeroForOne, amountSpecified, sqrtPriceLimitX96);

        // do the transfers and collect payment
        if (zeroForOne) {
            if (amount1 < 0) TransferHelper.safeTransfer(token1, recipient, uint256(-amount1));

            uint256 balance0Before = balance0();
            ISolidlyV3SwapCallback(msg.sender).solidlyV3SwapCallback(amount0, amount1, data);
            require(balance0Before.add(uint256(amount0)) <= balance0(), 'IIA');
        } else {
            if (amount0 < 0) TransferHelper.safeTransfer(token0, recipient, uint256(-amount0));

            uint256 balance1Before = balance1();
            ISolidlyV3SwapCallback(msg.sender).solidlyV3SwapCallback(amount0, amount1, data);
            require(balance1Before.add(uint256(amount1)) <= balance1(), 'IIA');
        }

        slot0.unlocked = true;
    }

    function _swapBase(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) private returns (int256 amount0, int256 amount1) {
        require(amountSpecified != 0, 'AS');

        Slot0 memory slot0Start = slot0;

        require(slot0Start.unlocked, 'LOK');
        require(
            zeroForOne
                ? sqrtPriceLimitX96 < slot0Start.sqrtPriceX96 && sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO
                : sqrtPriceLimitX96 > slot0Start.sqrtPriceX96 && sqrtPriceLimitX96 < TickMath.MAX_SQRT_RATIO,
            'SPL'
        );

        slot0.unlocked = false;

        uint128 liquidityStart = liquidity;

        bool exactInput = amountSpecified > 0;

        SwapState memory state = SwapState({
            amountSpecifiedRemaining: amountSpecified,
            amountCalculated: 0,
            sqrtPriceX96: slot0Start.sqrtPriceX96,
            tick: slot0Start.tick,
            liquidity: liquidityStart,
            poolFee: 0
        });

        // continue swapping as long as we haven't used the entire input/output and haven't reached the price limit
        while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
            StepComputations memory step;

            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.tickNext, step.initialized) = tickBitmap.nextInitializedTickWithinOneWord(
                state.tick,
                tickSpacing,
                zeroForOne
            );

            // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
            if (step.tickNext < TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            } else if (step.tickNext > TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            // get the price for the next tick
            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

            // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
            (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                (zeroForOne ? step.sqrtPriceNextX96 < sqrtPriceLimitX96 : step.sqrtPriceNextX96 > sqrtPriceLimitX96)
                    ? sqrtPriceLimitX96
                    : step.sqrtPriceNextX96,
                state.liquidity,
                state.amountSpecifiedRemaining,
                slot0Start.fee
            );

            if (exactInput) {
                state.amountSpecifiedRemaining -= (step.amountIn + step.feeAmount).toInt256();
                state.amountCalculated = state.amountCalculated.sub(step.amountOut.toInt256());
            } else {
                state.amountSpecifiedRemaining += step.amountOut.toInt256();
                state.amountCalculated = state.amountCalculated.add((step.amountIn + step.feeAmount).toInt256());
            }

            // increment poolFees for the current swap step
            state.poolFee += uint128(step.feeAmount);

            // shift tick if we reached the next price
            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                // if the tick is initialized, run the tick transition
                if (step.initialized) {
                    int128 liquidityNet = ticks.cross(step.tickNext);
                    // if we're moving leftward, we interpret liquidityNet as the opposite sign
                    // safe because liquidityNet cannot be type(int128).min
                    if (zeroForOne) liquidityNet = -liquidityNet;

                    state.liquidity = LiquidityMath.addDelta(state.liquidity, liquidityNet);
                }

                state.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }
        }

        // update tick if the tick changed
        if (state.tick != slot0Start.tick) {
            (slot0.sqrtPriceX96, slot0.tick) = (state.sqrtPriceX96, state.tick);
        } else {
            // otherwise just update the price
            slot0.sqrtPriceX96 = state.sqrtPriceX96;
        }

        // update liquidity if it changed
        if (liquidityStart != state.liquidity) liquidity = state.liquidity;

        // update pool fees
        // overflow is acceptable, fees must be claimed and reset before they hit type(uint128).max
        if (zeroForOne) {
            if (state.poolFee > 0) poolFees.token0 += state.poolFee;
        } else {
            if (state.poolFee > 0) poolFees.token1 += state.poolFee;
        }

        (amount0, amount1) = zeroForOne == exactInput
            ? (amountSpecified - state.amountSpecifiedRemaining, state.amountCalculated)
            : (state.amountCalculated, amountSpecified - state.amountSpecifiedRemaining);

        emit Swap(msg.sender, recipient, amount0, amount1, state.sqrtPriceX96, state.liquidity, state.tick);
    }

    function quoteSwap(
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    )
        external
        view
        override
        returns (int256 amount0, int256 amount1, uint160 sqrtPriceX96After, int24 tickAfter, uint128 liquidityAfter)
    {
        require(amountSpecified != 0, 'AS');

        Slot0 memory slot0Start = slot0;

        require(
            zeroForOne
                ? sqrtPriceLimitX96 < slot0Start.sqrtPriceX96 && sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO
                : sqrtPriceLimitX96 > slot0Start.sqrtPriceX96 && sqrtPriceLimitX96 < TickMath.MAX_SQRT_RATIO,
            'SPL'
        );

        uint128 liquidityStart = liquidity;

        bool exactInput = amountSpecified > 0;

        SwapState memory state = SwapState({
            amountSpecifiedRemaining: amountSpecified,
            amountCalculated: 0,
            sqrtPriceX96: slot0Start.sqrtPriceX96,
            tick: slot0Start.tick,
            liquidity: liquidityStart,
            poolFee: 0
        });

        // continue swapping as long as we haven't used the entire input/output and haven't reached the price limit
        while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
            StepComputations memory step;

            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.tickNext, step.initialized) = tickBitmap.nextInitializedTickWithinOneWord(
                state.tick,
                tickSpacing,
                zeroForOne
            );

            // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
            if (step.tickNext < TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            } else if (step.tickNext > TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            // get the price for the next tick
            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

            // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
            (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                (zeroForOne ? step.sqrtPriceNextX96 < sqrtPriceLimitX96 : step.sqrtPriceNextX96 > sqrtPriceLimitX96)
                    ? sqrtPriceLimitX96
                    : step.sqrtPriceNextX96,
                state.liquidity,
                state.amountSpecifiedRemaining,
                slot0Start.fee
            );

            if (exactInput) {
                state.amountSpecifiedRemaining -= (step.amountIn + step.feeAmount).toInt256();
                state.amountCalculated = state.amountCalculated.sub(step.amountOut.toInt256());
            } else {
                state.amountSpecifiedRemaining += step.amountOut.toInt256();
                state.amountCalculated = state.amountCalculated.add((step.amountIn + step.feeAmount).toInt256());
            }

            // increment poolFees for the current swap step
            state.poolFee += uint128(step.feeAmount);

            // shift tick if we reached the next price
            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                // if the tick is initialized, run the tick transition
                if (step.initialized) {
                    int128 liquidityNet = ticks.cross(step.tickNext);
                    // if we're moving leftward, we interpret liquidityNet as the opposite sign
                    // safe because liquidityNet cannot be type(int128).min
                    if (zeroForOne) liquidityNet = -liquidityNet;

                    state.liquidity = LiquidityMath.addDelta(state.liquidity, liquidityNet);
                }

                state.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }
        }

        (amount0, amount1) = zeroForOne == exactInput
            ? (amountSpecified - state.amountSpecifiedRemaining, state.amountCalculated)
            : (state.amountCalculated, amountSpecified - state.amountSpecifiedRemaining);

        return (amount0, amount1, state.sqrtPriceX96, state.tick, state.liquidity);
    }

    /// @inheritdoc ISolidlyV3PoolActions
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external override lock {
        uint128 _liquidity = liquidity;
        require(_liquidity > 0, 'L');

        uint256 fee0 = FullMath.mulDivRoundingUp(amount0, slot0.fee, 1e6);
        uint256 fee1 = FullMath.mulDivRoundingUp(amount1, slot0.fee, 1e6);
        uint256 balance0Before = balance0();
        uint256 balance1Before = balance1();

        if (amount0 > 0) TransferHelper.safeTransfer(token0, recipient, amount0);
        if (amount1 > 0) TransferHelper.safeTransfer(token1, recipient, amount1);

        ISolidlyV3FlashCallback(msg.sender).solidlyV3FlashCallback(fee0, fee1, data);

        uint256 balance0After = balance0();
        uint256 balance1After = balance1();

        require(balance0Before.add(fee0) <= balance0After, 'F0');
        require(balance1Before.add(fee1) <= balance1After, 'F1');

        // sub is safe because we know balanceAfter is gt balanceBefore by at least fee
        uint256 paid0 = balance0After - balance0Before;
        uint256 paid1 = balance1After - balance1Before;

        if (paid0 > 0) {
            poolFees.token0 += uint128(paid0);
        }
        if (paid1 > 0) {
            poolFees.token1 += uint128(paid1);
        }

        emit Flash(msg.sender, recipient, amount0, amount1, paid0, paid1);
    }

    /// @inheritdoc ISolidlyV3PoolOwnerActions
    function setFee(uint24 fee) external override lock {
        require(ISolidlyV3Factory(factory).isFeeSetter(msg.sender) == 1, 'UA');
        // pool fee capped at 10%
        require(fee <= 100000);
        uint24 feeOld = slot0.fee;
        slot0.fee = fee;
        emit SetFee(feeOld, fee);
    }

    /// @inheritdoc ISolidlyV3PoolOwnerActions
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override lock returns (uint128 amount0, uint128 amount1) {
        require(ISolidlyV3Factory(factory).feeCollector() == msg.sender, 'UA');

        amount0 = amount0Requested > poolFees.token0 ? poolFees.token0 : amount0Requested;
        amount1 = amount1Requested > poolFees.token1 ? poolFees.token1 : amount1Requested;

        if (amount0 > 0) {
            if (amount0 == poolFees.token0) amount0--; // ensure that the slot is not cleared, for gas savings
            poolFees.token0 -= amount0;
            TransferHelper.safeTransfer(token0, recipient, amount0);
        }
        if (amount1 > 0) {
            if (amount1 == poolFees.token1) amount1--; // ensure that the slot is not cleared, for gas savings
            poolFees.token1 -= amount1;
            TransferHelper.safeTransfer(token1, recipient, amount1);
        }

        emit CollectProtocol(msg.sender, recipient, amount0, amount1);
    }
}
