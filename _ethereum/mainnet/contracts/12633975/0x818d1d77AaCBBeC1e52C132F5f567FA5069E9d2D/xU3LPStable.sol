// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC20Upgradeable.sol";

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IUniswapV3Pool.sol";
import "./TickMath.sol";

import "./ISwapRouter.sol";
import "./INonfungiblePositionManager.sol";
import "./LiquidityAmounts.sol";

import "./ABDKMath64x64.sol";
import "./Utils.sol";
import "./BlockLock.sol";

contract xU3LPStable is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    BlockLock
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant LIQUIDATION_TIME_PERIOD = 4 weeks;
    uint256 private constant INITIAL_SUPPLY_MULTIPLIER = 1;
    uint256 private constant BUFFER_TARGET = 20; // 5% target
    uint256 private constant SWAP_SLIPPAGE = 100; // 1%
    uint256 private constant MINT_BURN_SLIPPAGE = 100; // 1%
    uint24 private constant POOL_FEE = 500;
    // Used to give an identical token representation
    uint8 private constant TOKEN_DECIMAL_REPRESENTATION = 18;

    int24 tickLower;
    int24 tickUpper;

    // Prices calculated using above ticks from TickMath.getSqrtRatioAtTick()
    uint160 priceLower;
    uint160 priceUpper;

    int128 lastTwap; // Last stored oracle twap
    // Max current twap vs last twap deviation percentage divisor (100 = 1%)
    uint256 maxTwapDeviationDivisor;

    IERC20 token0;
    IERC20 token1;

    IUniswapV3Pool pool;
    ISwapRouter router;
    INonfungiblePositionManager positionManager;

    uint256 public adminActiveTimestamp;
    uint256 public withdrawableToken0Fees;
    uint256 public withdrawableToken1Fees;
    uint256 public tokenId; // token id representing this uniswap position
    uint256 public token0DecimalMultiplier; // 10 ** (18 - token0 decimals)
    uint256 public token1DecimalMultiplier; // 10 ** (18 - token1 decimals)
    uint256 public tokenDiffDecimalMultiplier; // 10 ** (token0 decimals - token1 decimals)
    uint8 public token0Decimals;
    uint8 public token1Decimals;

    address private manager;
    address private manager2;

    struct FeeDivisors {
        uint256 mintFee;
        uint256 burnFee;
        uint256 claimFee;
    }

    FeeDivisors public feeDivisors;

    uint32 twapPeriod;

    event Rebalance();
    event PositionInitialized(int24 tickLower, int24 tickUpper);
    event PositionMigrated(int24 tickLower, int24 tickUpper);
    event FeeDivisorsSet(uint256 mintFee, uint256 burnFee, uint256 claimFee);
    event FeeWithdraw(uint256 token0Fee, uint256 token1Fee);

    function initialize(
        string memory _symbol,
        int24 _tickLower,
        int24 _tickUpper,
        IERC20 _token0,
        IERC20 _token1,
        IUniswapV3Pool _pool,
        ISwapRouter _router,
        INonfungiblePositionManager _positionManager,
        FeeDivisors memory _feeDivisors,
        uint256 _maxTwapDeviationDivisor,
        uint8 _token0Decimals,
        uint8 _token1Decimals
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained("xU3LP", _symbol);

        tickLower = _tickLower;
        tickUpper = _tickUpper;
        priceLower = TickMath.getSqrtRatioAtTick(_tickLower);
        priceUpper = TickMath.getSqrtRatioAtTick(_tickUpper);
        if (_token0 > _token1) {
            token0 = _token1;
            token1 = _token0;
            token0Decimals = _token1Decimals;
            token1Decimals = _token0Decimals;
        } else {
            token0 = _token0;
            token1 = _token1;
            token0Decimals = _token0Decimals;
            token1Decimals = _token1Decimals;
        }
        token0DecimalMultiplier =
            10**(TOKEN_DECIMAL_REPRESENTATION - token0Decimals);
        token1DecimalMultiplier =
            10**(TOKEN_DECIMAL_REPRESENTATION - token1Decimals);
        tokenDiffDecimalMultiplier =
            10**((Utils.subAbs(token0Decimals, token1Decimals)));

        maxTwapDeviationDivisor = _maxTwapDeviationDivisor;

        pool = _pool;
        router = _router;
        positionManager = _positionManager;

        token0.safeIncreaseAllowance(address(router), type(uint256).max);
        token1.safeIncreaseAllowance(address(router), type(uint256).max);
        token0.safeIncreaseAllowance(
            address(positionManager),
            type(uint256).max
        );
        token1.safeIncreaseAllowance(
            address(positionManager),
            type(uint256).max
        );

        lastTwap = getAsset0Price();
        _setFeeDivisors(_feeDivisors);
    }

    /* ========================================================================================= */
    /*                                            User-facing                                    */
    /* ========================================================================================= */

    /**
     *  @dev Mint xU3LP tokens by sending *amount* of *inputAsset* tokens
     */
    function mintWithToken(uint8 inputAsset, uint256 amount)
        external
        notLocked(msg.sender)
        whenNotPaused()
    {
        require(amount > 0);
        lock(msg.sender);
        checkTwap();
        if (inputAsset == 0) {
            token0.safeTransferFrom(msg.sender, address(this), amount);
            amount = getAmountInAsset1Terms(amount);
            uint256 fee = Utils.calculateFee(amount, feeDivisors.mintFee);
            _incrementWithdrawableToken0Fees(fee);
            _mintInternal(getToken0AmountInWei(amount.sub(fee)));
        } else {
            token1.safeTransferFrom(msg.sender, address(this), amount);
            amount = getAmountInAsset0Terms(amount);
            uint256 fee = Utils.calculateFee(amount, feeDivisors.mintFee);
            _incrementWithdrawableToken1Fees(fee);
            _mintInternal(getToken1AmountInWei(amount.sub(fee)));
        }
    }

    /**
     *  @dev Burn *amount* of xU3LP tokens to receive proportional
     *  amount of *outputAsset* tokens
     */
    function burn(uint8 outputAsset, uint256 amount)
        external
        notLocked(msg.sender)
    {
        require(amount > 0);
        lock(msg.sender);
        checkTwap();
        uint256 bufferBalance = getBufferBalance();
        uint256 totalBalance = bufferBalance.add(getStakedBalance());

        uint256 proRataBalance;
        if (outputAsset == 0) {
            proRataBalance = (totalBalance.mul(getAmountInAsset0Terms(amount)))
                .div(totalSupply());
        } else {
            proRataBalance = (
                totalBalance.mul(getAmountInAsset1Terms(amount)).div(
                    totalSupply()
                )
            );
        }

        // Add swap slippage to the calculations
        uint256 proRataBalanceWithSlippage =
            proRataBalance.add(proRataBalance.div(SWAP_SLIPPAGE));

        require(
            proRataBalanceWithSlippage <= bufferBalance,
            "Insufficient exit liquidity"
        );
        super._burn(msg.sender, amount);

        // Fee is in wei (18 decimals, so doesn't need to be normalized)
        uint256 fee = Utils.calculateFee(proRataBalance, feeDivisors.burnFee);
        if (outputAsset == 0) {
            withdrawableToken0Fees = withdrawableToken0Fees.add(fee);
        } else {
            withdrawableToken1Fees = withdrawableToken1Fees.add(fee);
        }
        uint256 transferAmount = proRataBalance.sub(fee);
        transferOnBurn(outputAsset, transferAmount);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        notLocked(msg.sender)
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override notLocked(sender) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    // Get net asset value priced in terms of asset0
    function getNav() public view returns (uint256) {
        return getStakedBalance().add(getBufferBalance());
    }

    // Get asset 1 twap
    function getAsset1Price() public view returns (int128) {
        return ABDKMath64x64.inv(getAsset0Price());
    }

    // Returns amount in terms of asset0
    function getAmountInAsset0Terms(uint256 amount)
        public
        view
        returns (uint256)
    {
        return ABDKMath64x64.mulu(getAsset1Price(), amount);
    }

    // Returns amount in terms of asset1
    function getAmountInAsset1Terms(uint256 amount)
        public
        view
        returns (uint256)
    {
        return ABDKMath64x64.mulu(getAsset0Price(), amount);
    }

    // Get total balance in the position
    function getStakedBalance() public view returns (uint256) {
        (uint256 amount0, uint256 amount1) = getStakedTokenBalance();
        return amount0.add(getAmountInAsset0Terms(amount1));
    }

    // Get balance in xU3LP contract
    function getBufferBalance() public view returns (uint256) {
        (uint256 balance0, uint256 balance1) = getBufferTokenBalance();
        return balance0.add(getAmountInAsset0Terms(balance1));
    }

    // Get wanted xU3LP contract balance - 5% of NAV
    function getTargetBufferBalance() public view returns (uint256) {
        return getNav().div(BUFFER_TARGET);
    }

    // Get token balances in xU3LP contract
    function getBufferTokenBalance()
        public
        view
        returns (uint256 amount0, uint256 amount1)
    {
        return (getBufferToken0Balance(), getBufferToken1Balance());
    }

    function getBufferToken0Balance() public view returns (uint256 amount0) {
        uint256 balance0 =
            getToken0AmountInWei(token0.balanceOf(address(this)));
        return Utils.sub0(balance0, withdrawableToken0Fees);
    }

    function getBufferToken1Balance() public view returns (uint256 amount1) {
        uint256 balance1 =
            getToken1AmountInWei(token1.balanceOf(address(this)));
        return Utils.sub0(balance1, withdrawableToken1Fees);
    }

    // Get token balances in the position
    function getStakedTokenBalance()
        public
        view
        returns (uint256 amount0, uint256 amount1)
    {
        (amount0, amount1) = getAmountsForLiquidity(getPositionLiquidity());
        amount0 = getToken0AmountInWei(amount0);
        amount1 = getToken1AmountInWei(amount1);
    }

    // Get wanted xU3LP contract token balance - 5% of NAV
    function getTargetBufferTokenBalance()
        public
        view
        returns (uint256 amount0, uint256 amount1)
    {
        (uint256 bufferAmount0, uint256 bufferAmount1) =
            getBufferTokenBalance();
        (uint256 poolAmount0, uint256 poolAmount1) = getStakedTokenBalance();
        amount0 = bufferAmount0.add(poolAmount0).div(BUFFER_TARGET);
        amount1 = bufferAmount1.add(poolAmount1).div(BUFFER_TARGET);
        // Keep 50:50 ratio
        amount0 = amount0.add(amount1).div(2);
        amount1 = amount0;
    }

    // Check how much xU3LP tokens will be minted
    function calculateMintAmount(uint256 _amount, uint256 totalSupply)
        public
        view
        returns (uint256 mintAmount)
    {
        if (totalSupply == 0) return _amount.mul(INITIAL_SUPPLY_MULTIPLIER);
        uint256 previousNav = getNav().sub(_amount);
        mintAmount = (_amount).mul(totalSupply).div(previousNav);
        return mintAmount;
    }

    /* ========================================================================================= */
    /*                                            Management                                     */
    /* ========================================================================================= */

    function rebalance() external onlyOwnerOrManager {
        _collect();
        _rebalance();
        _certifyAdmin();
    }

    function _rebalance() private {
        _provideOrRemoveLiquidity();
        emit Rebalance();
    }

    function _provideOrRemoveLiquidity() private {
        checkTwap();
        (uint256 bufferToken0Balance, uint256 bufferToken1Balance) =
            getBufferTokenBalance();
        (uint256 targetToken0Balance, uint256 targetToken1Balance) =
            getTargetBufferTokenBalance();
        uint256 bufferBalance = bufferToken0Balance.add(bufferToken1Balance);
        uint256 targetBalance = targetToken0Balance.add(targetToken1Balance);

        uint256 _amount0 =
            Utils.subAbs(bufferToken0Balance, targetToken0Balance);
        uint256 _amount1 =
            Utils.subAbs(bufferToken1Balance, targetToken1Balance);
        _amount0 = getToken0AmountInNativeDecimals(_amount0);
        _amount1 = getToken1AmountInNativeDecimals(_amount1);

        (uint256 amount0, uint256 amount1) =
            checkIfAmountsMatchAndSwap(_amount0, _amount1);

        if (amount0 == 0 || amount1 == 0) {
            return;
        }

        if (bufferBalance > targetBalance) {
            _stake(amount0, amount1);
        } else if (bufferBalance < targetBalance) {
            _unstake(amount0, amount1);
        }
    }

    function _stake(uint256 amount0, uint256 amount1) private {
        positionManager.increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: amount0.sub(amount0.div(MINT_BURN_SLIPPAGE)),
                amount1Min: amount1.sub(amount1.div(MINT_BURN_SLIPPAGE)),
                deadline: block.timestamp
            })
        );
    }

    function _unstake(uint256 amount0, uint256 amount1) private {
        uint128 liquidityAmount = getLiquidityForAmounts(amount0, amount1);
        (uint256 _amount0, uint256 _amount1) = unstakePosition(liquidityAmount);
        collectPosition(uint128(_amount0), uint128(_amount1));
    }

    // Collect fees
    function _collect() public onlyOwnerOrManager {
        (uint256 collected0, uint256 collected1) =
            collectPosition(type(uint128).max, type(uint128).max);

        uint256 fee0 = Utils.calculateFee(collected0, feeDivisors.claimFee);
        uint256 fee1 = Utils.calculateFee(collected1, feeDivisors.claimFee);
        _incrementWithdrawableToken0Fees(fee0);
        _incrementWithdrawableToken1Fees(fee1);
    }

    /**
     * Check if token amounts match before attempting mint() or burn()
     * Uniswap contract requires deposits at a precise token ratio
     * If they don't match, swap the tokens so as to deposit as much as possible
     */
    function checkIfAmountsMatchAndSwap(
        uint256 amount0ToMint,
        uint256 amount1ToMint
    ) private returns (uint256 amount0, uint256 amount1) {
        (uint256 amount0Minted, uint256 amount1Minted) =
            calculatePoolMintedAmounts(amount0ToMint, amount1ToMint);
        if (
            amount0Minted <
            amount0ToMint.sub(amount0ToMint.div(MINT_BURN_SLIPPAGE)) ||
            amount1Minted <
            amount1ToMint.sub(amount1ToMint.div(MINT_BURN_SLIPPAGE))
        ) {
            // calculate liquidity ratio
            uint256 mintLiquidity =
                getLiquidityForAmounts(amount0ToMint, amount1ToMint);
            uint256 poolLiquidity = getPoolLiquidity();
            int128 liquidityRatio =
                poolLiquidity == 0
                    ? 0
                    : int128(ABDKMath64x64.divuu(mintLiquidity, poolLiquidity));
            (amount0, amount1) = restoreTokenRatios(
                amount0ToMint,
                amount1ToMint,
                amount0Minted,
                amount1Minted,
                liquidityRatio
            );
        } else {
            (amount0, amount1) = (amount0ToMint, amount1ToMint);
        }
    }

    // Migrate the current position to a new position with different ticks
    function migratePosition(int24 newTickLower, int24 newTickUpper)
        external
        onlyOwnerOrManager
    {
        require(newTickLower != tickLower || newTickUpper != tickUpper);

        // withdraw entire liquidity from the position
        (uint256 _amount0, uint256 _amount1) = withdrawAll();
        // burn current position NFT
        positionManager.burn(tokenId);
        tokenId = 0;
        // set new ticks and prices
        tickLower = newTickLower;
        tickUpper = newTickUpper;
        priceLower = TickMath.getSqrtRatioAtTick(newTickLower);
        priceUpper = TickMath.getSqrtRatioAtTick(newTickUpper);

        // if amounts don't add up when minting, swap tokens
        (uint256 amount0, uint256 amount1) =
            checkIfAmountsMatchAndSwap(_amount0, _amount1);

        // mint the position NFT and deposit the liquidity
        // set new NFT token id
        tokenId = createPosition(amount0, amount1);
        emit PositionMigrated(newTickLower, newTickUpper);
    }

    // Withdraws all current liquidity from the position
    function withdrawAll()
        private
        returns (uint256 _amount0, uint256 _amount1)
    {
        // Collect fees
        _collect();
        (_amount0, _amount1) = unstakePosition(getPositionLiquidity());
        collectPosition(uint128(_amount0), uint128(_amount1));
    }

    /**
     * Transfers asset amount when user calls burn()
     * If there's not enough balance of that asset,
     * triggers a router swap to increase the balance
     * keep token ratio in xU3LP at 50:50 after swapping
     */
    function transferOnBurn(uint8 outputAsset, uint256 transferAmount) private {
        (uint256 balance0, uint256 balance1) = getBufferTokenBalance();
        if (outputAsset == 0) {
            if (balance0 < transferAmount) {
                uint256 amountIn =
                    transferAmount.add(transferAmount.div(SWAP_SLIPPAGE)).sub(
                        balance0
                    );
                uint256 amountOut = transferAmount.sub(balance0);
                uint256 balanceFactor = Utils.sub0(balance1, amountOut).div(2);
                amountIn = amountIn.add(balanceFactor);
                amountOut = amountOut.add(balanceFactor);
                swapToken1ForToken0(amountIn, amountOut);
            }
            transferAmount = getToken0AmountInNativeDecimals(transferAmount);
            token0.safeTransfer(msg.sender, transferAmount);
        } else {
            if (balance1 < transferAmount) {
                uint256 amountIn =
                    transferAmount.add(transferAmount.div(SWAP_SLIPPAGE)).sub(
                        balance1
                    );
                uint256 amountOut = transferAmount.sub(balance1);
                uint256 balanceFactor = Utils.sub0(balance0, amountOut).div(2);
                amountIn = amountIn.add(balanceFactor);
                amountOut = amountOut.add(balanceFactor);
                swapToken0ForToken1(amountIn, amountOut);
            }
            transferAmount = getToken1AmountInNativeDecimals(transferAmount);
            token1.safeTransfer(msg.sender, transferAmount);
        }
    }

    /**
     * Mint function which initializes the pool position
     * Must be called before any liquidity can be deposited
     */
    function mintInitial(uint256 amount0, uint256 amount1)
        external
        onlyOwnerOrManager
    {
        require(tokenId == 0);
        require(amount0 > 0 || amount1 > 0);
        checkTwap();
        if (amount0 > 0) {
            token0.safeTransferFrom(msg.sender, address(this), amount0);
        }
        if (amount1 > 0) {
            token1.safeTransferFrom(msg.sender, address(this), amount1);
        }
        tokenId = createPosition(amount0, amount1);
        amount0 = getToken0AmountInWei(amount0);
        amount1 = getToken1AmountInWei(amount1);
        _mintInternal(
            getAmountInAsset1Terms(amount0).add(getAmountInAsset0Terms(amount1))
        );
        emit PositionInitialized(tickLower, tickUpper);
    }

    /**
     * Creates the NFT token representing the pool position
     */
    function createPosition(uint256 amount0, uint256 amount1)
        private
        returns (uint256 _tokenId)
    {
        (_tokenId, , , ) = positionManager.mint(
            INonfungiblePositionManager.MintParams({
                token0: address(token0),
                token1: address(token1),
                fee: POOL_FEE,
                tickLower: tickLower,
                tickUpper: tickUpper,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: amount0.sub(amount0.div(MINT_BURN_SLIPPAGE)),
                amount1Min: amount1.sub(amount1.div(MINT_BURN_SLIPPAGE)),
                recipient: address(this),
                deadline: block.timestamp
            })
        );
    }

    /**
     * @dev Unstakes a given amount of liquidity from the Uni V3 position
     * @param liquidity amount of liquidity to unstake
     * @return amount0 token0 amount unstaked
     * @return amount1 token1 amount unstaked
     */
    function unstakePosition(uint128 liquidity)
        private
        returns (uint256 amount0, uint256 amount1)
    {
        (uint256 _amount0, uint256 _amount1) =
            getAmountsForLiquidity(liquidity);
        (amount0, amount1) = positionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: _amount0.sub(_amount0.div(MINT_BURN_SLIPPAGE)),
                amount1Min: _amount1.sub(_amount1.div(MINT_BURN_SLIPPAGE)),
                deadline: block.timestamp
            })
        );
    }

    /*
     * @notice Registers that admin is present and active
     * @notice If admin isn't certified within liquidation time period,
     * emergencyUnstake function becomes callable
     */
    function _certifyAdmin() private {
        adminActiveTimestamp = block.timestamp;
    }

    /*
     * @dev Public callable function for unstaking in event of admin failure/incapacitation
     */
    function emergencyUnstake(uint256 _amount0, uint256 _amount1) external {
        require(
            adminActiveTimestamp.add(LIQUIDATION_TIME_PERIOD) < block.timestamp
        );
        _unstake(_amount0, _amount1);
    }

    function _mintInternal(uint256 _amount) private {
        uint256 mintAmount = calculateMintAmount(_amount, totalSupply());
        return super._mint(msg.sender, mintAmount);
    }

    function _incrementWithdrawableToken0Fees(uint256 _feeAmount) private {
        withdrawableToken0Fees = withdrawableToken0Fees.add(
            getToken0AmountInWei(_feeAmount)
        );
    }

    function _incrementWithdrawableToken1Fees(uint256 _feeAmount) private {
        withdrawableToken1Fees = withdrawableToken1Fees.add(
            getToken1AmountInWei(_feeAmount)
        );
    }

    /*
     * @notice Inverse of fee i.e., a fee divisor of 100 == 1%
     * @notice Three fee types
     * @dev Mint fee 0 or <= 1%
     * @dev Burn fee 0 or <= 1%
     * @dev Claim fee 0 <= 4%
     */
    function setFeeDivisors(FeeDivisors memory _feeDivisors)
        external
        onlyOwnerOrManager
    {
        _setFeeDivisors(_feeDivisors);
    }

    function _setFeeDivisors(FeeDivisors memory _feeDivisors) private {
        require(_feeDivisors.mintFee == 0 || _feeDivisors.mintFee >= 100);
        require(_feeDivisors.burnFee == 0 || _feeDivisors.burnFee >= 100);
        require(_feeDivisors.claimFee == 0 || _feeDivisors.claimFee >= 25);
        feeDivisors.mintFee = _feeDivisors.mintFee;
        feeDivisors.burnFee = _feeDivisors.burnFee;
        feeDivisors.claimFee = _feeDivisors.claimFee;
        emit FeeDivisorsSet(
            feeDivisors.mintFee,
            feeDivisors.burnFee,
            feeDivisors.claimFee
        );
    }

    /*
     * Emergency function in case of errant transfer
     * of any token directly to contract
     */
    function withdrawToken(address token, address receiver)
        external
        onlyOwnerOrManager
    {
        require(token != address(token0) && token != address(token1));
        uint256 tokenBal = IERC20(address(token)).balanceOf(address(this));
        if (tokenBal > 0) {
            IERC20(address(token)).safeTransfer(receiver, tokenBal);
        }
    }

    /*
     * Withdraw function for token0 and token1 fees
     */
    function withdrawFees() external onlyOwnerOrManager {
        uint256 token0Fees =
            getToken0AmountInNativeDecimals(withdrawableToken0Fees);
        uint256 token1Fees =
            getToken1AmountInNativeDecimals(withdrawableToken1Fees);
        if (token0Fees > 0) {
            token0.safeTransfer(msg.sender, token0Fees);
            withdrawableToken0Fees = 0;
        }
        if (token1Fees > 0) {
            token1.safeTransfer(msg.sender, token1Fees);
            withdrawableToken1Fees = 0;
        }

        emit FeeWithdraw(token0Fees, token1Fees);
    }

    /*
     *  Admin function for staking beyond the scope of a rebalance
     */
    function adminStake(uint256 amount0, uint256 amount1)
        external
        onlyOwnerOrManager
    {
        _stake(amount0, amount1);
    }

    /*
     *  Admin function for unstaking beyond the scope of a rebalance
     */
    function adminUnstake(uint256 amount0, uint256 amount1)
        external
        onlyOwnerOrManager
    {
        _unstake(amount0, amount1);
    }

    /*
     *  Admin function for swapping LP tokens in xU3LP
     *  @param amount - how much to swap
     *  @param _0for1 - swap token 0 for 1 if true, token 1 for 0 if false
     */
    function adminSwap(uint256 amount, bool _0for1)
        external
        onlyOwnerOrManager
    {
        if (_0for1) {
            swapToken0ForToken1(amount.add(amount.div(SWAP_SLIPPAGE)), amount);
        } else {
            swapToken1ForToken0(amount.add(amount.div(SWAP_SLIPPAGE)), amount);
        }
    }

    function pauseContract() external onlyOwnerOrManager returns (bool) {
        _pause();
        return true;
    }

    function unpauseContract() external onlyOwnerOrManager returns (bool) {
        _unpause();
        return true;
    }

    function setManager(address _manager) external onlyOwner {
        manager = _manager;
    }

    function setManager2(address _manager2) external onlyOwner {
        manager2 = _manager2;
    }

    modifier onlyOwnerOrManager {
        require(
            msg.sender == owner() ||
                msg.sender == manager ||
                msg.sender == manager2
        );
        _;
    }

    /* ========================================================================================= */
    /*                                       Uniswap helpers                                     */
    /* ========================================================================================= */

    function swapToken0ForToken1(uint256 amountIn, uint256 amountOut) private {
        amountIn = getToken0AmountInNativeDecimals(amountIn);
        amountOut = getToken1AmountInNativeDecimals(amountOut);
        router.exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: address(token0),
                tokenOut: address(token1),
                fee: POOL_FEE,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountIn,
                sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1
            })
        );
    }

    function swapToken1ForToken0(uint256 amountIn, uint256 amountOut) private {
        amountIn = getToken1AmountInNativeDecimals(amountIn);
        amountOut = getToken0AmountInNativeDecimals(amountOut);
        router.exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: address(token1),
                tokenOut: address(token0),
                fee: POOL_FEE,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountIn,
                sqrtPriceLimitX96: TickMath.MAX_SQRT_RATIO - 1
            })
        );
    }

    /**
     * Swap tokens in xU3LP so as to keep a ratio which is required for
     * depositing/withdrawing liquidity from the pool
     */
    function restoreTokenRatios(
        uint256 amount0ToMint,
        uint256 amount1ToMint,
        uint256 amount0Minted,
        uint256 amount1Minted,
        int128 liquidityRatio
    ) private returns (uint256 amount0, uint256 amount1) {
        // after normalization, returned swap amount will be in wei representation
        uint256 swapAmount =
            Utils.calculateSwapAmount(
                getToken0AmountInWei(amount0ToMint),
                getToken1AmountInWei(amount1ToMint),
                getToken0AmountInWei(amount0Minted),
                getToken1AmountInWei(amount1Minted),
                liquidityRatio
            );
        if (swapAmount == 0) {
            return (amount0ToMint, amount1ToMint);
        }
        uint256 swapAmountWithSlippage =
            swapAmount.add(swapAmount.div(SWAP_SLIPPAGE));

        uint256 mul1 = amount0ToMint.mul(amount1Minted);
        uint256 mul2 = amount1ToMint.mul(amount0Minted);
        (uint256 balance0, uint256 balance1) = getBufferTokenBalance();

        if (mul1 > mul2) {
            if (balance0 < swapAmountWithSlippage) {
                // withdraw enough balance to swap
                withdrawSingleToken(true, swapAmountWithSlippage);
                // balances are not the same as before, so go back to rebalancing
                _provideOrRemoveLiquidity();
                return (0, 0);
            }
            // Swap tokens
            swapToken0ForToken1(swapAmountWithSlippage, swapAmount);
            amount0 = amount0ToMint.sub(
                getToken0AmountInNativeDecimals(swapAmount)
            );
            amount1 = amount1ToMint.add(
                getToken1AmountInNativeDecimals(swapAmount)
            );
        } else if (mul1 < mul2) {
            if (balance1 < swapAmountWithSlippage) {
                // withdraw enough balance to swap
                withdrawSingleToken(false, swapAmountWithSlippage);
                // balances are not the same as before, so go back to rebalancing
                _provideOrRemoveLiquidity();
                return (0, 0);
            }
            // Swap tokens
            swapToken1ForToken0(swapAmountWithSlippage, swapAmount);
            amount0 = amount0ToMint.add(
                getToken0AmountInNativeDecimals(swapAmount)
            );
            amount1 = amount1ToMint.sub(
                getToken1AmountInNativeDecimals(swapAmount)
            );
        }
    }

    /**
     *  @dev Withdraw until token0 or token1 balance reaches amount
     *  @param forToken0 withdraw balance for token0 (true) or token1 (false)
     *  @param amount minimum amount we want to have in token0 or token1
     */
    function withdrawSingleToken(bool forToken0, uint256 amount) private {
        uint256 balance;
        uint256 unstakeAmount0;
        uint256 unstakeAmount1;
        uint256 swapAmount;
        do {
            // calculate how much we can withdraw
            (unstakeAmount0, unstakeAmount1) = calculatePoolMintedAmounts(
                getToken0AmountInNativeDecimals(amount),
                getToken1AmountInNativeDecimals(amount)
            );
            // withdraw both tokens
            _unstake(unstakeAmount0, unstakeAmount1);

            // swap the excess amount of token0 for token1 or vice-versa
            swapAmount = forToken0
                ? getToken1AmountInWei(unstakeAmount1)
                : getToken0AmountInWei(unstakeAmount0);
            forToken0
                ? swapToken1ForToken0(
                    swapAmount.add(swapAmount.div(SWAP_SLIPPAGE)),
                    swapAmount
                )
                : swapToken0ForToken1(
                    swapAmount.add(swapAmount.div(SWAP_SLIPPAGE)),
                    swapAmount
                );
            balance = forToken0
                ? getBufferToken0Balance()
                : getBufferToken1Balance();
        } while (balance < amount);
    }

    // Returns the current liquidity in the position
    function getPositionLiquidity() private view returns (uint128 liquidity) {
        (, , , , , , , liquidity, , , , ) = positionManager.positions(tokenId);
    }

    // Returns the current pool price
    function getPoolPrice() private view returns (uint160) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return sqrtRatioX96;
    }

    // Returns the current pool liquidity
    function getPoolLiquidity() private view returns (uint128) {
        return pool.liquidity();
    }

    // Returns the earliest oracle observation time
    function getObservationTime() public view returns (uint32) {
        (, , uint16 index, uint16 cardinality, , , ) = pool.slot0();
        uint16 oldestObservationIndex = (index + 1) % cardinality;
        (uint32 observationTime, , , bool initialized) =
            pool.observations(oldestObservationIndex);
        if (!initialized) (observationTime, , , ) = pool.observations(0);
        return observationTime;
    }

    /**
     *  Get asset 0 twap
     *  Uses Uni V3 oracle, reading the TWAP from twap period
     *  or the earliest oracle observation time if twap period is not set
     */
    function getAsset0Price() public view returns (int128) {
        uint32[] memory secondsArray = new uint32[](2);
        // get earliest oracle observation time
        uint32 observationTime = getObservationTime();
        uint32 currTimestamp = uint32(block.timestamp);
        uint32 earliestObservationSecondsAgo = currTimestamp - observationTime;
        if (
            twapPeriod == 0 ||
            !Utils.lte(
                currTimestamp,
                observationTime,
                currTimestamp - twapPeriod
            )
        ) {
            // set to earliest observation time if:
            // a) twap period is 0 (not set)
            // b) now - twap period is before earliest observation
            secondsArray[0] = earliestObservationSecondsAgo;
        } else {
            secondsArray[0] = twapPeriod;
        }
        secondsArray[1] = 0;
        (int56[] memory prices, ) = pool.observe(secondsArray);

        int128 twap = Utils.getTWAP(prices, secondsArray[0]);
        if (token1Decimals > token0Decimals) {
            // divide twap by token decimal difference
            twap = ABDKMath64x64.mul(
                twap,
                ABDKMath64x64.divu(1, tokenDiffDecimalMultiplier)
            );
        } else if (token0Decimals > token1Decimals) {
            // multiply twap by token decimal difference
            int128 multiplierFixed =
                ABDKMath64x64.fromUInt(tokenDiffDecimalMultiplier);
            twap = ABDKMath64x64.mul(twap, multiplierFixed);
        }
        return twap;
    }

    /**
     * Checks if twap deviates too much from the previous twap
     */
    function checkTwap() private {
        int128 twap = getAsset0Price();
        int128 _lastTwap = lastTwap;
        int128 deviation =
            _lastTwap > twap ? _lastTwap - twap : twap - _lastTwap;
        int128 maxDeviation =
            ABDKMath64x64.mul(
                twap,
                ABDKMath64x64.divu(1, maxTwapDeviationDivisor)
            );
        require(deviation <= maxDeviation, "Wrong twap");
        lastTwap = twap;
    }

    /**
     *  Reset last twap if oracle price is consistently above the max deviation
     *  Requires twap to be above max deviation to execute
     */
    function resetTwap() external onlyOwnerOrManager {
        lastTwap = getAsset0Price();
    }

    /**
     *  Set the max twap deviation divisor
     */
    function setMaxTwapDeviationDivisor(uint256 newDeviationDivisor)
        external
        onlyOwnerOrManager
    {
        maxTwapDeviationDivisor = newDeviationDivisor;
    }

    /**
     * Set the oracle reading twap period
     */
    function setTwapPeriod(uint32 newPeriod) external onlyOwnerOrManager {
        require(newPeriod >= 360);
        twapPeriod = newPeriod;
    }

    /**
     *  Collect token amounts from pool position
     */
    function collectPosition(uint128 amount0, uint128 amount1)
        private
        returns (uint256 collected0, uint256 collected1)
    {
        (collected0, collected1) = positionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: amount0,
                amount1Max: amount1
            })
        );
    }

    /**
     * Calculates the amounts deposited/withdrawn from the pool
     * amount0, amount1 - amounts to deposit/withdraw
     * amount0Minted, amount1Minted - actual amounts which can be deposited
     */
    function calculatePoolMintedAmounts(uint256 amount0, uint256 amount1)
        public
        view
        returns (uint256 amount0Minted, uint256 amount1Minted)
    {
        uint128 liquidityAmount = getLiquidityForAmounts(amount0, amount1);
        (amount0Minted, amount1Minted) = getAmountsForLiquidity(
            liquidityAmount
        );
    }

    function getAmountsForLiquidity(uint128 liquidity)
        private
        view
        returns (uint256 amount0, uint256 amount1)
    {
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            getPoolPrice(),
            priceLower,
            priceUpper,
            liquidity
        );
    }

    function getLiquidityForAmounts(uint256 amount0, uint256 amount1)
        private
        view
        returns (uint128 liquidity)
    {
        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            getPoolPrice(),
            priceLower,
            priceUpper,
            amount0,
            amount1
        );
    }

    /**
     *  Get lower and upper ticks of the pool position
     */
    function getTicks() external view returns (int24 tick0, int24 tick1) {
        return (tickLower, tickUpper);
    }

    /**
     * Returns token0 amount in TOKEN_DECIMAL_REPRESENTATION
     */
    function getToken0AmountInWei(uint256 amount)
        private
        view
        returns (uint256)
    {
        if (token0Decimals < TOKEN_DECIMAL_REPRESENTATION) {
            amount = amount.mul(token0DecimalMultiplier);
        }
        return amount;
    }

    /**
     * Returns token1 amount in TOKEN_DECIMAL_REPRESENTATION
     */
    function getToken1AmountInWei(uint256 amount)
        private
        view
        returns (uint256)
    {
        if (token1Decimals < TOKEN_DECIMAL_REPRESENTATION) {
            amount = amount.mul(token1DecimalMultiplier);
        }
        return amount;
    }

    /**
     * Returns token0 amount in token0Decimals
     */
    function getToken0AmountInNativeDecimals(uint256 amount)
        private
        view
        returns (uint256)
    {
        if (token0Decimals < TOKEN_DECIMAL_REPRESENTATION) {
            amount = amount.div(token0DecimalMultiplier);
        }
        return amount;
    }

    /**
     * Returns token1 amount in token1Decimals
     */
    function getToken1AmountInNativeDecimals(uint256 amount)
        private
        view
        returns (uint256)
    {
        if (token1Decimals < TOKEN_DECIMAL_REPRESENTATION) {
            amount = amount.div(token1DecimalMultiplier);
        }
        return amount;
    }
}
