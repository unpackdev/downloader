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

import "./UniswapLibrary.sol";
import "./BlockLock.sol";

import "./IxTokenManager.sol";
import "./IxAsset.sol";

contract xAssetCLR is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    BlockLock
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant SWAP_SLIPPAGE = 50; // 2%
    uint256 private constant MINT_BURN_SLIPPAGE = 100; // 1%
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

    uint256 public tokenId; // token id representing this uniswap position
    uint256 public token0DecimalMultiplier; // 10 ** (18 - token0 decimals)
    uint256 public token1DecimalMultiplier; // 10 ** (18 - token1 decimals)
    uint256 public tokenDiffDecimalMultiplier; // 10 ** (token0 decimals - token1 decimals)
    uint24 public poolFee;
    uint8 public token0Decimals;
    uint8 public token1Decimals;

    UniswapContracts public uniContracts;

    IxTokenManager xTokenManager; // xToken manager contract

    uint32 twapPeriod;
    
    struct UniswapContracts {
        address pool;
        address router;
        address quoter;
        address positionManager;
    }

    event Rebalance();
    event FeeCollected(uint256 token0Fee, uint256 token1Fee);

    function initialize(
        string memory _symbol,
        int24 _tickLower,
        int24 _tickUpper,
        IERC20 _token0,
        IERC20 _token1,
        UniswapContracts memory contracts,
        address _xTokenManagerAddress,
        uint256 _maxTwapDeviationDivisor,
        uint8 _token0Decimals,
        uint8 _token1Decimals
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained("xAssetCLR", _symbol);

        tickLower = _tickLower;
        tickUpper = _tickUpper;
        priceLower = UniswapLibrary.getSqrtRatio(_tickLower);
        priceUpper = UniswapLibrary.getSqrtRatio(_tickUpper);
        token0 = _token0;
        token1 = _token1;
        token0Decimals = _token0Decimals;
        token1Decimals = _token1Decimals;
        token0DecimalMultiplier =
            10**(TOKEN_DECIMAL_REPRESENTATION - token0Decimals);
        token1DecimalMultiplier =
            10**(TOKEN_DECIMAL_REPRESENTATION - token1Decimals);
        tokenDiffDecimalMultiplier =
            10**((UniswapLibrary.subAbs(token0Decimals, token1Decimals)));

        maxTwapDeviationDivisor = _maxTwapDeviationDivisor;
        poolFee = 3000;

        uniContracts = contracts;

        token0.safeIncreaseAllowance(uniContracts.router, type(uint256).max);
        token1.safeIncreaseAllowance(uniContracts.router, type(uint256).max);
        token0.safeIncreaseAllowance(
            uniContracts.positionManager,
            type(uint256).max
        );
        token1.safeIncreaseAllowance(
            uniContracts.positionManager,
            type(uint256).max
        );
        UniswapLibrary.approveOneInch(token0, token1);
        xTokenManager = IxTokenManager(_xTokenManagerAddress);

        lastTwap = getAsset0Price();
        twapPeriod = 3600;
    }

    /* ========================================================================================= */
    /*                                            User-facing                                    */
    /* ========================================================================================= */

    /**
     *  @dev Mint xAssetCLR tokens by sending *amount* of *inputAsset* tokens
     *  @dev amount of the other asset is auto-calculated
     */
    function mint(uint8 inputAsset, uint256 amount)
        external
        notLocked(msg.sender)
        whenNotPaused()
    {
        require(amount > 0);
        lock(msg.sender);
        checkTwap();
        (uint256 amount0, uint256 amount1) =
            calculateAmountsMintedSingleToken(inputAsset, amount);

        // Check if address has enough balance
        uint256 token0Balance = token0.balanceOf(msg.sender);
        uint256 token1Balance = token1.balanceOf(msg.sender);
        if (amount0 > token0Balance || amount1 > token1Balance) {
            amount0 = amount0 > token0Balance ? token0Balance : amount0;
            amount1 = amount1 > token1Balance ? token1Balance : amount1;
            (amount0, amount1) = calculatePoolMintedAmounts(amount0, amount1);
        }

        token0.safeTransferFrom(msg.sender, address(this), amount0);
        token1.safeTransferFrom(msg.sender, address(this), amount1);
        uint128 liquidityAmount =
            getLiquidityForAmounts(amount0, amount1);
        _mintInternal(liquidityAmount);

        // stake tokens in pool
         _stake(amount0, amount1);
    }

    /**
     *  @dev Burn *amount* of xAssetCLR tokens to receive proportional
     *  amount of pool tokens
     */
    function burn(uint256 amount) external notLocked(msg.sender) {
        require(amount > 0);
        lock(msg.sender);
        checkTwap();
        uint256 totalLiquidity = getTotalLiquidity();

        uint256 proRataBalance = amount.mul(totalLiquidity).div(totalSupply());

        super._burn(msg.sender, amount);
        (uint256 amount0, uint256 amount1) =
            getAmountsForLiquidity(uint128(proRataBalance));
        uint256 unstakeAmount0 = amount0.add(amount0.div(MINT_BURN_SLIPPAGE));
        uint256 unstakeAmount1 = amount1.add(amount1.div(MINT_BURN_SLIPPAGE));
        _unstake(unstakeAmount0, unstakeAmount1);
        token0.safeTransfer(msg.sender, amount0);
        token1.safeTransfer(msg.sender, amount1);
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
     * @notice Get Net Asset Value in terms of token 1
     * @dev NAV = token 0 amt * token 0 price + token1 amt
     */
    function getNav() public view returns (uint256) {
        return getStakedBalance().add(getBufferBalance());
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
                uniContracts.pool,
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
                uniContracts.pool,
                twapPeriod,
                token0Decimals,
                token1Decimals,
                tokenDiffDecimalMultiplier
            );
    }

    /**
     * @notice Get balance in xAssetCLR contract
     * @notice amount is represented in token 1 terms:
     * @dev token 0 amt * token 0 price + token1 amt
     */
    function getBufferBalance() public view returns (uint256) {
        (uint256 balance0, uint256 balance1) = getBufferTokenBalance();
        return getAmountInAsset1Terms(balance0).add(balance1);
    }

    /**
     * @notice Get total balance in the position
     * @notice amount is represented in token 1 terms:
     * @dev token 0 amt * token 0 price + token1 amt
     */
    function getStakedBalance() public view returns (uint256) {
        (uint256 amount0, uint256 amount1) = getStakedTokenBalance();
        return getAmountInAsset1Terms(amount0).add(amount1);
    }

    /**
     * @notice Get token balances in xAssetCLR contract
     * @dev returned balances are represented with 18 decimals
     */
    function getBufferTokenBalance()
        public
        view
        returns (uint256 amount0, uint256 amount1)
    {
        return (getBufferToken0Balance(), getBufferToken1Balance());
    }

    /**
     * @notice Get token0 balance in xAssetCLR
     * @dev returned balance is represented with 18 decimals
     */
    function getBufferToken0Balance() public view returns (uint256 amount0) {
        return getToken0AmountInWei(token0.balanceOf(address(this)));
    }

    /**
     * @notice Get token1 balance in xAssetCLR
     * @dev returned balance is represented with 18 decimals
     */
    function getBufferToken1Balance() public view returns (uint256 amount1) {
        return getToken1AmountInWei(token1.balanceOf(address(this)));
    }

    /**
     * @notice Get token balances in the position
     * @dev returned balance is represented with 18 decimals
     */
    function getStakedTokenBalance()
        public
        view
        returns (uint256 amount0, uint256 amount1)
    {
        (amount0, amount1) = getAmountsForLiquidity(getPositionLiquidity());
        amount0 = getToken0AmountInWei(amount0);
        amount1 = getToken1AmountInWei(amount1);
    }

    /**
     * @notice Get total liquidity
     * @dev buffer liquidity + position liquidity
     */
    function getTotalLiquidity() public view returns (uint256 amount) {
        (uint256 buffer0, uint256 buffer1) = getBufferTokenBalance();
        uint128 bufferLiquidity = getLiquidityForAmounts(buffer0, buffer1);
        uint128 positionLiquidity = getPositionLiquidity();
        return uint256(bufferLiquidity).add(uint256(positionLiquidity));
    }

    /**
     * @dev Check how much xAssetCLR tokens will be minted on mint
     * @dev Uses position liquidity to calculate the amount
     */
    function calculateMintAmount(uint256 _amount, uint256 totalSupply)
        public
        view
        returns (uint256 mintAmount)
    {
        if (totalSupply == 0) return _amount;
        uint256 previousLiquidity = getTotalLiquidity().sub(_amount);
        mintAmount = (_amount).mul(totalSupply).div(previousLiquidity);
        return mintAmount;
    }

    /* ========================================================================================= */
    /*                                            Management                                     */
    /* ========================================================================================= */

    /**
     * @dev Collect rewards from pool and stake them in position
     * @dev may leave unstaked tokens in contract
     */
    function collectAndRestake() external onlyOwnerOrManager {
        (uint256 amount0, uint256 amount1) = collect();
        (uint256 stakeAmount0, uint256 stakeAmount1) =
            calculatePoolMintedAmounts(amount0, amount1);
        _stake(stakeAmount0, stakeAmount1);
    }

    /**
     * @dev Collect fees generated from position
     */
    function collect()
        public
        onlyOwnerOrManager
        returns (uint256 collected0, uint256 collected1)
    {
        (collected0, collected1) = collectPosition(
            type(uint128).max,
            type(uint128).max
        );
        emit FeeCollected(collected0, collected1);
    }

    /**
     * @dev Migrate the current position to a new position with different ticks
     */
    function migratePosition(int24 newTickLower, int24 newTickUpper)
        public
        onlyOwnerOrManager
    {
        require(newTickLower != tickLower || newTickUpper != tickUpper);

        // withdraw entire liquidity from the position
        (uint256 _amount0, uint256 _amount1) = withdrawAll();
        // burn current position NFT
        UniswapLibrary.burn(uniContracts.positionManager, tokenId);
        // set new ticks and prices
        tickLower = newTickLower;
        tickUpper = newTickUpper;
        priceLower = UniswapLibrary.getSqrtRatio(newTickLower);
        priceUpper = UniswapLibrary.getSqrtRatio(newTickUpper);

        (uint256 amount0, uint256 amount1) =
            calculatePoolMintedAmounts(_amount0, _amount1);

        // mint the position NFT and deposit the liquidity
        // set new NFT token id
        tokenId = createPosition(amount0, amount1);
    }

    /**
     * @dev Migrate the current position to a new position with different ticks
     * @dev Migrates position tick lower and upper by same amount of ticks
     * @dev Tick spacing (minimum tick difference) in pool w/ 3000 fee is 60
     * @param ticks how many ticks to shift up or down
     * @param up whether to move tick range up or down
     */
    function migrateParallel(uint24 ticks, bool up)
        external
        onlyOwnerOrManager
    {
        require(ticks != 0);

        int24 newTickLower;
        int24 newTickUpper;
        int24 ticksToShift = int24(ticks) * 60;
        if (up) {
            newTickLower = tickLower + ticksToShift;
            newTickUpper = tickUpper + ticksToShift;
        } else {
            newTickLower = tickLower - ticksToShift;
            newTickUpper = tickUpper - ticksToShift;
        }
        migratePosition(newTickLower, newTickUpper);
    }

    /**
     * @dev Mint function which initializes the pool position
     * @dev Must be called before any liquidity can be deposited
     */
    function mintInitial(uint256 amount0, uint256 amount1)
        external
        onlyOwnerOrManager
    {
        require(tokenId == 0);
        require(amount0 > 0 || amount1 > 0);
        checkTwap();
        (uint256 amount0Minted, uint256 amount1Minted) =
            calculatePoolMintedAmounts(amount0, amount1);
        token0.safeTransferFrom(msg.sender, address(this), amount0Minted);
        token1.safeTransferFrom(msg.sender, address(this), amount1Minted);
        tokenId = createPosition(amount0Minted, amount1Minted);
        uint256 liquidity =
            uint256(getLiquidityForAmounts(amount0Minted, amount1Minted));
        _mintInternal(liquidity);
    }

    /**
     * @dev Admin function to stake tokens
     * @dev used in case there's leftover tokens in the contract
     */
    function adminRebalance() external onlyOwnerOrManager {
        UniswapLibrary.adminRebalance(
            UniswapLibrary.TokenDetails({
                token0: address(token0),
                token1: address(token1),
                token0DecimalMultiplier: token0DecimalMultiplier,
                token1DecimalMultiplier: token1DecimalMultiplier,
                tokenDiffDecimalMultiplier: tokenDiffDecimalMultiplier,
                token0Decimals: token0Decimals,
                token1Decimals: token1Decimals
            }),
            UniswapLibrary.PositionDetails({
                poolFee: poolFee,
                twapPeriod: twapPeriod,
                priceLower: priceLower,
                priceUpper: priceUpper,
                tokenId: tokenId,
                positionManager: uniContracts.positionManager,
                router: uniContracts.router,
                quoter: uniContracts.quoter,
                pool: uniContracts.pool
            })
        );
        emit Rebalance();
    }

    /**
     * @dev Admin function for staking in position
     */
    function adminStake(uint256 amount0, uint256 amount1)
        external
        onlyOwnerOrManager
    {
        (uint256 stakeAmount0, uint256 stakeAmount1) =
            calculatePoolMintedAmounts(amount0, amount1);
        _stake(stakeAmount0, stakeAmount1);
    }

    /**
     * @dev Admin function for unstaking from position
     */
    function adminUnstake(uint256 amount0, uint256 amount1)
        external
        onlyOwnerOrManager
    {
        _unstake(amount0, amount1);
    }

    /**
     * @dev Admin function for swapping LP tokens in xAssetCLR
     * @param amount - swap amount (in t0 terms if _0for1 is true, in t1 terms if false)
     * @param _0for1 - swap token 0 for 1 if true, token 1 for 0 if false
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
     * @dev Admin function for swapping LP tokens in xAssetCLR using 1inch v3 exchange
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
            minReturn,
            _0for1,
            UniswapLibrary.TokenDetails({
                token0: address(token0),
                token1: address(token1),
                token0DecimalMultiplier: token0DecimalMultiplier,
                token1DecimalMultiplier: token1DecimalMultiplier,
                tokenDiffDecimalMultiplier: tokenDiffDecimalMultiplier,
                token0Decimals: token0Decimals,
                token1Decimals: token1Decimals
            }),
            _oneInchData
        );
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
                uniContracts.positionManager,
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

    /**
     * @dev Withdraws all current liquidity from the position
     */
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
                tokenDiffDecimalMultiplier: tokenDiffDecimalMultiplier,
                token0Decimals: token0Decimals,
                token1Decimals: token1Decimals
            });
        UniswapLibrary.PositionDetails memory positionDetails =
            UniswapLibrary.PositionDetails({
                poolFee: poolFee,
                twapPeriod: twapPeriod,
                priceLower: priceLower,
                priceUpper: priceUpper,
                tokenId: tokenId,
                positionManager: uniContracts.positionManager,
                router: uniContracts.router,
                quoter: uniContracts.quoter,
                pool: uniContracts.pool
            });
        return
            UniswapLibrary.createPosition(
                amount0,
                amount1,
                uniContracts.positionManager,
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
                poolFee: poolFee,
                twapPeriod: twapPeriod,
                priceLower: priceLower,
                priceUpper: priceUpper,
                tokenId: tokenId,
                positionManager: uniContracts.positionManager,
                router: uniContracts.router,
                quoter: uniContracts.quoter,
                pool: uniContracts.pool
            });
        return UniswapLibrary.unstakePosition(liquidity, positionDetails);
    }

    function _mintInternal(uint256 _amount) private {
        uint256 mintAmount = calculateMintAmount(_amount, totalSupply());
        return super._mint(msg.sender, mintAmount);
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
        IERC20(address(token)).safeTransfer(receiver, tokenBal);
    }

    /**
     * Mint xAsset tokens using underlying 
     * xAsset contract needs to be approved
     * @param amount amount to mint
     * @param isToken0 if true, call mint on token0, else on token1
     */
    function adminMint(uint256 amount, bool isToken0) external onlyOwnerOrManager {
        if(isToken0) {
            IxAsset(address(token0)).mintWithToken(amount);
        } else {
            IxAsset(address(token1)).mintWithToken(amount);
        }
    }

    /**
     * Burn xAsset tokens using underlying 
     * @param amount amount to burn
     * @param isToken0 if true, call burn on token0, else on token1
     */
    function adminBurn(uint256 amount, bool isToken0) external onlyOwnerOrManager {
        if(isToken0) {
            IxAsset(address(token0)).burn(amount, false, 1);
        } else {
            IxAsset(address(token1)).burn(amount, false, 1);
        }
    }

    /**
     * Approve underlying token to xAsset tokens
     * @param isToken0 if token 0 is xAsset token, set to true, otherwise false
     */
    function adminApprove(bool isToken0) external onlyOwnerOrManager {
        if(isToken0) {
            token1.safeApprove(address(token0), type(uint256).max);
        } else {
            token0.safeApprove(address(token1), type(uint256).max);
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

    /**
     * @dev Swap token 0 for token 1 in xAssetCLR using Uni V3 Pool
     * @dev amounts should be in 18 decimals
     * @param amountIn - amount as maximum input for swap, in token 0 terms
     * @param amountOut - amount as output for swap, in token 0 terms
     */
    function swapToken0ForToken1(uint256 amountIn, uint256 amountOut) private {
        UniswapLibrary.swapToken0ForToken1(
            amountIn,
            amountOut,
            UniswapLibrary.PositionDetails({
                poolFee: poolFee,
                twapPeriod: twapPeriod,
                priceLower: priceLower,
                priceUpper: priceUpper,
                tokenId: tokenId,
                positionManager: uniContracts.positionManager,
                router: uniContracts.router,
                quoter: uniContracts.quoter,
                pool: uniContracts.pool
            }),
            UniswapLibrary.TokenDetails({
                token0: address(token0),
                token1: address(token1),
                token0DecimalMultiplier: token0DecimalMultiplier,
                token1DecimalMultiplier: token1DecimalMultiplier,
                tokenDiffDecimalMultiplier: tokenDiffDecimalMultiplier,
                token0Decimals: token0Decimals,
                token1Decimals: token1Decimals
            })
        );
    }

    /**
     * @dev Swap token 1 for token 0 in xAssetCLR using Uni V3 Pool
     * @dev amounts should be in 18 decimals
     * @param amountIn - amount as maximum input for swap, in token 1 terms
     * @param amountOut - amount as output for swap, in token 1 terms
     */
    function swapToken1ForToken0(uint256 amountIn, uint256 amountOut) private {
        UniswapLibrary.swapToken1ForToken0(
            amountIn,
            amountOut,
            UniswapLibrary.PositionDetails({
                poolFee: poolFee,
                twapPeriod: twapPeriod,
                priceLower: priceLower,
                priceUpper: priceUpper,
                tokenId: tokenId,
                positionManager: uniContracts.positionManager,
                router: uniContracts.router,
                quoter: uniContracts.quoter,
                pool: uniContracts.pool
            }),
            UniswapLibrary.TokenDetails({
                token0: address(token0),
                token1: address(token1),
                token0DecimalMultiplier: token0DecimalMultiplier,
                token1DecimalMultiplier: token1DecimalMultiplier,
                tokenDiffDecimalMultiplier: tokenDiffDecimalMultiplier,
                token0Decimals: token0Decimals,
                token1Decimals: token1Decimals
            })
        );
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
                uniContracts.positionManager
            );
    }

    /**
     * @dev Change pool fee and address
     */
    function changePool(address _poolAddress, uint24 _poolFee)
        external
        onlyOwnerOrManager
    {
        uniContracts.pool = _poolAddress;
        poolFee = _poolFee;
    }

    // Returns the current liquidity in the position
    function getPositionLiquidity() public view returns (uint128 liquidity) {
        return
            UniswapLibrary.getPositionLiquidity(
                uniContracts.positionManager,
                tokenId
            );
    }

    /**
     *  @dev Get asset 0 twap
     *  @dev Uses Uni V3 oracle, reading the TWAP from twap period
     *  @dev or the earliest oracle observation time if twap period is not set
     */
    function getAsset0Price() public view returns (int128) {
        return
            UniswapLibrary.getAsset0Price(
                uniContracts.pool,
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
                uniContracts.pool,
                twapPeriod,
                token0Decimals,
                token1Decimals,
                tokenDiffDecimalMultiplier
            );
    }

    /**
     * @dev Checks if twap deviates too much from the previous twap
     */
    function checkTwap() private {
        lastTwap = UniswapLibrary.checkTwap(
            uniContracts.pool,
            twapPeriod,
            token0Decimals,
            token1Decimals,
            tokenDiffDecimalMultiplier,
            lastTwap,
            maxTwapDeviationDivisor
        );
    }

    /**
     *  @dev Reset last twap if oracle price is consistently above the max deviation
     */
    function resetTwap() external onlyOwnerOrManager {
        lastTwap = getAsset0Price();
    }

    /**
     *  @dev Set the max twap deviation divisor
     *  @dev if twap moves more than the divisor specified
     *  @dev mint, burn and mintInitial functions are locked
     */
    function setMaxTwapDeviationDivisor(uint256 newDeviationDivisor)
        external
        onlyOwnerOrManager
    {
        maxTwapDeviationDivisor = newDeviationDivisor;
    }

    /**
     * @dev Set the oracle reading twap period
     * @dev Twap used is [now - twapPeriod, now]
     */
    function setTwapPeriod(uint32 newPeriod) external onlyOwnerOrManager {
        require(newPeriod >= 360);
        twapPeriod = newPeriod;
    }

    /**
     * @dev Calculates the amounts deposited/withdrawn from the pool
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

    /**
     * @dev Calculates single-side minted amount
     * @param inputAsset - use token0 if 0, token1 else
     * @param amount - amount to deposit/withdraw
     */
    function calculateAmountsMintedSingleToken(uint8 inputAsset, uint256 amount)
        public
        view
        returns (uint256 amount0Minted, uint256 amount1Minted)
    {
        uint128 liquidityAmount;
        if (inputAsset == 0) {
            liquidityAmount = getLiquidityForAmounts(amount, type(uint112).max);
        } else {
            liquidityAmount = getLiquidityForAmounts(type(uint112).max, amount);
        }
        (amount0Minted, amount1Minted) = getAmountsForLiquidity(
            liquidityAmount
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
            uniContracts.pool
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
            uniContracts.pool
        );
    }

    /**
     *  @dev Get lower and upper ticks of the pool position
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
}
