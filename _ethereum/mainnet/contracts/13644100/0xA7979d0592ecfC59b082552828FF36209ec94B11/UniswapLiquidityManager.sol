// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
pragma abicoder v2;

import "./IUniswapV3Factory.sol";

import "./IUniStrategy.sol";
import "./IUnipilot.sol";
import "./IUniswapLiquidityManager.sol";
import "./IOracle.sol";

import "./LiquidityReserves.sol";
import "./FixedPoint128.sol";
import "./SafeCast.sol";
import "./LiquidityPositions.sol";
import "./UserPositions.sol";

import "./PeripheryPayments.sol";

/// @title UniswapLiquidityManager Universal Liquidity Manager of Uniswap V3
/// @notice Universal & Automated liquidity managment contract that handles liquidity of any Uniswap V3 pool
/// @dev Instead of deploying a contract each time when a new vault is created, UniswapLiquidityManager will
/// manage this in a single contract, all of the vaults are managed within one contract with users just paying
/// storage fees when creating a new vault.
/// @dev UniswapLiquidityManager always maintains 2 range orders on Uniswap V3,
/// base order: The main liquidity range -- where the majority of LP capital sits
/// limit order: A single token range -- depending on which token it holds more of after the base order was placed.
/// @dev The vault readjustment function can be called by captains or anyone to ensure
/// the liquidity of each vault remains in the most optimum range, incentive will be provided for readjustment of vault
/// @dev Vault can not be readjust more than two times in 24 hrs,
/// pool is too volatile if it requires readjustment more than 2
/// @dev User can collect fees in 2 ways:
/// 1. Claim fees in tokens with vault fare, 2. Claim all fees in PILOT
contract UniswapLiquidityManager is PeripheryPayments, IUniswapLiquidityManager {
    using LowGasSafeMath for uint256;
    using SafeCast for uint256;

    address private immutable uniswapFactory;

    uint128 private constant MAX_UINT128 = type(uint128).max;

    uint8 private _unlocked = 1;

    /// @dev The token ID position data of the user
    mapping(uint256 => Position) private positions;

    /// @dev The data of the Unipilot base & range orders
    mapping(address => LiquidityPosition) private liquidityPositions;

    UnipilotProtocolDetails private unipilotProtocolDetails;

    modifier onlyUnipilot() {
        _isUnipilot();
        _;
    }

    modifier onlyGovernance() {
        _isGovernance();
        _;
    }

    modifier nonReentrant() {
        require(_unlocked == 1);
        _unlocked = 0;
        _;
        _unlocked = 1;
    }

    constructor(UnipilotProtocolDetails memory params, address _uniswapFactory) {
        unipilotProtocolDetails = params;
        uniswapFactory = _uniswapFactory;
    }

    function userPositions(uint256 tokenId)
        external
        view
        override
        returns (Position memory)
    {
        return positions[tokenId];
    }

    function poolPositions(address pool)
        external
        view
        override
        returns (LiquidityPosition memory)
    {
        return liquidityPositions[pool];
    }

    /// @dev Blacklist/Whitelist swapping for getting pool in range & premium for readjust liquidity
    /// @param pool Address of the uniswap v3 pool
    /// @param feesInPilot_ Additional premium of a user as an incentive for optimization of vaults.
    /// @param managed_ P
    function setPoolIncentives(
        address pool,
        bool feesInPilot_,
        bool managed_,
        address oracle0,
        address oracle1
    ) external onlyGovernance {
        LiquidityPosition storage lp = liquidityPositions[pool];
        lp.feesInPilot = feesInPilot_;
        lp.managed = managed_;
        lp.oracle0 = oracle0;
        lp.oracle1 = oracle1;
    }

    /// @dev Sets the new details for unipilot protocol
    function setPilotProtocolDetails(UnipilotProtocolDetails calldata params)
        external
        onlyGovernance
    {
        unipilotProtocolDetails = params;
    }

    /// @notice Returns the status of runnng readjust function, the limit is set to 2 readjusts per day
    /// @param pool Address of the pool
    /// @return status Pool rebase status
    function readjustFrequencyStatus(address pool) public returns (bool status) {
        LiquidityPosition storage lp = liquidityPositions[pool];
        if (
            block.timestamp - lp.timestamp > unipilotProtocolDetails.readjustFrequencyTime
        ) {
            lp.counter = 0;
            lp.status = false;
        }
        status = lp.status;
    }

    /// @inheritdoc IUniswapLiquidityManager
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external override {
        address sender = msg.sender;
        MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));
        _verifyCallback(decoded.token0, decoded.token1, decoded.fee);
        if (amount0Owed > 0) pay(decoded.token0, decoded.payer, sender, amount0Owed);
        if (amount1Owed > 0) pay(decoded.token1, decoded.payer, sender, amount1Owed);
    }

    /// @inheritdoc IUniswapLiquidityManager
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        address recipient = msg.sender;
        SwapCallbackData memory decoded = abi.decode(data, (SwapCallbackData));
        _verifyCallback(decoded.token0, decoded.token1, decoded.fee);
        if (amount0Delta > 0)
            pay(decoded.token0, address(this), recipient, uint256(amount0Delta));
        if (amount1Delta > 0)
            pay(decoded.token1, address(this), recipient, uint256(amount1Delta));
    }

    /// @inheritdoc IUniswapLiquidityManager
    function getReserves(
        address token0,
        address token1,
        bytes calldata data
    )
        external
        view
        override
        returns (
            uint256 totalAmount0,
            uint256 totalAmount1,
            uint256 totalLiquidity
        )
    {
        uint24 fee = abi.decode(data, (uint24));
        address pool = getPoolAddress(token0, token1, fee);
        (totalAmount0, totalAmount1, totalLiquidity) = updatePositionTotalAmounts(pool);
    }

    /// @notice Returns maximum amount of fees owed to a specific user position
    /// @dev Updates the unipilot base & range positions in order to fetch updated amount of user fees
    /// @param tokenId The ID of the Unpilot NFT for which tokens will be collected
    /// @return fees0 Amount of fees in token0
    /// @return fees1 Amount of fees in token1
    function getUserFees(uint256 tokenId)
        external
        returns (uint256 fees0, uint256 fees1)
    {
        Position memory position = positions[tokenId];
        _collectPositionFees(position.pool);
        LiquidityPosition memory lp = liquidityPositions[position.pool];
        (uint256 tokensOwed0, uint256 tokensOwed1) = UserPositions.getTokensOwedAmount(
            position.feeGrowth0,
            position.feeGrowth1,
            position.liquidity,
            lp.feeGrowthGlobal0,
            lp.feeGrowthGlobal1
        );

        fees0 = position.tokensOwed0.add(tokensOwed0);
        fees1 = position.tokensOwed1.add(tokensOwed1);
    }

    /// @inheritdoc IUniswapLiquidityManager
    function createPair(
        address _token0,
        address _token1,
        bytes memory data
    ) external override returns (address _pool) {
        (uint24 _fee, uint160 _sqrtPriceX96) = abi.decode(data, (uint24, uint160));
        _pool = IUniswapV3Factory(uniswapFactory).createPool(_token0, _token1, _fee);
        IUniswapV3Pool(_pool).initialize(_sqrtPriceX96);
        emit PoolCreated(_token0, _token1, _pool, _fee, _sqrtPriceX96);
    }

    /// @inheritdoc IUniswapLiquidityManager
    function deposit(
        address token0,
        address token1,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 shares,
        uint256 tokenId,
        bool isTokenMinted,
        bytes memory data
    ) external payable override onlyUnipilot {
        DepositVars memory b;
        b.fee = abi.decode(data, (uint24));
        b.pool = getPoolAddress(token0, token1, b.fee);
        LiquidityPosition storage poolPosition = liquidityPositions[b.pool];

        // updating the feeGrowthGlobal of pool for new user
        if (poolPosition.totalLiquidity > 0) _collectPositionFees(b.pool);
        (
            b.amount0Base,
            b.amount1Base,
            b.amount0Range,
            b.amount1Range
        ) = _addLiquidityInManager(
            AddLiquidityManagerParams({
                pool: b.pool,
                amount0Desired: amount0Desired,
                amount1Desired: amount1Desired,
                shares: shares
            })
        );

        if (!isTokenMinted) {
            Position storage userPosition = positions[tokenId];
            require(b.pool == userPosition.pool);
            userPosition.tokensOwed0 += FullMath.mulDiv(
                poolPosition.feeGrowthGlobal0 - userPosition.feeGrowth0,
                userPosition.liquidity,
                FixedPoint128.Q128
            );
            userPosition.tokensOwed1 += FullMath.mulDiv(
                poolPosition.feeGrowthGlobal1 - userPosition.feeGrowth1,
                userPosition.liquidity,
                FixedPoint128.Q128
            );
            userPosition.liquidity += shares;
            userPosition.feeGrowth0 = poolPosition.feeGrowthGlobal0;
            userPosition.feeGrowth1 = poolPosition.feeGrowthGlobal1;
        } else {
            positions[tokenId] = Position({
                nonce: 0,
                pool: b.pool,
                liquidity: shares,
                feeGrowth0: poolPosition.feeGrowthGlobal0,
                feeGrowth1: poolPosition.feeGrowthGlobal1,
                tokensOwed0: 0,
                tokensOwed1: 0
            });
        }

        _checkDustAmount(
            b.pool,
            (b.amount0Base + b.amount0Range),
            (b.amount1Base + b.amount1Range),
            amount0Desired,
            amount1Desired
        );

        emit Deposited(b.pool, tokenId, amount0Desired, amount1Desired, shares);
    }

    /// @inheritdoc IUniswapLiquidityManager
    function withdraw(
        bool pilotToken,
        bool wethToken,
        uint256 liquidity,
        uint256 tokenId,
        bytes memory data
    ) external payable override onlyUnipilot nonReentrant {
        Position storage position = positions[tokenId];
        require(liquidity > 0);
        require(liquidity <= position.liquidity);
        WithdrawVars memory c;
        c.recipient = abi.decode(data, (address));

        (c.amount0Removed, c.amount1Removed) = _removeLiquidityUniswap(
            false,
            position.pool,
            liquidity
        );

        (c.userAmount0, c.userAmount1, c.pilotAmount) = _distributeFeesAndLiquidity(
            DistributeFeesParams({
                pilotToken: pilotToken,
                wethToken: wethToken,
                pool: position.pool,
                recipient: c.recipient,
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Removed: c.amount0Removed,
                amount1Removed: c.amount1Removed
            })
        );

        emit Withdrawn(
            position.pool,
            c.recipient,
            tokenId,
            c.amount0Removed,
            c.amount1Removed
        );
    }

    /// @inheritdoc IUniswapLiquidityManager
    function collect(
        bool pilotToken,
        bool wethToken,
        uint256 tokenId,
        bytes memory data
    ) external payable override onlyUnipilot nonReentrant {
        Position memory position = positions[tokenId];
        require(position.liquidity > 0);
        address recipient = abi.decode(data, (address));

        _collectPositionFees(position.pool);

        _distributeFeesAndLiquidity(
            DistributeFeesParams({
                pilotToken: pilotToken,
                wethToken: wethToken,
                pool: position.pool,
                recipient: recipient,
                tokenId: tokenId,
                liquidity: 0,
                amount0Removed: 0,
                amount1Removed: 0
            })
        );
    }

    /// @dev Returns the status of the vault that needs reabsing
    function shouldReadjust(
        address pool,
        int24 baseTickLower,
        int24 baseTickUpper
    ) public view returns (bool readjust) {
        (, , , , , , int24 currentTick, ) = getPoolDetails(pool);
        int24 threshold = IUniStrategy(unipilotProtocolDetails.uniStrategy)
            .getReadjustThreshold(pool);
        if (
            (currentTick < (baseTickLower + threshold)) ||
            (currentTick > (baseTickUpper - threshold))
        ) {
            readjust = true;
        } else {
            readjust = false;
        }
    }

    function getPoolDetails(address pool)
        internal
        view
        returns (
            address token0,
            address token1,
            uint24 fee,
            uint16 poolCardinality,
            uint128 liquidity,
            uint160 sqrtPriceX96,
            int24 currentTick,
            int24 tickSpacing
        )
    {
        IUniswapV3Pool uniswapPool = IUniswapV3Pool(pool);
        token0 = uniswapPool.token0();
        token1 = uniswapPool.token1();
        fee = uniswapPool.fee();
        liquidity = uniswapPool.liquidity();
        (sqrtPriceX96, currentTick, , poolCardinality, , , ) = uniswapPool.slot0();
        tickSpacing = uniswapPool.tickSpacing();
    }

    /// @notice burns all positions, collects any fees accrued and mints new base & range positions for vault.
    /// @dev This function can be called by anyone, also user gets the tx fees + premium on chain for readjusting the vault
    /// @dev Only those vaults are eligible for readjust incentive that have liquidity greater than 100,000 USD through Unipilot,
    /// @dev Pools can be readjust 2 times in 24 hrs (more than 2 requirement means pool is too volatile)
    /// @dev If all assets are converted in a single token then 2% amount will be swapped from vault total liquidity
    /// in order to add in range liquidity rather than waiting for price to come in range
    function readjustLiquidity(
        address token0,
        address token1,
        uint24 fee
    ) external {
        // @dev calculating the gas amount at the begining
        uint256 initialGas = gasleft();
        ReadjustVars memory b;

        b.poolAddress = getPoolAddress(token0, token1, fee);
        LiquidityPosition storage position = liquidityPositions[b.poolAddress];

        require(!readjustFrequencyStatus(b.poolAddress));
        require(
            shouldReadjust(b.poolAddress, position.baseTickLower, position.baseTickUpper)
        );

        position.timestamp = block.timestamp;

        (, , , , , b.sqrtPriceX96, , ) = getPoolDetails(b.poolAddress);
        (b.amount0, b.amount1) = _removeLiquidityUniswap(
            true,
            b.poolAddress,
            position.totalLiquidity
        );

        if ((b.amount0 == 0 || b.amount1 == 0)) {
            (b.zeroForOne, b.amountIn) = b.amount0 > 0
                ? (true, b.amount0)
                : (false, b.amount1);
            b.exactSqrtPriceImpact =
                (b.sqrtPriceX96 * (unipilotProtocolDetails.swapPriceThreshold / 2)) /
                1e6;
            b.sqrtPriceLimitX96 = b.zeroForOne
                ? b.sqrtPriceX96 - b.exactSqrtPriceImpact
                : b.sqrtPriceX96 + b.exactSqrtPriceImpact;

            b.amountIn = FullMath.mulDiv(
                b.amountIn,
                unipilotProtocolDetails.swapPercentage,
                100
            );

            (int256 amount0Delta, int256 amount1Delta) = IUniswapV3Pool(b.poolAddress)
                .swap(
                    address(this),
                    b.zeroForOne,
                    b.amountIn.toInt256(),
                    b.sqrtPriceLimitX96,
                    abi.encode(
                        (SwapCallbackData({ token0: token0, token1: token1, fee: fee }))
                    )
                );

            if (amount1Delta < 1) {
                amount1Delta = -amount1Delta;
                b.amount0 = b.amount0.sub(uint256(amount0Delta));
                b.amount1 = b.amount1.add(uint256(amount1Delta));
            } else {
                amount0Delta = -amount0Delta;
                b.amount0 = b.amount0.add(uint256(amount0Delta));
                b.amount1 = b.amount1.sub(uint256(amount1Delta));
            }
        }
        // @dev calculating new ticks for base & range positions
        Tick memory ticks;
        (
            ticks.baseTickLower,
            ticks.baseTickUpper,
            ticks.bidTickLower,
            ticks.bidTickUpper,
            ticks.rangeTickLower,
            ticks.rangeTickUpper
        ) = _getTicksFromUniStrategy(b.poolAddress);

        (b.baseLiquidity, b.amount0Added, b.amount1Added, ) = _addLiquidityUniswap(
            AddLiquidityParams({
                token0: token0,
                token1: token1,
                fee: fee,
                tickLower: ticks.baseTickLower,
                tickUpper: ticks.baseTickUpper,
                amount0Desired: b.amount0,
                amount1Desired: b.amount1
            })
        );

        (position.baseLiquidity, position.baseTickLower, position.baseTickUpper) = (
            b.baseLiquidity,
            ticks.baseTickLower,
            ticks.baseTickUpper
        );

        uint256 amount0Remaining = b.amount0.sub(b.amount0Added);
        uint256 amount1Remaining = b.amount1.sub(b.amount1Added);

        (uint128 bidLiquidity, , ) = LiquidityReserves.getLiquidityAmounts(
            ticks.bidTickLower,
            ticks.bidTickUpper,
            0,
            amount0Remaining,
            amount1Remaining,
            IUniswapV3Pool(b.poolAddress)
        );
        (uint128 rangeLiquidity, , ) = LiquidityReserves.getLiquidityAmounts(
            ticks.rangeTickLower,
            ticks.rangeTickUpper,
            0,
            amount0Remaining,
            amount1Remaining,
            IUniswapV3Pool(b.poolAddress)
        );

        // @dev adding bid or range order on Uniswap depending on which token is left
        if (bidLiquidity > rangeLiquidity) {
            (, b.amount0Range, b.amount1Range, ) = _addLiquidityUniswap(
                AddLiquidityParams({
                    token0: token0,
                    token1: token1,
                    fee: fee,
                    tickLower: ticks.bidTickLower,
                    tickUpper: ticks.bidTickUpper,
                    amount0Desired: amount0Remaining,
                    amount1Desired: amount1Remaining
                })
            );

            (
                position.rangeLiquidity,
                position.rangeTickLower,
                position.rangeTickUpper
            ) = (bidLiquidity, ticks.bidTickLower, ticks.bidTickUpper);
        } else {
            (, b.amount0Range, b.amount1Range, ) = _addLiquidityUniswap(
                AddLiquidityParams({
                    token0: token0,
                    token1: token1,
                    fee: fee,
                    tickLower: ticks.rangeTickLower,
                    tickUpper: ticks.rangeTickUpper,
                    amount0Desired: amount0Remaining,
                    amount1Desired: amount1Remaining
                })
            );
            (
                position.rangeLiquidity,
                position.rangeTickLower,
                position.rangeTickUpper
            ) = (rangeLiquidity, ticks.rangeTickLower, ticks.rangeTickUpper);
        }

        position.counter += 1;
        if (position.counter == 2) position.status = true;

        if (position.managed) {
            require(tx.gasprice <= unipilotProtocolDetails.gasPriceLimit);
            b.gasUsed = (tx.gasprice.mul(initialGas.sub(gasleft()))).add(
                unipilotProtocolDetails.premium
            );
            b.pilotAmount = IOracle(unipilotProtocolDetails.oracle).ethToAsset(
                PILOT,
                unipilotProtocolDetails.pilotWethPair,
                b.gasUsed
            );
            _mintPilot(msg.sender, b.pilotAmount);
        }

        _checkDustAmount(
            b.poolAddress,
            (b.amount0Added + b.amount0Range),
            (b.amount1Added + b.amount1Range),
            b.amount0,
            b.amount1
        );

        emit PoolReajusted(
            b.poolAddress,
            position.baseLiquidity,
            position.rangeLiquidity,
            position.baseTickLower,
            position.baseTickUpper,
            position.rangeTickLower,
            position.rangeTickUpper
        );
    }

    function emergencyExit(address recipient, bytes[10] memory data)
        external
        onlyGovernance
    {
        for (uint256 i = 0; i < data.length; ++i) {
            (
                address token,
                address pool,
                int24 tickLower,
                int24 tickUpper,
                uint128 liquidity
            ) = abi.decode(data[i], (address, address, int24, int24, uint128));

            if (pool != address(0)) {
                IUniswapV3Pool(pool).burn(tickLower, tickUpper, liquidity);

                IUniswapV3Pool(pool).collect(
                    recipient,
                    tickLower,
                    tickUpper,
                    MAX_UINT128,
                    MAX_UINT128
                );
            }

            uint256 balanceToken = IERC20(token).balanceOf(address(this));
            if (balanceToken > 0) {
                TransferHelper.safeTransfer(token, recipient, balanceToken);
            }
        }
    }

    /// @inheritdoc IUniswapLiquidityManager
    function updatePositionTotalAmounts(address _pool)
        public
        view
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 totalLiquidity
        )
    {
        LiquidityPosition memory position = liquidityPositions[_pool];
        if (position.totalLiquidity > 0) {
            return LiquidityPositions.getTotalAmounts(position, _pool);
        }
    }

    function getPoolAddress(
        address token0,
        address token1,
        uint24 fee
    ) private view returns (address) {
        return IUniswapV3Factory(uniswapFactory).getPool(token0, token1, fee);
    }

    function _isUnipilot() private view {
        require(msg.sender == unipilotProtocolDetails.unipilot);
    }

    function _isGovernance() private view {
        require(msg.sender == IUnipilot(unipilotProtocolDetails.unipilot).governance());
    }

    function _mintPilot(address recipient, uint256 amount) private {
        IUnipilot(unipilotProtocolDetails.unipilot).mintPilot(recipient, amount);
    }

    /// @dev fetches the new ticks for base and range positions
    function _getTicksFromUniStrategy(address pool)
        private
        returns (
            int24 baseTickLower,
            int24 baseTickUpper,
            int24 bidTickLower,
            int24 bidTickUpper,
            int24 rangeTickLower,
            int24 rangeTickUpper
        )
    {
        return IUniStrategy(unipilotProtocolDetails.uniStrategy).getTicks(pool);
    }

    /// @dev checks the dust amount durnig deposit
    function _checkDustAmount(
        address pool,
        uint256 amount0Added,
        uint256 amount1Added,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) private {
        LiquidityPosition storage poolPosition = liquidityPositions[pool];
        uint256 dust0 = amount0Desired.sub(amount0Added);
        uint256 dust1 = amount1Desired.sub(amount1Added);

        if (dust0 > 0) {
            poolPosition.fees0 += dust0;
            poolPosition.feeGrowthGlobal0 += FullMath.mulDiv(
                dust0,
                FixedPoint128.Q128,
                poolPosition.totalLiquidity
            );
        }

        if (dust1 > 0) {
            poolPosition.fees1 += dust1;
            poolPosition.feeGrowthGlobal1 += FullMath.mulDiv(
                dust1,
                FixedPoint128.Q128,
                poolPosition.totalLiquidity
            );
        }
    }

    /// @dev Do zero-burns to poke a position on Uniswap so earned fees are
    /// updated. Should be called if total amounts needs to include up-to-date
    /// fees.
    function _updatePosition(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        IUniswapV3Pool pool
    ) private {
        if (liquidity > 0) {
            pool.burn(tickLower, tickUpper, 0);
        }
    }

    /// @notice Deposits user liquidity in a range order of Unipilot vault.
    /// @dev If the liquidity of vault is out of range then contract will add user liquidity in a range position
    /// of the vault, user liquidity gets in range as soon as vault will be rebase again by anyone
    /// @param pool Address of the uniswap pool
    /// @param amount0 The desired amount of token0 to be spent
    /// @param amount1 The desired amount of token1 to be spent,
    /// @param shares Amount of shares minted
    function _addRangeLiquidity(
        address pool,
        uint256 amount0,
        uint256 amount1,
        uint256 shares
    ) private returns (uint256 amount0Range, uint256 amount1Range) {
        RangeLiquidityVars memory b;
        (b.token0, b.token1, b.fee, , , , , ) = getPoolDetails(pool);
        LiquidityPosition storage position = liquidityPositions[pool];

        (b.rangeLiquidity, b.amount0Range, b.amount1Range, ) = _addLiquidityUniswap(
            AddLiquidityParams({
                token0: b.token0,
                token1: b.token1,
                fee: b.fee,
                tickLower: position.rangeTickLower,
                tickUpper: position.rangeTickUpper,
                amount0Desired: amount0,
                amount1Desired: amount1
            })
        );

        position.rangeLiquidity += b.rangeLiquidity;
        position.totalLiquidity += shares;
        (amount0Range, amount1Range) = (b.amount0Range, b.amount1Range);
    }

    /// @dev Deposits liquidity in a range on the UniswapV3 pool.
    /// @param params The params necessary to mint a position, encoded as `AddLiquidityParams`
    /// @return liquidity Amount of liquidity added in a range on UniswapV3
    /// @return amount0 Amount of token0 added in a range
    /// @return amount1 Amount of token1 added in a range
    /// @return pool Instance of the UniswapV3 pool
    function _addLiquidityUniswap(AddLiquidityParams memory params)
        private
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1,
            IUniswapV3Pool pool
        )
    {
        pool = IUniswapV3Pool(getPoolAddress(params.token0, params.token1, params.fee));
        (liquidity, , ) = LiquidityReserves.getLiquidityAmounts(
            params.tickLower,
            params.tickUpper,
            0,
            params.amount0Desired,
            params.amount1Desired,
            pool
        );

        (amount0, amount1) = pool.mint(
            address(this),
            params.tickLower,
            params.tickUpper,
            liquidity,
            abi.encode(
                (
                    MintCallbackData({
                        payer: address(this),
                        token0: params.token0,
                        token1: params.token1,
                        fee: params.fee
                    })
                )
            )
        );
    }

    function _removeLiquiditySingle(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 liquiditySharePercentage,
        IUniswapV3Pool pool
    ) private returns (RemoveLiquidity memory removedLiquidity) {
        uint256 amount0;
        uint256 amount1;

        uint128 liquidityRemoved = _uint256ToUint128(
            FullMath.mulDiv(liquidity, liquiditySharePercentage, 1e18)
        );

        if (liquidity > 0) {
            (amount0, amount1) = pool.burn(tickLower, tickUpper, liquidityRemoved);
        }

        (uint256 collect0, uint256 collect1) = pool.collect(
            address(this),
            tickLower,
            tickUpper,
            MAX_UINT128,
            MAX_UINT128
        );

        removedLiquidity = RemoveLiquidity(
            amount0,
            amount1,
            liquidityRemoved,
            collect0.sub(amount0),
            collect1.sub(amount1)
        );
    }

    /// @dev Do zero-burns to poke a position on Uniswap so earned fees & feeGrowthGlobal of vault are updated
    function _collectPositionFees(address _pool) private {
        LiquidityPosition storage position = liquidityPositions[_pool];
        IUniswapV3Pool pool = IUniswapV3Pool(_pool);

        _updatePosition(
            position.baseTickLower,
            position.baseTickUpper,
            position.baseLiquidity,
            pool
        );
        _updatePosition(
            position.rangeTickLower,
            position.rangeTickUpper,
            position.rangeLiquidity,
            pool
        );

        (uint256 collect0Base, uint256 collect1Base) = pool.collect(
            address(this),
            position.baseTickLower,
            position.baseTickUpper,
            MAX_UINT128,
            MAX_UINT128
        );

        (uint256 collect0Range, uint256 collect1Range) = pool.collect(
            address(this),
            position.rangeTickLower,
            position.rangeTickUpper,
            MAX_UINT128,
            MAX_UINT128
        );

        position.fees0 = position.fees0.add((collect0Base.add(collect0Range)));
        position.fees1 = position.fees1.add((collect1Base.add(collect1Range)));

        position.feeGrowthGlobal0 += FullMath.mulDiv(
            collect0Base + collect0Range,
            FixedPoint128.Q128,
            position.totalLiquidity
        );
        position.feeGrowthGlobal1 += FullMath.mulDiv(
            collect1Base + collect1Range,
            FixedPoint128.Q128,
            position.totalLiquidity
        );
    }

    /// @notice Increases the amount of liquidity in a base & range positions of the vault, with tokens paid by the sender
    /// @param pool Address of the uniswap pool
    /// @param amount0Desired The desired amount of token0 to be spent
    /// @param amount1Desired The desired amount of token1 to be spent,
    /// @param shares Amount of shares minted
    function _increaseLiquidity(
        address pool,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 shares
    )
        private
        returns (
            uint256 amount0Base,
            uint256 amount1Base,
            uint256 amount0Range,
            uint256 amount1Range
        )
    {
        LiquidityPosition storage position = liquidityPositions[pool];
        IncreaseParams memory a;
        (a.token0, a.token1, a.fee, , , , a.currentTick, ) = getPoolDetails(pool);

        if (
            a.currentTick < position.baseTickLower ||
            a.currentTick > position.baseTickUpper
        ) {
            (amount0Range, amount1Range) = _addRangeLiquidity(
                pool,
                amount0Desired,
                amount1Desired,
                shares
            );
        } else {
            uint256 liquidityOffset = a.currentTick >= position.rangeTickLower &&
                a.currentTick <= position.rangeTickUpper
                ? 1
                : 0;
            (a.baseLiquidity, a.baseAmount0, a.baseAmount1, ) = _addLiquidityUniswap(
                AddLiquidityParams({
                    token0: a.token0,
                    token1: a.token1,
                    fee: a.fee,
                    tickLower: position.baseTickLower,
                    tickUpper: position.baseTickUpper,
                    amount0Desired: amount0Desired.sub(liquidityOffset),
                    amount1Desired: amount1Desired.sub(liquidityOffset)
                })
            );

            (a.rangeLiquidity, a.rangeAmount0, a.rangeAmount1, ) = _addLiquidityUniswap(
                AddLiquidityParams({
                    token0: a.token0,
                    token1: a.token1,
                    fee: a.fee,
                    tickLower: position.rangeTickLower,
                    tickUpper: position.rangeTickUpper,
                    amount0Desired: amount0Desired.sub(a.baseAmount0),
                    amount1Desired: amount1Desired.sub(a.baseAmount1)
                })
            );

            position.baseLiquidity += a.baseLiquidity;
            position.rangeLiquidity += a.rangeLiquidity;
            position.totalLiquidity += shares;
            (amount0Base, amount1Base) = (a.baseAmount0, a.baseAmount1);
            (amount0Range, amount1Range) = (a.rangeAmount0, a.rangeAmount1);
        }
    }

    /// @dev Two orders are placed - a base order and a range order. The base
    /// order is placed first with as much liquidity as possible. This order
    /// should use up all of one token, leaving only the other one. This excess
    /// amount is then placed as a single-sided bid or ask order.
    function _addLiquidityInManager(AddLiquidityManagerParams memory params)
        private
        returns (
            uint256 amount0Base,
            uint256 amount1Base,
            uint256 amount0Range,
            uint256 amount1Range
        )
    {
        TokenDetails memory tokenDetails;
        (
            tokenDetails.token0,
            tokenDetails.token1,
            tokenDetails.fee,
            tokenDetails.poolCardinality,
            ,
            ,
            tokenDetails.currentTick,

        ) = getPoolDetails(params.pool);
        LiquidityPosition storage position = liquidityPositions[params.pool];

        if (position.totalLiquidity > 0) {
            (amount0Base, amount1Base, amount0Range, amount1Range) = _increaseLiquidity(
                params.pool,
                params.amount0Desired,
                params.amount1Desired,
                params.shares
            );
        } else {
            if (
                tokenDetails.poolCardinality <
                unipilotProtocolDetails.poolCardinalityDesired
            )
                IUniswapV3Pool(params.pool).increaseObservationCardinalityNext(
                    unipilotProtocolDetails.poolCardinalityDesired
                );

            // @dev calculate new ticks for base & range order
            Tick memory ticks;
            (
                ticks.baseTickLower,
                ticks.baseTickUpper,
                ticks.bidTickLower,
                ticks.bidTickUpper,
                ticks.rangeTickLower,
                ticks.rangeTickUpper
            ) = _getTicksFromUniStrategy(params.pool);

            if (position.baseTickLower != 0 && position.baseTickUpper != 0) {
                if (
                    tokenDetails.currentTick < position.baseTickLower ||
                    tokenDetails.currentTick > position.baseTickUpper
                ) {
                    (amount0Range, amount1Range) = _addRangeLiquidity(
                        params.pool,
                        params.amount0Desired,
                        params.amount1Desired,
                        params.shares
                    );
                }
            } else {
                (
                    tokenDetails.baseLiquidity,
                    tokenDetails.amount0Added,
                    tokenDetails.amount1Added,

                ) = _addLiquidityUniswap(
                    AddLiquidityParams({
                        token0: tokenDetails.token0,
                        token1: tokenDetails.token1,
                        fee: tokenDetails.fee,
                        tickLower: ticks.baseTickLower,
                        tickUpper: ticks.baseTickUpper,
                        amount0Desired: params.amount0Desired,
                        amount1Desired: params.amount1Desired
                    })
                );

                (
                    position.baseLiquidity,
                    position.baseTickLower,
                    position.baseTickUpper
                ) = (
                    tokenDetails.baseLiquidity,
                    ticks.baseTickLower,
                    ticks.baseTickUpper
                );
                {
                    uint256 amount0 = params.amount0Desired.sub(
                        tokenDetails.amount0Added
                    );
                    uint256 amount1 = params.amount1Desired.sub(
                        tokenDetails.amount1Added
                    );

                    (tokenDetails.bidLiquidity, , ) = LiquidityReserves
                        .getLiquidityAmounts(
                            ticks.bidTickLower,
                            ticks.bidTickUpper,
                            0,
                            amount0,
                            amount1,
                            IUniswapV3Pool(params.pool)
                        );
                    (tokenDetails.rangeLiquidity, , ) = LiquidityReserves
                        .getLiquidityAmounts(
                            ticks.rangeTickLower,
                            ticks.rangeTickUpper,
                            0,
                            amount0,
                            amount1,
                            IUniswapV3Pool(params.pool)
                        );

                    // adding bid or range order on Uniswap depending on which token is left
                    if (tokenDetails.bidLiquidity > tokenDetails.rangeLiquidity) {
                        (, amount0Range, amount1Range, ) = _addLiquidityUniswap(
                            AddLiquidityParams({
                                token0: tokenDetails.token0,
                                token1: tokenDetails.token1,
                                fee: tokenDetails.fee,
                                tickLower: ticks.bidTickLower,
                                tickUpper: ticks.bidTickUpper,
                                amount0Desired: amount0,
                                amount1Desired: amount1
                            })
                        );

                        (
                            position.rangeLiquidity,
                            position.rangeTickLower,
                            position.rangeTickUpper
                        ) = (
                            tokenDetails.bidLiquidity,
                            ticks.bidTickLower,
                            ticks.bidTickUpper
                        );
                        (amount0Base, amount1Base) = (
                            tokenDetails.amount0Added,
                            tokenDetails.amount1Added
                        );
                    } else {
                        (, amount0Range, amount1Range, ) = _addLiquidityUniswap(
                            AddLiquidityParams({
                                token0: tokenDetails.token0,
                                token1: tokenDetails.token1,
                                fee: tokenDetails.fee,
                                tickLower: ticks.rangeTickLower,
                                tickUpper: ticks.rangeTickUpper,
                                amount0Desired: amount0,
                                amount1Desired: amount1
                            })
                        );
                        (
                            position.rangeLiquidity,
                            position.rangeTickLower,
                            position.rangeTickUpper
                        ) = (
                            tokenDetails.rangeLiquidity,
                            ticks.rangeTickLower,
                            ticks.rangeTickUpper
                        );
                        (amount0Base, amount1Base) = (
                            tokenDetails.amount0Added,
                            tokenDetails.amount1Added
                        );
                    }
                }
                position.totalLiquidity = position.totalLiquidity.add(params.shares);
            }
        }
    }

    /// @notice Convert 100% fees of the user in PILOT and transfer it to user
    /// @dev token0 & token1 amount of user fees will be transfered to index fund
    /// @param _recipient The account that should receive the PILOT,
    /// @param _token0 The address of the token0 for a specific pool
    /// @param _token1 The address of the token0 for a specific pool
    /// @param _tokensOwed0 The uncollected amount of token0 fees to the user position as of the last computation
    /// @param _tokensOwed1 The uncollected amount of token1 fees to the user position as of the last computation
    function _distributeFeesInPilot(
        address _recipient,
        address _token0,
        address _token1,
        uint256 _tokensOwed0,
        uint256 _tokensOwed1,
        address _oracle0,
        address _oracle1
    ) private returns (uint256 _pilotAmount) {
        // if the incoming pair is weth pair then compute the amount
        // of PILOT w.r.t alt token amount and the weth amount
        uint256 _pilotAmountInitial = _token0 == WETH
            ? IOracle(unipilotProtocolDetails.oracle).getPilotAmountWethPair(
                _token1,
                _tokensOwed1,
                _tokensOwed0,
                _oracle1
            )
            : IOracle(unipilotProtocolDetails.oracle).getPilotAmountForTokens(
                _token0,
                _token1,
                _tokensOwed0,
                _tokensOwed1,
                _oracle0,
                _oracle1
            );

        _pilotAmount = FullMath.mulDiv(
            _pilotAmountInitial,
            unipilotProtocolDetails.userPilotPercentage,
            100
        );

        _mintPilot(_recipient, _pilotAmount);

        if (_tokensOwed0 > 0)
            TransferHelper.safeTransfer(
                _token0,
                unipilotProtocolDetails.indexFund,
                _tokensOwed0
            );
        if (_tokensOwed1 > 0)
            TransferHelper.safeTransfer(
                _token1,
                unipilotProtocolDetails.indexFund,
                _tokensOwed1
            );
    }

    /// @notice Distribute the maximum amount of fees after calculating the percentage of user & index fund
    /// @dev Total fees of user will be distributed in two parts i.e 98% will be transferred to user & remaining 2% to index fund
    /// @param wethToken Boolean if the user wants fees in WETH or ETH, always false if it is not weth/alt pair
    /// @param _recipient The account that should receive the PILOT,
    /// @param _token0 The address of the token0 for a specific pool
    /// @param _token1 The address of the token0 for a specific pool
    /// @param _tokensOwed0 The uncollected amount of token0 fees to the user position as of the last computation
    /// @param _tokensOwed1 The uncollected amount of token1 fees to the user position as of the last computation
    function _distributeFeesInTokens(
        bool wethToken,
        address _recipient,
        address _token0,
        address _token1,
        uint256 _tokensOwed0,
        uint256 _tokensOwed1
    ) private {
        (
            uint256 _indexAmount0,
            uint256 _indexAmount1,
            uint256 _userBalance0,
            uint256 _userBalance1
        ) = UserPositions.getUserAndIndexShares(
                _tokensOwed0,
                _tokensOwed1,
                unipilotProtocolDetails.feesPercentageIndexFund
            );

        if (_tokensOwed0 > 0) {
            if (_token0 == WETH && !wethToken) {
                IWETH9(WETH).withdraw(_userBalance0);
                TransferHelper.safeTransferETH(_recipient, _userBalance0);
            } else {
                TransferHelper.safeTransfer(_token0, _recipient, _userBalance0);
            }
            TransferHelper.safeTransfer(
                _token0,
                unipilotProtocolDetails.indexFund,
                _indexAmount0
            );
        }

        if (_tokensOwed1 > 0) {
            if (_token1 == WETH && !wethToken) {
                IWETH9(WETH).withdraw(_userBalance1);
                TransferHelper.safeTransferETH(_recipient, _userBalance1);
            } else {
                TransferHelper.safeTransfer(_token1, _recipient, _userBalance1);
            }
            TransferHelper.safeTransfer(
                _token1,
                unipilotProtocolDetails.indexFund,
                _indexAmount1
            );
        }
    }

    /// @notice Transfer the amount of liquidity to user which has been removed from base & range position of the vault
    /// @param _token0 The address of the token0 for a specific pool
    /// @param _token1 The address of the token1 for a specific pool
    /// @param wethToken Boolean whether to recieve liquidity in WETH or ETH (only valid for WETH/ALT pairs)
    /// @param _recipient The account that should receive the liquidity amounts
    /// @param amount0Removed The amount of token0 that has been removed from base & range positions
    /// @param amount1Removed The amount of token1 that has been removed from base & range positions
    function _transferLiquidity(
        address _token0,
        address _token1,
        bool wethToken,
        address _recipient,
        uint256 amount0Removed,
        uint256 amount1Removed
    ) private {
        if (_token0 == WETH || _token1 == WETH) {
            (
                address tokenAlt,
                uint256 altAmount,
                address tokenWeth,
                uint256 wethAmount
            ) = _token0 == WETH
                    ? (_token1, amount1Removed, _token0, amount0Removed)
                    : (_token0, amount0Removed, _token1, amount1Removed);

            if (wethToken) {
                if (amount0Removed > 0)
                    TransferHelper.safeTransfer(tokenWeth, _recipient, wethAmount);
                if (amount1Removed > 0)
                    TransferHelper.safeTransfer(tokenAlt, _recipient, altAmount);
            } else {
                if (wethAmount > 0) {
                    IWETH9(WETH).withdraw(wethAmount);
                    TransferHelper.safeTransferETH(_recipient, wethAmount);
                }
                if (altAmount > 0)
                    TransferHelper.safeTransfer(tokenAlt, _recipient, altAmount);
            }
        } else {
            if (amount0Removed > 0)
                TransferHelper.safeTransfer(_token0, _recipient, amount0Removed);
            if (amount1Removed > 0)
                TransferHelper.safeTransfer(_token1, _recipient, amount1Removed);
        }
    }

    function _distributeFeesAndLiquidity(DistributeFeesParams memory params)
        private
        returns (
            uint256 userAmount0,
            uint256 userAmount1,
            uint256 pilotAmount
        )
    {
        WithdrawTokenOwedParams memory a;
        LiquidityPosition storage position = liquidityPositions[params.pool];
        Position storage userPosition = positions[params.tokenId];
        (a.token0, a.token1, , , , , , ) = getPoolDetails(params.pool);

        (a.tokensOwed0, a.tokensOwed1) = UserPositions.getTokensOwedAmount(
            userPosition.feeGrowth0,
            userPosition.feeGrowth1,
            userPosition.liquidity,
            position.feeGrowthGlobal0,
            position.feeGrowthGlobal1
        );

        userPosition.tokensOwed0 += a.tokensOwed0;
        userPosition.tokensOwed1 += a.tokensOwed1;
        userPosition.feeGrowth0 = position.feeGrowthGlobal0;
        userPosition.feeGrowth1 = position.feeGrowthGlobal1;

        if (position.feesInPilot && params.pilotToken) {
            if (a.token0 == WETH || a.token1 == WETH) {
                (
                    address tokenAlt,
                    uint256 altAmount,
                    address altOracle,
                    address tokenWeth,
                    uint256 wethAmount,
                    address wethOracle
                ) = a.token0 == WETH
                        ? (
                            a.token1,
                            userPosition.tokensOwed1,
                            position.oracle1,
                            a.token0,
                            userPosition.tokensOwed0,
                            position.oracle0
                        )
                        : (
                            a.token0,
                            userPosition.tokensOwed0,
                            position.oracle0,
                            a.token1,
                            userPosition.tokensOwed1,
                            position.oracle1
                        );

                pilotAmount = _distributeFeesInPilot(
                    params.recipient,
                    tokenWeth,
                    tokenAlt,
                    wethAmount,
                    altAmount,
                    wethOracle,
                    altOracle
                );
            } else {
                pilotAmount = _distributeFeesInPilot(
                    params.recipient,
                    a.token0,
                    a.token1,
                    userPosition.tokensOwed0,
                    userPosition.tokensOwed1,
                    position.oracle0,
                    position.oracle1
                );
            }
        } else {
            _distributeFeesInTokens(
                params.wethToken,
                params.recipient,
                a.token0,
                a.token1,
                userPosition.tokensOwed0,
                userPosition.tokensOwed1
            );
        }

        _transferLiquidity(
            a.token0,
            a.token1,
            params.wethToken,
            params.recipient,
            params.amount0Removed,
            params.amount1Removed
        );

        (userAmount0, userAmount1) = (userPosition.tokensOwed0, userPosition.tokensOwed1);
        position.fees0 = position.fees0.sub(userPosition.tokensOwed0);
        position.fees1 = position.fees1.sub(userPosition.tokensOwed1);

        userPosition.tokensOwed0 = 0;
        userPosition.tokensOwed1 = 0;
        userPosition.liquidity = userPosition.liquidity.sub(params.liquidity);

        emit Collect(
            params.tokenId,
            userAmount0,
            userAmount1,
            pilotAmount,
            params.pool,
            params.recipient
        );
    }

    /// @notice Decreases the amount of liquidity (base and range positions) from Uniswap pool and collects all fees in the process.
    /// @dev Total liquidity of Unipilot vault won't decrease in readjust because same liquidity amount is added
    /// again in Uniswap, total liquidity will only decrease if user is withdrawing his share from vault
    /// @param isRebase Boolean for the readjust liquidity function for not decreasing the total liquidity of vault
    /// @param pool Address of the Uniswap pool
    /// @param liquidity Liquidity amount of vault to remove from Uniswap positions
    /// @return amount0Removed The amount of token0 removed from base & range positions
    /// @return amount1Removed The amount of token1 removed from base & range positions
    function _removeLiquidityUniswap(
        bool isRebase,
        address pool,
        uint256 liquidity
    ) private returns (uint256 amount0Removed, uint256 amount1Removed) {
        LiquidityPosition storage position = liquidityPositions[pool];
        IUniswapV3Pool uniswapPool = IUniswapV3Pool(pool);

        uint256 liquiditySharePercentage = FullMath.mulDiv(
            liquidity,
            1e18,
            position.totalLiquidity
        );

        RemoveLiquidity memory bl = _removeLiquiditySingle(
            position.baseTickLower,
            position.baseTickUpper,
            position.baseLiquidity,
            liquiditySharePercentage,
            uniswapPool
        );
        RemoveLiquidity memory rl = _removeLiquiditySingle(
            position.rangeTickLower,
            position.rangeTickUpper,
            position.rangeLiquidity,
            liquiditySharePercentage,
            uniswapPool
        );

        position.fees0 = position.fees0.add(bl.feesCollected0.add(rl.feesCollected0));
        position.fees1 = position.fees1.add(bl.feesCollected1.add(rl.feesCollected1));

        position.feeGrowthGlobal0 += FullMath.mulDiv(
            bl.feesCollected0 + rl.feesCollected0,
            FixedPoint128.Q128,
            position.totalLiquidity
        );
        position.feeGrowthGlobal1 += FullMath.mulDiv(
            bl.feesCollected1 + rl.feesCollected1,
            FixedPoint128.Q128,
            position.totalLiquidity
        );

        amount0Removed = bl.amount0.add(rl.amount0);
        amount1Removed = bl.amount1.add(rl.amount1);

        if (!isRebase) {
            position.totalLiquidity = position.totalLiquidity.sub(liquidity);
        }

        position.baseLiquidity = position.baseLiquidity - bl.liquidityRemoved;
        position.rangeLiquidity = position.rangeLiquidity - rl.liquidityRemoved;

        // @dev reseting the positions to initial state if total liquidity of vault gets zero
        /// in order to calculate the amounts correctly from getSharesAndAmounts
        if (position.totalLiquidity == 0) {
            (position.baseTickLower, position.baseTickUpper) = (0, 0);
            (position.rangeTickLower, position.rangeTickUpper) = (0, 0);
        }
    }

    /// @notice Verify that caller should be the address of a valid Uniswap V3 Pool
    /// @param token0 The contract address of token0
    /// @param token1 The contract address of token1
    /// @param fee Fee tier of the pool
    function _verifyCallback(
        address token0,
        address token1,
        uint24 fee
    ) private view {
        require(msg.sender == getPoolAddress(token0, token1, fee));
    }

    function _uint256ToUint128(uint256 value) private pure returns (uint128) {
        assert(value <= type(uint128).max);
        return uint128(value);
    }
}
