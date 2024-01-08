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

import "./ABDKMath64x64.sol";
import "./Utils.sol";
import "./UniswapLibrary.sol";
import "./BlockLock.sol";

import "./IxTokenManager.sol";

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

    address public poolAddress;
    address public routerAddress;
    address public positionManagerAddress;

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

    IxTokenManager xTokenManager; // xToken manager contract

    event Rebalance();
    event FeeDivisorsSet(uint256 mintFee, uint256 burnFee, uint256 claimFee);
    event FeeWithdraw(uint256 token0Fee, uint256 token1Fee);
    event FeeCollected(uint256 token0Fee, uint256 token1Fee);

    function initialize(
        string memory _symbol,
        int24 _tickLower,
        int24 _tickUpper,
        IERC20 _token0,
        IERC20 _token1,
        address _pool,
        address _router,
        address _positionManager,
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
        priceLower = UniswapLibrary.getSqrtRatio(_tickLower);
        priceUpper = UniswapLibrary.getSqrtRatio(_tickUpper);
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

        poolAddress = _pool;
        routerAddress = _router;
        positionManagerAddress = _positionManager;

        token0.safeIncreaseAllowance(_router, type(uint256).max);
        token1.safeIncreaseAllowance(_router, type(uint256).max);
        token0.safeIncreaseAllowance(_positionManager, type(uint256).max);
        token1.safeIncreaseAllowance(_positionManager, type(uint256).max);

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
        (uint256 bufferToken0Balance, uint256 bufferToken1Balance) =
            getBufferTokenBalance();
        uint256 nav = getNav();

        uint256 proRataBalance;
        if (outputAsset == 0) {
            proRataBalance = (nav.mul(getAmountInAsset0Terms(amount))).div(
                totalSupply()
            );
            require(
                proRataBalance <= bufferToken0Balance,
                "Insufficient exit liquidity"
            );
        } else {
            proRataBalance = (nav.mul(amount).div(totalSupply()));
            require(
                proRataBalance <= bufferToken1Balance,
                "Insufficient exit liquidity"
            );
        }

        super._burn(msg.sender, amount);

        // Fee is in wei (18 decimals, so doesn't need to be normalized)
        uint256 fee = Utils.calculateFee(proRataBalance, feeDivisors.burnFee);
        if (outputAsset == 0) {
            withdrawableToken0Fees = withdrawableToken0Fees.add(fee);
            uint256 transferAmount =
                getToken0AmountInNativeDecimals(proRataBalance.sub(fee));
            token0.safeTransfer(msg.sender, transferAmount);
        } else {
            withdrawableToken1Fees = withdrawableToken1Fees.add(fee);
            uint256 transferAmount =
                getToken1AmountInNativeDecimals(proRataBalance.sub(fee));
            token1.safeTransfer(msg.sender, transferAmount);
        }
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

    /**
     *  @dev Get asset 0 twap
     *  @dev Uses Uni V3 oracle, reading the TWAP from twap period
     *  @dev or the earliest oracle observation time if twap period is not set
     */
    function getAsset0Price() public view returns (int128) {
        return
            UniswapLibrary.getAsset0Price(
                poolAddress,
                twapPeriod,
                token0Decimals,
                token1Decimals,
                tokenDiffDecimalMultiplier
            );
    }

    /**
     *  @dev Get asset 1 twap
     *  @dev Uses Uni V3 oracle, reading the TWAP from twap period
     *  @dev or the earliest oracle observation time if twap period is not set
     */
    function getAsset1Price() public view returns (int128) {
        return
            UniswapLibrary.getAsset1Price(
                poolAddress,
                twapPeriod,
                token0Decimals,
                token1Decimals,
                tokenDiffDecimalMultiplier
            );
    }

    /**
     * @dev Returns amount in terms of asset 0
     * @dev amount * asset 1 price
     */
    function getAmountInAsset0Terms(uint256 amount)
        public
        view
        returns (uint256)
    {
        return
            UniswapLibrary.getAmountInAsset0Terms(
                amount,
                poolAddress,
                twapPeriod,
                token0Decimals,
                token1Decimals,
                tokenDiffDecimalMultiplier
            );
    }

    /**
     * @dev Returns amount in terms of asset 1
     * @dev amount * asset 0 price
     */
    function getAmountInAsset1Terms(uint256 amount)
        public
        view
        returns (uint256)
    {
        return
            UniswapLibrary.getAmountInAsset1Terms(
                amount,
                poolAddress,
                twapPeriod,
                token0Decimals,
                token1Decimals,
                tokenDiffDecimalMultiplier
            );
    }

    // Get net asset value
    function getNav() public view returns (uint256) {
        return getStakedBalance().add(getBufferBalance());
    }

    // Get total balance in the position
    function getStakedBalance() public view returns (uint256) {
        (uint256 amount0, uint256 amount1) = getStakedTokenBalance();
        return getAmountInAsset1Terms(amount0).add(amount1);
    }

    // Get balance in xU3LP contract
    function getBufferBalance() public view returns (uint256) {
        (uint256 balance0, uint256 balance1) = getBufferTokenBalance();
        return getAmountInAsset1Terms(balance0).add(balance1);
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
        collect();
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

    /**
     * @dev Stake liquidity in position
     */
    function _stake(uint256 amount0, uint256 amount1)
        private
        returns (uint256 stakedAmount0, uint256 stakedAmount1)
    {
        return
            UniswapLibrary.stake(
                amount0,
                amount1,
                positionManagerAddress,
                tokenId
            );
    }

    /**
     * @dev Unstake liquidity from position
     */
    function _unstake(uint256 amount0, uint256 amount1)
        private
        returns (uint256 collected0, uint256 collected1)
    {
        uint128 liquidityAmount = getLiquidityForAmounts(amount0, amount1);
        (uint256 _amount0, uint256 _amount1) = unstakePosition(liquidityAmount);
        return collectPosition(uint128(_amount0), uint128(_amount1));
    }

    // Collect fees
    function collect() public onlyOwnerOrManager {
        (uint256 collected0, uint256 collected1) =
            collectPosition(type(uint128).max, type(uint128).max);

        uint256 fee0 = Utils.calculateFee(collected0, feeDivisors.claimFee);
        uint256 fee1 = Utils.calculateFee(collected1, feeDivisors.claimFee);
        _incrementWithdrawableToken0Fees(fee0);
        _incrementWithdrawableToken1Fees(fee1);
        emit FeeCollected(collected0, collected1);
    }

    /**
     * @dev Check if token amounts match before attempting rebalance
     * @dev Uniswap contract requires deposits at a precise token ratio
     * @dev If they don't match, swap the tokens so as to deposit as much as possible
     */
    function checkIfAmountsMatchAndSwap(
        uint256 amount0ToMint,
        uint256 amount1ToMint
    ) private returns (uint256 amount0, uint256 amount1) {
        UniswapLibrary.TokenDetails memory tokenDetails =
            UniswapLibrary.TokenDetails({
                token0: address(token0),
                token1: address(token1),
                token0DecimalMultiplier: token0DecimalMultiplier,
                token1DecimalMultiplier: token1DecimalMultiplier,
                token0Decimals: token0Decimals,
                token1Decimals: token1Decimals
            });
        UniswapLibrary.PositionDetails memory positionDetails =
            UniswapLibrary.PositionDetails({
                poolFee: POOL_FEE,
                priceLower: priceLower,
                priceUpper: priceUpper,
                tokenId: tokenId,
                positionManager: positionManagerAddress,
                router: routerAddress,
                pool: poolAddress
            });
        return
            UniswapLibrary.checkIfAmountsMatchAndSwap(
                true,
                amount0ToMint,
                amount1ToMint,
                positionDetails,
                tokenDetails
            );
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
        UniswapLibrary.burn(positionManagerAddress, tokenId);
        tokenId = 0;
        // set new ticks and prices
        tickLower = newTickLower;
        tickUpper = newTickUpper;
        priceLower = UniswapLibrary.getSqrtRatio(newTickLower);
        priceUpper = UniswapLibrary.getSqrtRatio(newTickUpper);

        // if amounts don't add up when minting, swap tokens
        (uint256 amount0, uint256 amount1) =
            checkIfAmountsMatchAndSwap(_amount0, _amount1);

        // mint the position NFT and deposit the liquidity
        // set new NFT token id
        tokenId = createPosition(amount0, amount1);
    }

    // Withdraws all current liquidity from the position
    function withdrawAll()
        private
        returns (uint256 _amount0, uint256 _amount1)
    {
        // Collect fees
        collect();
        (_amount0, _amount1) = unstakePosition(getPositionLiquidity());
        collectPosition(uint128(_amount0), uint128(_amount1));
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
        _mintInternal(getAmountInAsset1Terms(amount0).add(amount1));
    }

    /**
     * @dev Creates the NFT token representing the pool position
     * @dev Mint initial liquidity
     */
    function createPosition(uint256 amount0, uint256 amount1)
        private
        returns (uint256 _tokenId)
    {
        UniswapLibrary.TokenDetails memory tokenDetails =
            UniswapLibrary.TokenDetails({
                token0: address(token0),
                token1: address(token1),
                token0DecimalMultiplier: token0DecimalMultiplier,
                token1DecimalMultiplier: token1DecimalMultiplier,
                token0Decimals: token0Decimals,
                token1Decimals: token1Decimals
            });
        UniswapLibrary.PositionDetails memory positionDetails =
            UniswapLibrary.PositionDetails({
                poolFee: POOL_FEE,
                priceLower: priceLower,
                priceUpper: priceUpper,
                tokenId: tokenId,
                positionManager: positionManagerAddress,
                router: routerAddress,
                pool: poolAddress
            });
        return
            UniswapLibrary.createPosition(
                amount0,
                amount1,
                positionManagerAddress,
                tokenDetails,
                positionDetails
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
        UniswapLibrary.PositionDetails memory positionDetails =
            UniswapLibrary.PositionDetails({
                poolFee: POOL_FEE,
                priceLower: priceLower,
                priceUpper: priceUpper,
                tokenId: tokenId,
                positionManager: positionManagerAddress,
                router: routerAddress,
                pool: poolAddress
            });
        return UniswapLibrary.unstakePosition(liquidity, positionDetails);
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
    function withdrawFees() external {
        require(
            xTokenManager.isRevenueController(msg.sender),
            "Callable only by Revenue Controller"
        );
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

    /**
     * @dev Admin function for swapping LP tokens in xU3LP using 1inch v3 exchange
     * @param minReturn - how much output tokens to receive on swap, in 18 decimals
     * @param _0for1 - swap token 0 for token 1 if true, token 1 for token 0 if false
     * @param _oneInchData - 1inch calldata, generated off-chain using their v3 api
     */
    function adminSwapOneInch(
        uint256 minReturn,
        bool _0for1,
        bytes memory _oneInchData
    ) external onlyOwnerOrManager {
        UniswapLibrary.oneInchSwap(
            true,
            minReturn,
            _0for1,
            UniswapLibrary.TokenDetails({
                token0: address(token0),
                token1: address(token1),
                token0DecimalMultiplier: token0DecimalMultiplier,
                token1DecimalMultiplier: token1DecimalMultiplier,
                token0Decimals: token0Decimals,
                token1Decimals: token1Decimals
            }),
            _oneInchData
        );
    }

    function pauseContract() external onlyOwnerOrManager returns (bool) {
        _pause();
        return true;
    }

    function unpauseContract() external onlyOwnerOrManager returns (bool) {
        _unpause();
        return true;
    }

    modifier onlyOwnerOrManager {
        require(
            msg.sender == owner() ||
                xTokenManager.isManager(msg.sender, address(this)),
            "Function may be called only by owner or manager"
        );
        _;
    }

    /* ========================================================================================= */
    /*                                       Uniswap helpers                                     */
    /* ========================================================================================= */

    function swapToken0ForToken1(uint256 amountIn, uint256 amountOut) private {
        UniswapLibrary.swapToken0ForToken1(
            amountIn,
            amountOut,
            POOL_FEE,
            routerAddress,
            UniswapLibrary.TokenDetails({
                token0: address(token0),
                token1: address(token1),
                token0DecimalMultiplier: token0DecimalMultiplier,
                token1DecimalMultiplier: token1DecimalMultiplier,
                token0Decimals: token0Decimals,
                token1Decimals: token1Decimals
            })
        );
    }

    function swapToken1ForToken0(uint256 amountIn, uint256 amountOut) private {
        UniswapLibrary.swapToken1ForToken0(
            amountIn,
            amountOut,
            POOL_FEE,
            routerAddress,
            UniswapLibrary.TokenDetails({
                token0: address(token0),
                token1: address(token1),
                token0DecimalMultiplier: token0DecimalMultiplier,
                token1DecimalMultiplier: token1DecimalMultiplier,
                token0Decimals: token0Decimals,
                token1Decimals: token1Decimals
            })
        );
    }

    // Returns the current liquidity in the position
    function getPositionLiquidity() public view returns (uint128 liquidity) {
        return
            UniswapLibrary.getPositionLiquidity(
                positionManagerAddress,
                tokenId
            );
    }

    // Returns the current pool price
    function getPoolPrice() private view returns (uint160) {
        return UniswapLibrary.getPoolPrice(poolAddress);
    }

    // Returns the current pool liquidity
    function getPoolLiquidity() private view returns (uint128) {
        return UniswapLibrary.getPoolLiquidity(poolAddress);
    }

    /**
     * @dev Checks if twap deviates too much from the previous twap
     */
    function checkTwap() private {
        lastTwap = UniswapLibrary.checkTwap(
            poolAddress,
            twapPeriod,
            token0Decimals,
            token1Decimals,
            tokenDiffDecimalMultiplier,
            lastTwap,
            maxTwapDeviationDivisor
        );
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
     *  @dev Collect token amounts from pool position
     */
    function collectPosition(uint128 amount0, uint128 amount1)
        private
        returns (uint256 collected0, uint256 collected1)
    {
        return
            UniswapLibrary.collectPosition(
                amount0,
                amount1,
                tokenId,
                positionManagerAddress
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
        public
        view
        returns (uint256 amount0, uint256 amount1)
    {
        (amount0, amount1) = UniswapLibrary.getAmountsForLiquidity(
            liquidity,
            priceLower,
            priceUpper,
            poolAddress
        );
    }

    function getLiquidityForAmounts(uint256 amount0, uint256 amount1)
        public
        view
        returns (uint128 liquidity)
    {
        liquidity = UniswapLibrary.getLiquidityForAmounts(
            amount0,
            amount1,
            priceLower,
            priceUpper,
            poolAddress
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
        return
            UniswapLibrary.getToken0AmountInWei(
                amount,
                token0Decimals,
                token0DecimalMultiplier
            );
    }

    /**
     * Returns token1 amount in TOKEN_DECIMAL_REPRESENTATION
     */
    function getToken1AmountInWei(uint256 amount)
        private
        view
        returns (uint256)
    {
        return
            UniswapLibrary.getToken1AmountInWei(
                amount,
                token1Decimals,
                token1DecimalMultiplier
            );
    }

    /**
     * Returns token0 amount in token0Decimals
     */
    function getToken0AmountInNativeDecimals(uint256 amount)
        private
        view
        returns (uint256)
    {
        return
            UniswapLibrary.getToken0AmountInNativeDecimals(
                amount,
                token0Decimals,
                token0DecimalMultiplier
            );
    }

    /**
     * Returns token1 amount in token1Decimals
     */
    function getToken1AmountInNativeDecimals(uint256 amount)
        private
        view
        returns (uint256)
    {
        return
            UniswapLibrary.getToken1AmountInNativeDecimals(
                amount,
                token1Decimals,
                token1DecimalMultiplier
            );
    }

    /**
     * Set xTokenManager contract
     */
    function setxTokenManager(IxTokenManager _manager) external onlyOwner {
        require(address(xTokenManager) == address(0));
        xTokenManager = _manager;
    }

    /**
     * Approve 1inch v3 exchange for swaps
     */
    function approveOneInch() external onlyOwnerOrManager {
        UniswapLibrary.approveOneInch(token0, token1);
    }
}
