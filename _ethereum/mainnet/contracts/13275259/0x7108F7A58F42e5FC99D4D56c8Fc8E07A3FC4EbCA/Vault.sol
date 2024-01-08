pragma solidity >=0.7.5;
pragma abicoder v2;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV3MintCallback.sol";
import "./IUniswapV3SwapCallback.sol";
import "./ISwapRouter.sol";
import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./LiquidityAmounts.sol";
import "./PositionKey.sol";

import "./IERC20Metadata.sol";
import "./IVault.sol";
import "./IFactory.sol";

import "./LongMath.sol";

contract Vault is
    IVault,
    IUniswapV3MintCallback,
    IUniswapV3SwapCallback,
    ERC20,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using LongMath for uint256;
    using SafeERC20 for IERC20Metadata;
    // using VaultMath for IVault;

    IFactory public override factory;
    ISwapRouter public swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IUniswapV3Pool public immutable override pool;
    IERC20Metadata public immutable override token0;
    IERC20Metadata public immutable override token1;

    bool public pauseStrategy;
    bool public pauseUser;

    uint256 public protocolFee;
    uint256 public strategyFee;
    uint256 public maxTotalSupply;

    uint256 public accruedProtocolFees0;
    uint256 public accruedStrategyFees0;
    uint256 public accruedProtocolFees1;
    uint256 public accruedStrategyFees1;

    int24 public immutable override tickSpacing;
    int24 public override baseLower;
    int24 public override baseUpper;
    int24 public override limitLower;
    int24 public override limitUpper;

    /**
     * @dev Needs to be called by the Factory contract
     * @param _pool Underlying Uniswap V3 pool
     * @param _protocolFee Protocol fee expressed as multiple of 1e-6
     * @param _strategyFee Protocol fee expressed as multiple of 1e-6
     * @param _maxTotalSupply Cap on total supply
     */
    constructor(
        address _pool,
        uint256 _protocolFee,
        uint256 _strategyFee,
        uint256 _maxTotalSupply
    ) ERC20("Aastra Vault", "AASTRA-ETHPUT") {
        factory = IFactory(msg.sender);
        pool = IUniswapV3Pool(_pool);
        token0 = IERC20Metadata(IUniswapV3Pool(_pool).token0());
        token1 = IERC20Metadata(IUniswapV3Pool(_pool).token1());
        tickSpacing = IUniswapV3Pool(_pool).tickSpacing();

        protocolFee = _protocolFee;
        strategyFee = _strategyFee;

        if (_maxTotalSupply > 0) maxTotalSupply = _maxTotalSupply;
        else maxTotalSupply = type(uint256).max;
    }

    /// @notice Fetches the governance address from factory.
    function governance() public view returns (address) {
        return factory.governance();
    }

    /// @notice Fetches the vault manager from factory
    function strategy() public view override returns (address) {
        return factory.vaultManager(address(this));
    }

    /// @notice Fetches the current router address from factory.
    function router() public view override returns (address) {
        return factory.router();
    }

    /// @inheritdoc IVault
    function deposit(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    )
        external
        override
        nonReentrant
        onlyUser
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        )
    {
        require(
            amount0Desired > 0 || amount1Desired > 0,
            "amount0Desired or amount1Desired"
        );
        require(to != address(0) && to != address(this), "to");

        // Poke positions so vault's current holdings are up-to-date
        poke(baseLower, baseUpper);
        poke(limitLower, limitUpper);

        // Calculate amounts proportional to vault's holdings
        (shares, amount0, amount1) = _calcSharesAndAmounts(
            amount0Desired,
            amount1Desired
        );

        require(shares > 0, "shares");
        require(amount0 >= amount0Min, "amount0Min");
        require(amount1 >= amount1Min, "amount1Min");

        // Pull in tokens from sender
        if (amount0 > 0)
            token0.safeTransferFrom(msg.sender, address(this), amount0);
        if (amount1 > 0)
            token1.safeTransferFrom(msg.sender, address(this), amount1);

        (uint256 baseAmount0, uint256 baseAmount1) = getPositionAmounts(
            baseLower,
            baseUpper
        );
        (uint256 limitAmount0, uint256 limitAmount1) = getPositionAmounts(
            limitLower,
            limitUpper
        );
        {
            (uint256 totalAmount0, uint256 totalAmount1) = getTotalAmounts();
            
            uint256 baseMintAmount0; 
            uint256 baseMintAmount1 ;
            uint256 limitMintAmount0;
            uint256 limitMintAmount1 ;
            
            if (totalAmount0>0){
                baseMintAmount0 = amount0.mul(baseAmount0).div(
                    totalAmount0
                );
                limitMintAmount0 = amount0.mul(limitAmount0).div(
                    totalAmount0
                );
            }
            if (totalAmount1>0){
                baseMintAmount1 = amount1.mul(baseAmount1).div(
                    totalAmount1
                );
                limitMintAmount1 = amount1.mul(limitAmount1).div(
                    totalAmount1
                );
            }
            // Mint tokens
            if (baseMintAmount0 > 0 || baseMintAmount1 > 0) {
                uint128 baseLiquidity = _liquidityForAmounts(
                    baseLower,
                    baseUpper,
                    baseMintAmount0,
                    baseMintAmount1
                );
                mintLiquidity(baseLower, baseUpper, baseLiquidity);
            }

            if (limitMintAmount0 > 0 || limitMintAmount1 > 0) {
                uint128 limitLiquidity = _liquidityForAmounts(
                    limitLower,
                    limitUpper,
                    limitMintAmount0,
                    limitMintAmount1
                );
                mintLiquidity(limitLower, limitUpper, limitLiquidity);
            }
        }
        // Mint shares to recipient
        _mint(to, shares);
        emit Deposit(msg.sender, to, shares, amount0, amount1);
        require(totalSupply() <= maxTotalSupply, "maxTotalSupply");
    }

    /// @inheritdoc IVault
    function withdraw(
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    )
        external
        override
        nonReentrant
        onlyUser
        returns (uint256 amount0, uint256 amount1)
    {
        require(shares > 0, "shares");
        require(to != address(0) && to != address(this), "to");
        uint256 totalSupply = totalSupply();

        // Burn shares
        _burn(msg.sender, shares);

        // Calculate token amounts proportional to unused balances
        uint256 unusedAmount0 = getBalance0().mul(shares).div(totalSupply);
        uint256 unusedAmount1 = getBalance1().mul(shares).div(totalSupply);

        // Withdraw proportion of liquidity from Uniswap pool
        (uint256 baseAmount0, uint256 baseAmount1) = burnLiquidityShare(
            baseLower,
            baseUpper,
            shares,
            totalSupply
        );

        (uint256 limitAmount0, uint256 limitAmount1) = burnLiquidityShare(
            limitLower,
            limitUpper,
            shares,
            totalSupply
        );

        // Sum up total amounts owed to recipient
        amount0 = unusedAmount0.add(baseAmount0).add(limitAmount0);
        amount1 = unusedAmount1.add(baseAmount1).add(limitAmount1);
        require(amount0 >= amount0Min, "amount0Min");
        require(amount1 >= amount1Min, "amount1Min");
        // Push tokens to recipient
        if (amount0 > 0) token0.safeTransfer(to, amount0);
        if (amount1 > 0) token1.safeTransfer(to, amount1);

        emit Withdraw(msg.sender, to, shares, amount0, amount1);
    }

    /// @inheritdoc IVault
    function poke(int24 tickLower, int24 tickUpper) public override {
        (uint128 liquidity, , , , ) = position(tickLower, tickUpper);
        if (liquidity > 0) {
            pool.burn(tickLower, tickUpper, 0);
        }
    }

    /// @dev Withdraws share of liquidity in a limit from Uniswap pool.
    function burnLiquidityShare(
        int24 tickLower,
        int24 tickUpper,
        uint256 shares,
        uint256 totalSupply
    ) internal returns (uint256 amount0, uint256 amount1) {
        (uint128 totalLiquidity, , , , ) = position(tickLower, tickUpper);
        uint256 liquidity = uint256(totalLiquidity).mul(shares).div(
            totalSupply
        );

        if (liquidity > 0) {
            (
                uint256 burned0,
                uint256 burned1,
                uint256 fees0,
                uint256 fees1
            ) = _burnAndCollect(tickLower, tickUpper, _toUint128(liquidity));

            // Add share of fees
            amount0 = burned0.add(fees0.mul(shares).div(totalSupply));
            amount1 = burned1.add(fees1.mul(shares).div(totalSupply));
        }
    }

    /// @notice Internal method to swap between token0 and token1 for vault funds
    function performOptimalSwap(
        uint256 actualAmount0,
        uint256 actualAmount1,
        uint256 amount0,
        uint256 amount1
    ) internal returns (uint256 token0AfterSwap, uint256 token1AfterSwap) {

        bool isToken0Excess;
        uint256 amountIn;
        uint256 amountOut;

        if (actualAmount1==0 || actualAmount0 == 0) {
            isToken0Excess = actualAmount0==0;
            amountIn = isToken0Excess? amount0: amount1;
        }
        else {
        // Round off the factors to 18 decimal places.
        uint256 factor = 10 **
            (uint256(18).sub(token1.decimals()).add(token0.decimals()));
        uint256 ratio = actualAmount1.mulDiv(factor, actualAmount0);
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint256 price = uint256(sqrtPriceX96).mul(uint256(sqrtPriceX96)).mul(
            factor
        ) >> (96 * 2);

        uint256 token0Converted = ratio.mulDiv(amount0, factor);
        isToken0Excess = amount1 < token0Converted;

        uint256 excessAmount = isToken0Excess ? token0Converted.sub(amount1).mulDiv(factor, ratio) : amount1.sub(token0Converted);
        amountIn = isToken0Excess
            ? excessAmount.mulDiv(ratio, price.add(ratio))
            : excessAmount.mulDiv(price, price.add(ratio));
        }
        if (amountIn > 0) {
            amountOut = swapTokensFromPool(isToken0Excess, amountIn);
        }

        token0AfterSwap = isToken0Excess
            ? amount0.sub(amountIn)
            : amount0.add(amountOut);

        token1AfterSwap = isToken0Excess
            ? amount1.add(amountOut)
            : amount1.sub(amountIn);

        
    }

    /// @inheritdoc IVault
    function mintOptimalLiquidity(
        int24 _lowerTick,
        int24 _upperTick,
        uint256 amount0,
        uint256 amount1,
        bool swapEnabled
    ) public override onlyRouter {

        (uint256 actualAmount0, uint256 actualAmount1) = _amountsForLiquidity(
            _lowerTick,
            _upperTick,
            _liquidityForAmounts(_lowerTick, _upperTick,10**token0.decimals(),10**token1.decimals())
        );


        if (swapEnabled) {
            (uint256 token0AfterSwap, uint256 token1AfterSwap) = performOptimalSwap(
                actualAmount0,
                actualAmount1,
                amount0,
                amount1
            );

            mintLiquidity(
                _lowerTick,
                _upperTick,
                _liquidityForAmounts(
                    _lowerTick,
                    _upperTick,
                    token0AfterSwap,
                    token1AfterSwap
                )
            );


        } else {
            mintLiquidity(
                _lowerTick,
                _upperTick,
                _liquidityForAmounts(
                    _lowerTick,
                    _upperTick,
                    amount0,
                    amount1
                )
            );
        }

    }

    /// @dev Deposits liquidity in a range on the Uniswap pool.
    function mintLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal {
        checkRange(tickLower, tickUpper);
        if (liquidity > 0) {
            pool.mint(address(this), tickLower, tickUpper, liquidity, "");
        }
    }

    /// @inheritdoc IVault
    function compoundFee() public override onlyRouter {

        collectFeeAndReinvest(baseLower, baseUpper);

        collectFeeAndReinvest(limitLower, limitUpper);
    }

    /// @dev Updates fee owed to vault, collects the fee and mints more liquidity into the same position
    /// @param tickLower Lower bound of the tick range
    /// @param tickUpper Upper bound of the tick range
    function collectFeeAndReinvest(int24 tickLower, int24 tickUpper) internal {
        poke(tickLower, tickUpper);

        (uint256 collect0, uint256 collect1) = pool.collect(
            address(this),
            tickLower,
            tickUpper,
            type(uint128).max,
            type(uint128).max
        );

        if (collect0 > 0 && collect1 > 0) {
            (uint256 fee0, uint256 fee1) = calculateFee(collect0, collect1);

            uint128 liquidity = _liquidityForAmounts(
                tickLower,
                tickUpper,
                fee0,
                fee1
            );
            mintLiquidity(tickLower, tickUpper, liquidity);
        }
    }

    /// @inheritdoc IVault
    function burnAndCollect(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    )
        public
        override
        onlyRouter
        returns (
            uint256 burned0,
            uint256 burned1,
            uint256 feesToVault0,
            uint256 feesToVault1
        )
    {
        return _burnAndCollect(tickLower, tickUpper, liquidity);
    }

    /// @dev Withdraws liquidity from a range and collects all fees in the
    /// process.
    function _burnAndCollect(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    )
        internal
        returns (
            uint256 burned0,
            uint256 burned1,
            uint256 feesToVault0,
            uint256 feesToVault1
        )
    {
        checkRange(tickLower, tickUpper);
        
        poke(tickLower, tickUpper);
        // Collect all earned fees
        (uint256 collectedFee0, uint256 collectedFee1) = pool.collect(
            address(this),
            tickLower,
            tickUpper,
            type(uint128).max,
            type(uint128).max
        );

        calculateFee(collectedFee0, collectedFee1);


        if (liquidity > 0) {
            (burned0, burned1) = pool.burn(tickLower, tickUpper, liquidity);
        

            // Collect all owed tokens including earned fees
            (uint256 collect0, uint256 collect1) = pool.collect(
                address(this),
                tickLower,
                tickUpper,
                type(uint128).max,
                type(uint128).max
            );
        }

        // feesToVault0 = collect0.sub(burned0);
        // feesToVault1 = collect1.sub(burned1);
        // calculateFee(feesToVault0, feesToVault1);
    }

    /// @dev Calculates fees owed to protocol and strategy from total fee earned
    function calculateFee(uint256 feesToVault0, uint256 feesToVault1)
        internal
        returns (uint256, uint256)
    {
        uint256 feesToProtocol0;
        uint256 feesToProtocol1;
        uint256 feesToStrategy0;
        uint256 feesToStrategy1;

        {
            // Update accrued protocol fees
            if (protocolFee > 0) {
                feesToProtocol0 = feesToVault0.mul(protocolFee).div(1e6);
                feesToProtocol1 = feesToVault1.mul(protocolFee).div(1e6);
                accruedProtocolFees0 = accruedProtocolFees0.add(
                    feesToProtocol0
                );
                accruedProtocolFees1 = accruedProtocolFees1.add(
                    feesToProtocol1
                );
            }

            if (strategyFee > 0) {
                feesToStrategy0 = feesToVault0.mul(strategyFee).div(1e6);
                feesToStrategy1 = feesToVault1.mul(strategyFee).div(1e6);
                accruedStrategyFees0 = accruedStrategyFees0.add(
                    feesToStrategy0
                );
                accruedStrategyFees1 = accruedStrategyFees1.add(
                    feesToStrategy1
                );
            }

            if (protocolFee > 0) {
                feesToVault0 = feesToVault0.sub(feesToProtocol0);
                feesToVault1 = feesToVault1.sub(feesToProtocol1);
            }
            if (strategyFee > 0) {
                feesToVault0 = feesToVault0.sub(feesToStrategy0);
                feesToVault1 = feesToVault1.sub(feesToStrategy1);
            }
        }

        emit CollectFees(
            feesToVault0,
            feesToVault1,
            feesToStrategy0,
            feesToStrategy1
        );

        return (feesToVault0, feesToVault1);
    }

   /// @inheritdoc IVault
    function swapTokensFromPool(bool direction, uint256 amountInToSwap)
        public
        override
        nonReentrant
        onlyRouter
        returns (uint256 amountOut)
    {
        address tokenInAddress = direction ? address(token0) : address(token1);
        address tokenOutAddress = direction ? address(token1) : address(token0);

        if (direction) {
            token0.approve(address(swapRouter), amountInToSwap);
        } else {
            token1.approve(address(swapRouter), amountInToSwap);
        }

        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenInAddress,
                tokenOut: tokenOutAddress,
                fee: pool.fee(),
                recipient: address(this),
                deadline: block.timestamp + 10,
                amountIn: amountInToSwap,
                amountOutMinimum: 1,
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(swapParams);
    }

    /// @inheritdoc IVault
    function collectProtocol(
        uint256 amount0,
        uint256 amount1,
        address to
    ) external override onlyGovernance {
        accruedProtocolFees0 = accruedProtocolFees0.sub(amount0);
        accruedProtocolFees1 = accruedProtocolFees1.sub(amount1);
        if (amount0 > 0) token0.safeTransfer(to, amount0);
        if (amount1 > 0) token1.safeTransfer(to, amount1);
    }

    /// @inheritdoc IVault
    function collectStrategy(
        uint256 amount0,
        uint256 amount1,
        address to
    ) external override onlyStrategy {
        accruedStrategyFees0 = accruedStrategyFees0.sub(amount0);
        accruedStrategyFees1 = accruedStrategyFees1.sub(amount1);
        if (amount0 > 0) token0.safeTransfer(to, amount0);
        if (amount1 > 0) token1.safeTransfer(to, amount1);
    }

    /// @inheritdoc IVault
    function setBaseTicks(int24 _baseLower, int24 _baseUpper)
        public
        override
        onlyRouter
    {
        (baseLower, baseUpper) = (_baseLower, _baseUpper);
    }

    /// @inheritdoc IVault
    function setLimitTicks(int24 _limitLower, int24 _limitUpper)
        public
        override
        onlyRouter
    {
        (limitLower, limitUpper) = (_limitLower, _limitUpper);
    }

    /// @inheritdoc IVault
    function setMaxTotalSupply(uint256 _maxTotalSupply)
        external
        override
        onlyGovernance
    {
        maxTotalSupply = _maxTotalSupply;
    }

    /// @inheritdoc IVault
    function emergencyBurnAndCollect(address to)
        external
        override
        onlyGovernance
    {

        if (baseLower < baseUpper) {
            (uint128 liquidityBase, , , , ) = position(baseLower, baseUpper);
            if (liquidityBase > 0) {
                pool.burn(baseLower, baseUpper, liquidityBase);
            }
            pool.collect(
                to,
                baseLower,
                baseUpper,
                type(uint128).max,
                type(uint128).max
            );
        }

        if (limitLower < limitUpper) {
            (uint128 liquidityLimit, , , , ) = position(limitLower, limitUpper);
            if (liquidityLimit > 0) {
                pool.burn(limitLower, limitUpper, liquidityLimit);
            }

            pool.collect(
                to,
                limitLower,
                limitUpper,
                type(uint128).max,
                type(uint128).max
            );
        }

        uint256 token0Balance = getBalance0();
        uint256 token1Balance = getBalance1();
        if (token0Balance > 0) token0.safeTransfer(to, getBalance0());
        if (token1Balance > 0) token1.safeTransfer(to, getBalance1());
    }

    /// @dev Calculates the largest possible `amount0` and `amount1` such that
    /// they're in the same proportion as total amounts, but not greater than
    /// `amount0Desired` and `amount1Desired` respectively.
    function _calcSharesAndAmounts(
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
        uint256 totalSupply = totalSupply();
        (uint256 total0, uint256 total1) = getTotalAmounts();

        // If total supply > 0, vault can't be empty
        assert(totalSupply == 0 || total0 > 0 || total1 > 0);

        if (totalSupply == 0) {
            // For first deposit, just use the amounts desired
            amount0 = amount0Desired;
            amount1 = amount1Desired;
            shares = Math.max(amount0, amount1);
        } else if (total0 == 0) {
            amount1 = amount1Desired;
            shares = amount1.mul(totalSupply).div(total1);
        } else if (total1 == 0) {
            amount0 = amount0Desired;
            shares = amount0.mul(totalSupply).div(total0);
        } else {
            uint256 cross = Math.min(
                amount0Desired.mul(total1),
                amount1Desired.mul(total0)
            );
            require(cross > 0, "cross");

            // Round up amounts
            amount0 = cross.sub(1).div(total1).add(1);
            amount1 = cross.sub(1).div(total0).add(1);
            shares = cross.mul(totalSupply).div(total0).div(total1);
        }
    }

    /// @inheritdoc IVault
    function getTotalAmounts()
        public
        view
        override
        returns (uint256 total0, uint256 total1)
    {
        (uint256 baseAmount0, uint256 baseAmount1) = getPositionAmounts(
            baseLower,
            baseUpper
        );
        (uint256 limitAmount0, uint256 limitAmount1) = getPositionAmounts(
            limitLower,
            limitUpper
        );
        total0 = getBalance0().add(baseAmount0).add(limitAmount0);
        total1 = getBalance1().add(baseAmount1).add(limitAmount1);
    }

    /// @inheritdoc IVault
    function getPositionAmounts(int24 tickLower, int24 tickUpper)
        public
        view
        override
        returns (uint256 amount0, uint256 amount1)
    {
        (
            uint128 liquidity,
            ,
            ,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = position(tickLower, tickUpper);
        (amount0, amount1) = _amountsForLiquidity(
            tickLower,
            tickUpper,
            liquidity
        );

        // Subtract protocol fees
        uint256 oneMinusFee = uint256(1e6).sub(protocolFee).sub(strategyFee);
        amount0 = amount0.add(uint256(tokensOwed0).mul(oneMinusFee).div(1e6));
        amount1 = amount1.add(uint256(tokensOwed1).mul(oneMinusFee).div(1e6));
    }

    /**
     * @notice Balance of token0 in vault not used in any position.
     * @return balance0 Balance of token0 in vault not used in any position
     */
    function getBalance0() public view override returns (uint256) {
        return
            token0.balanceOf(address(this)).sub(accruedProtocolFees0).sub(
                accruedStrategyFees0
            );
    }

    /**
     * @notice Balance of token1 in vault not used in any position.
     * @return balance1 Balance of token1 in vault not used in any position
     */
    function getBalance1() public view override returns (uint256) {
        return
            token1.balanceOf(address(this)).sub(accruedProtocolFees1).sub(
                accruedStrategyFees1
            );
    }


    /// @inheritdoc IVault
    function freezeStrategy(bool value) external override onlyGovernance {
        pauseStrategy = value;
    }

    /// @inheritdoc IVault
    function freezeUser(bool value) external override onlyGovernance {
        pauseUser = value;
    }

    /// @dev Casts uint256 to uint128 with overflow check.
    function _toUint128(uint256 x) internal pure returns (uint128) {
        assert(x <= type(uint128).max);
        return uint128(x);
    }

    modifier onlyGovernance() {
        require(msg.sender == governance(), "tx sender should be governance");
        _;
    }

    modifier onlyStrategy() {
        require(
            msg.sender == strategy() || msg.sender == router(),
            "tx sender should be either the strategy manager or router"
        );
        require(!pauseStrategy, "operations paused for strategy manager");
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == router(), "tx sender should be router");
        require(!pauseStrategy, "operations paused for strategy manager");
        _;
    }

    modifier onlyUser() {
        require(!pauseUser, "operations paused for vault users");
        _;
    }

    /// @inheritdoc IVault
    function position(int24 tickLower, int24 tickUpper)
        public
        view
        override
        returns (
            uint128,
            uint256,
            uint256,
            uint128,
            uint128
        )
    {
        bytes32 positionKey = PositionKey.compute(
            address(this),
            tickLower,
            tickUpper
        );

        return pool.positions(positionKey);
    }

    /// @dev Wrapper around `LiquidityAmounts.getLiquidityForAmounts()`.
    function _liquidityForAmounts(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) internal view returns (uint128) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                amount0,
                amount1
            );
    }

    /// @dev Wrapper around `LiquidityAmounts.getAmountsForLiquidity()`.
    function _amountsForLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal view returns (uint256, uint256) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity
            );
    }

    /// @dev validates tickRanges to be valid for V3 pool.
    function checkRange(int24 tickLower, int24 tickUpper) internal view {
        int24 _tickSpacing = tickSpacing;
        require(tickLower < tickUpper, "tickLower < tickUpper");
        require(tickLower >= TickMath.MIN_TICK, "tickLower too low");
        require(tickUpper <= TickMath.MAX_TICK, "tickUpper too high");
        require(tickLower % _tickSpacing == 0, "tickLower % tickSpacing");
        require(tickUpper % _tickSpacing == 0, "tickUpper % tickSpacing");
    }

    /// @dev Callback for Uniswap V3 pool.
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        require(msg.sender == address(pool));
        if (amount0 > 0) token0.safeTransfer(msg.sender, amount0);
        if (amount1 > 0) token1.safeTransfer(msg.sender, amount1);
    }

    /// @dev Callback for Uniswap V3 pool.
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) public override {
        require(msg.sender == address(pool));

        if (amount0Delta > 0)
            token0.safeTransfer(msg.sender, uint256(amount0Delta));
        if (amount1Delta > 0)
            token1.safeTransfer(msg.sender, uint256(amount1Delta));
    }
}
