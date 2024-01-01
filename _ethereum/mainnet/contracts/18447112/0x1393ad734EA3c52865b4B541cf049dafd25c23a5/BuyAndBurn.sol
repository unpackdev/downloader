// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";
import "./INonfungiblePositionManager.sol";
import "./ReentrancyGuard.sol";

import "./PoolAddress.sol";
import "./CallbackValidation.sol";
import "./TransferHelper.sol";
import "./FullMath.sol";

import "./IWETH9.sol";
import "./ITITANX.sol";
import "./Constant.sol";

contract BuyAndBurn is ReentrancyGuard {
    /** @dev genesis timestamp */
    uint256 private immutable i_genesisTs;

    /** @dev titanx address */
    address private s_titanxAddress;
    /** @dev owner address */
    address private s_ownerAddress;
    /** @dev titanx weth uniswapv3 pool address */
    address private s_poolAddress;
    /** @dev is initial LP created */
    InitialLPCreated private s_initialLiquidityCreated;

    /** @dev tracks collect fees (weth) for buyandburn */
    uint88 private s_feesBuyAndBurn;

    /** @dev tracks total buyandburn from weth exclude weth fees */
    uint256 private s_totalWethBuyAndBurn;
    /** @dev tracks total buyandburn from fees (weth) */
    uint256 private s_totalWethFeesBuyAndBurn;

    /** @dev tracks titan burned through buyandburn */
    uint256 private s_totalTitanBuyAndBurn;
    /** @dev tracks total titan burned from fees (titanx) */
    uint256 private s_totalTitanFeesBurn;

    /** @dev tracks current global swap cap */
    uint256 private s_globalSwapCap = START_GLOBAL_SWAP_CAP;
    /** @dev tracks current per swap cap */
    uint256 private s_capPerSwap = START_PER_SWAP_CAP;

    /** @dev store position token info, only one full range position */
    TokenInfo private s_tokenInfo;

    //structs
    struct TokenInfo {
        uint80 tokenId;
        uint128 liquidity;
        int24 tickLower;
        int24 tickUpper;
    }

    event BoughtAndBurned(
        uint256 indexed weth,
        uint256 indexed titan,
        address indexed caller
    );
    event CollectedFees(
        uint256 indexed weth,
        uint256 indexed titan,
        address indexed caller
    );

    constructor(address ownerAddress) {
        require(ownerAddress != address(0), "InvalidAddress");
        i_genesisTs = block.timestamp;
        s_ownerAddress = ownerAddress;
    }

    /** @notice receive eth and convert all eth into weth */
    receive() external payable {
        //prevent ETH withdrawal received from WETH contract into deposit function
        if (msg.sender != WETH9) IWETH9(WETH9).deposit{value: msg.value}();
    }

    /** @notice remove owner */
    function renounceOwnership() public {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        s_ownerAddress = address(0);
    }

    /** @notice set new owner address. Only callable by owner address.
     * @param ownerAddress new owner address
     */
    function setOwnerAddress(address ownerAddress) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(ownerAddress != address(0), "InvalidAddress");
        s_ownerAddress = ownerAddress;
    }

    /** @notice set titanx address. Only callable by owner address.
     * @param titanxAddress titanx contract address
     */
    function setTitanContractAddress(address titanxAddress) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(s_titanxAddress == address(0), "CannotResetAddress");
        require(titanxAddress != address(0), "InvalidAddress");
        s_titanxAddress = titanxAddress;
    }

    /**
     * @notice set global buy and burn Weth cap. Only callable by owner address.
     * @param amount amount in 18 decimals
     */
    function setGlobalWethBuyAndBurnCap(uint256 amount) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(amount > s_globalSwapCap, "MustBeGreaterAmount");
        s_globalSwapCap = amount;
    }

    /**
     * @notice set weth cap amount per buynburn call. Only callable by owner address.
     * @param amount amount in 18 decimals
     */
    function setCapPerSwap(uint256 amount) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(amount >= START_PER_SWAP_CAP, "Min1WETH");
        s_capPerSwap = amount;
    }

    /** @notice burn all Titan in BuyAndBurn address */
    function burnLPTitan() public {
        ITITANX(s_titanxAddress).burnLPTokens();
    }

    /** @notice buy and burn Titan from uniswap pool */
    function buynBurn() public nonReentrant {
        require(
            s_initialLiquidityCreated == InitialLPCreated.YES,
            "NeedInitialLP"
        );

        uint256 globalWethCap = s_globalSwapCap;
        uint256 totalWethBuyAndBurn = s_totalWethBuyAndBurn +
            s_totalWethFeesBuyAndBurn;
        require(totalWethBuyAndBurn < globalWethCap, "ReachMaxGlobalCap");

        uint256 wethAmount = getWethBalance(address(this));
        require(wethAmount != 0, "NoAvailableFunds");

        uint256 wethCap = s_capPerSwap;
        if (wethAmount > wethCap) wethAmount = wethCap;
        if (totalWethBuyAndBurn + wethAmount > globalWethCap) {
            wethAmount = globalWethCap - totalWethBuyAndBurn;
            //due to incentive fees, we add 0.5% of the weth amount to make sure we can hit the global cap after incentive fees deduction
            wethAmount += (wethAmount * 50) / 10000;
            //at this point, if the amount is greater than the balance,
            //means the above addition amount difference is within the 0.5% added on top, then just use all the balance
            uint256 balance = getWethBalance(address(this));
            if (wethAmount > balance) wethAmount = balance;
        }

        //update s_totalWethFeesBuyAndBurn from collected fees
        uint256 feeFunds = s_feesBuyAndBurn;
        if (feeFunds != 0) {
            if (wethAmount < feeFunds) {
                feeFunds = wethAmount;
                s_feesBuyAndBurn -= uint88(feeFunds);
            } else {
                s_feesBuyAndBurn = 0;
            }
            //deduct out the incentive fees from s_feesBuyAndBurn
            feeFunds -= (feeFunds * INCENTIVE_FEE) / INCENTIVE_FEE_PERCENT_BASE;
            s_totalWethFeesBuyAndBurn += feeFunds;
        }

        uint256 incentiveFee = (wethAmount * INCENTIVE_FEE) /
            INCENTIVE_FEE_PERCENT_BASE;
        IWETH9(WETH9).withdraw(incentiveFee);

        wethAmount -= incentiveFee;
        //update s_totalWethBuyAndBurn which excludes collected fees
        if (wethAmount - feeFunds > 0)
            s_totalWethBuyAndBurn += wethAmount - feeFunds;

        _swapWETHForTitan(wethAmount);
        TransferHelper.safeTransferETH(payable(msg.sender), incentiveFee);
    }

    /** @notice Used by uniswapV3. Modified from uniswapV3 swap callback function to complete the swap */
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        IUniswapV3Pool pool = CallbackValidation.verifyCallback(
            UNISWAPV3FACTORY,
            WETH9,
            s_titanxAddress,
            POOLFEE1PERCENT
        );
        require(address(pool) == s_poolAddress, "WrongPool");

        //swap weth for titan
        TransferHelper.safeTransferFrom(
            WETH9,
            address(this),
            msg.sender,
            amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta)
        );
    }

    /** @notice One-time function to create initial pool to initialize with the desired price ratio.
     * To avoid being front run, must call this function right after contract is deployed and titanx address is set.
     */
    function createInitialPool() public {
        require(s_poolAddress == address(0), "PoolHasCreated");
        require(s_titanxAddress != address(0), "InvalidTitanxAddress");
        _createPool();
    }

    /** @notice One-time function to create initial liquidity pool. Require 28 Weth to execute. */
    function createInitialLiquidity() public {
        require(s_poolAddress != address(0), "NoPoolExists");
        if (s_initialLiquidityCreated == InitialLPCreated.YES) return;
        require(getWethBalance(address(this)) >= INITIAL_LP_WETH, "Need8WETH");

        s_initialLiquidityCreated = InitialLPCreated.YES;

        // Approve the position manager
        TransferHelper.safeApprove(
            s_titanxAddress,
            NONFUNGIBLEPOSITIONMANAGER,
            type(uint256).max
        );
        TransferHelper.safeApprove(
            WETH9,
            NONFUNGIBLEPOSITIONMANAGER,
            type(uint256).max
        );

        ITITANX(s_titanxAddress).mintLPTokens();
        _mintPosition();
    }

    /** @notice collect fees from LP */
    function collectFees() public nonReentrant {
        (uint256 amount0, uint256 amount1) = _collectFees();
        uint256 titan;
        uint256 weth;
        if (WETH9 < s_titanxAddress) {
            weth = uint256(amount0 >= 0 ? amount0 : -amount0);
            titan = uint256(amount1 >= 0 ? amount1 : -amount1);
        } else {
            titan = uint256(amount0 >= 0 ? amount0 : -amount0);
            weth = uint256(amount1 >= 0 ? amount1 : -amount1);
        }

        s_totalTitanFeesBurn += titan;
        s_feesBuyAndBurn += uint88(weth);
        burnLPTitan();
        emit CollectedFees(weth, titan, msg.sender);
    }

    // ==================== Private Functions =======================================
    /** @dev sort tokens in ascending order, that's how uniswap identify the pair
     * @return token0 token address that is digitally smaller than token1
     * @return token1 token address that is digitally larger than token0
     * @return amount0 LP amount for token0
     * @return amount1 LP amount for token1
     */
    function _getTokensConfig()
        private
        view
        returns (
            address token0,
            address token1,
            uint256 amount0,
            uint256 amount1
        )
    {
        token0 = WETH9;
        token1 = s_titanxAddress;
        amount0 = INITIAL_LP_WETH;
        amount1 = INITIAL_LP_TITAN;
        if (s_titanxAddress < WETH9) {
            token0 = s_titanxAddress;
            token1 = WETH9;
            amount0 = INITIAL_LP_TITAN;
            amount1 = INITIAL_LP_WETH;
        }
    }

    /** @dev create pool with the preset sqrt price ratio */
    function _createPool() private {
        (address token0, address token1, , ) = _getTokensConfig();
        s_poolAddress = INonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER)
            .createAndInitializePoolIfNecessary(
                token0,
                token1,
                POOLFEE1PERCENT,
                WETH9 < s_titanxAddress
                    ? INITIAL_SQRTPRICE_WETH_TITANX
                    : INITIAL_SQRTPRICE_TITANX_WETH
            );
    }

    /** @dev mint full range LP token */
    function _mintPosition() private {
        (
            address token0,
            address token1,
            uint256 amount0Desired,
            uint256 amount1Desired
        ) = _getTokensConfig();

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: POOLFEE1PERCENT,
                tickLower: MIN_TICK,
                tickUpper: MAX_TICK,
                amount0Desired: amount0Desired,
                amount1Desired: amount1Desired,
                amount0Min: (amount0Desired * 90) / 100,
                amount1Min: (amount1Desired * 90) / 100,
                recipient: address(this),
                deadline: block.timestamp + 600
            });

        (uint256 tokenId, uint256 liquidity, , ) = INonfungiblePositionManager(
            NONFUNGIBLEPOSITIONMANAGER
        ).mint(params);

        s_tokenInfo.tokenId = uint80(tokenId);
        s_tokenInfo.liquidity = uint128(liquidity);
        s_tokenInfo.tickLower = MIN_TICK;
        s_tokenInfo.tickUpper = MAX_TICK;
    }

    /** @dev call uniswapv3 collect funtion to collect LP fees
     * @return amount0 token0 amount
     * @return amount1 token1 amount
     */
    function _collectFees() private returns (uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams(
                s_tokenInfo.tokenId,
                address(this),
                type(uint128).max,
                type(uint128).max
            );
        (amount0, amount1) = INonfungiblePositionManager(
            NONFUNGIBLEPOSITIONMANAGER
        ).collect(params);
    }

    /** @dev call uniswap swap function to swap weth for titan, then burn all titan
     * @param amountWETH weth amount
     */
    function _swapWETHForTitan(uint256 amountWETH) private {
        (int256 amount0, int256 amount1) = IUniswapV3Pool(s_poolAddress).swap(
            address(this),
            WETH9 < s_titanxAddress,
            int256(amountWETH),
            WETH9 < s_titanxAddress ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
            ""
        );
        uint256 titan = WETH9 < s_titanxAddress
            ? uint256(amount1 >= 0 ? amount1 : -amount1)
            : uint256(amount0 >= 0 ? amount0 : -amount0);
        s_totalTitanBuyAndBurn += titan;
        burnLPTitan();
        emit BoughtAndBurned(amountWETH, titan, msg.sender);
    }

    //views
    /** @notice get titanx weth pool address
     * @return address titanx weth pool address
     */
    function getPoolAddress() public view returns (address) {
        return s_poolAddress;
    }

    /** @notice get contract ETH balance
     * @return balance contract ETH balance
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /** @notice get WETH balance for speciifed address
     * @param account address
     * @return balance WETH balance
     */
    function getWethBalance(address account) public view returns (uint256) {
        return IWETH9(WETH9).balanceOf(account);
    }

    /** @notice get titan balance for speicifed address
     * @param account address
     */
    function getTitanBalance(address account) public view returns (uint256) {
        return ITITANX(s_titanxAddress).balanceOf(account);
    }

    /** @notice get buy and burn current contract day
     * @return day current contract day
     */
    function getCurrentContractDay() public view returns (uint256) {
        return ((block.timestamp - i_genesisTs) / SECONDS_IN_DAY) + 1;
    }

    /** @notice get buy and burn funds (exclude weth fees)
     * @return amount weth amount
     */
    function getBuyAndBurnFunds() public view returns (uint256) {
        return getWethBalance(address(this)) - s_feesBuyAndBurn;
    }

    /** @notice get buy and burn funds from weth fees only
     * @return amount weth amount
     */
    function getFeesBuyAndBurnFunds() public view returns (uint256) {
        return s_feesBuyAndBurn;
    }

    /** @notice get total weth amount used to buy and burn (exclude weth fees)
     * @return amount total weth amount
     */
    function getTotalWethBuyAndBurn() public view returns (uint256) {
        return s_totalWethBuyAndBurn;
    }

    /** @notice get total weth amount from fees only used to buy and burn
     * @return amount total weth amount
     */
    function getTotalWethFeesBuyAndBurn() public view returns (uint256) {
        return s_totalWethFeesBuyAndBurn;
    }

    /** @notice get total titan amount burned from all buy and burn
     * @return amount total titan amount
     */
    function getTotalTitanBuyAndBurn() public view returns (uint256) {
        return s_totalTitanBuyAndBurn;
    }

    /** @notice get total titan amount burned from collected LP fees
     * @return amount total titan amount
     */
    function getTotalTitanFeesBurn() public view returns (uint256) {
        return s_totalTitanFeesBurn;
    }

    /** @notice get LP token info
     * @return tokenId tokenId
     * @return liquidity liquidity
     * @return tickLower tickLower
     * @return tickUpper tickUpper
     */
    function getTokenInfo()
        public
        view
        returns (
            uint256 tokenId,
            uint256 liquidity,
            int24 tickLower,
            int24 tickUpper
        )
    {
        return (
            s_tokenInfo.tokenId,
            s_tokenInfo.liquidity,
            s_tokenInfo.tickLower,
            s_tokenInfo.tickUpper
        );
    }

    /** @notice get LP token URI
     * @return uri URI
     */
    function getTokenURI() public view returns (string memory) {
        return
            INonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER).tokenURI(1);
    }

    /** @notice get current sqrt price
     * @return sqrtPrice sqrt Price X96
     */
    function getCurrentSqrtPriceX96() public view returns (uint160) {
        IUniswapV3Pool pool = IUniswapV3Pool(s_poolAddress);
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        return sqrtPriceX96;
    }

    /** @notice get current eth price
     * @return ethPrice eth price
     */
    function getCurrentEthPrice() public view returns (uint256) {
        IUniswapV3Pool pool = IUniswapV3Pool(s_poolAddress);
        (uint256 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint256 numerator1 = sqrtPriceX96 * sqrtPriceX96;
        uint256 numerator2 = 10 ** 18;
        uint256 price = FullMath.mulDiv(numerator1, numerator2, 1 << 192);
        price = WETH9 < s_titanxAddress ? (1 ether * 1 ether) / price : price;
        return price;
    }

    /** @notice get titanx address
     * @return titanxAddress titanx address
     */
    function gettitanxAddress() public view returns (address) {
        return s_titanxAddress;
    }

    /** @notice get global buy and burn cap
     * @return cap amount
     */
    function getGlobalWethBuyAndBurnCap() public view returns (uint256) {
        return s_globalSwapCap;
    }

    /** @notice get cap amount per buy and burn
     * @return cap amount
     */
    function getWethBuyAndBurnCap() public view returns (uint256) {
        return s_capPerSwap;
    }
}
