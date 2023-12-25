// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./ReentrancyGuard.sol";

import "./Constant.sol";
import "./PoolAddress.sol";
import "./CallbackValidation.sol";
import "./TransferHelper.sol";
import "./FullMath.sol";

import "./IUniswapV3Pool.sol";
import "./IWETH9.sol";
import "./ITITANX.sol";

contract BuyAndBurnV2 is ReentrancyGuard {
    /** @dev genesis timestamp */
    uint256 private immutable i_genesisTs;

    /** @dev owner address */
    address private s_ownerAddress;

    /** @dev tracks total weth used for buyandburn */
    uint256 private s_totalWethBuyAndBurn;

    /** @dev tracks titan burned through buyandburn */
    uint256 private s_totalTitanBuyAndBurn;

    /** @dev tracks current per swap cap */
    uint256 private s_capPerSwap;

    /** @dev tracks timestamp of the last buynburn was called */
    uint256 private s_lastCallTs;

    /** @dev slippage amount between 0 - 50 */
    uint256 private s_slippage;

    /** @dev buynburn interval in seconds */
    uint256 private s_interval;

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

    constructor() {
        i_genesisTs = block.timestamp;
        s_ownerAddress = msg.sender;
        s_capPerSwap = 1 ether;
        s_slippage = 5;
        s_interval = 60;
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

    /**
     * @notice set weth cap amount per buynburn call. Only callable by owner address.
     * @param amount amount in 18 decimals
     */
    function setCapPerSwap(uint256 amount) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        s_capPerSwap = amount;
    }

    /**
     * @notice set slippage % for buynburn minimum received amount. Only callable by owner address.
     * @param amount amount from 0 - 50
     */
    function setSlippage(uint256 amount) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(amount >= 5 && amount <= 15, "5-15_Only");
        s_slippage = amount;
    }

    /**
     * @notice set buynburn call interval in seconds. Only callable by owner address.
     * @param secs amount in seconds
     */
    function setBuynBurnInterval(uint256 secs) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(
            secs >= MIN_INTERVAL_SECONDS && secs <= MAX_INTERVAL_SECONDS,
            "1m-12h_Only"
        );
        s_interval = secs;
    }

    /** @notice burn all Titan in BuyAndBurn address */
    function burnLPTitan() public {
        ITITANX(TITANX).burnLPTokens();
    }

    /** @notice buy and burn Titan from uniswap pool */
    function buynBurn() public nonReentrant {
        //prevent contract accounts (bots) from calling this function
        require(msg.sender == tx.origin, "InvalidCaller");
        //a minium gap of 1 min between each call
        require(block.timestamp - s_lastCallTs > s_interval, "IntervalWait");
        s_lastCallTs = block.timestamp;

        uint256 wethAmount = getWethBalance(address(this));
        require(wethAmount != 0, "NoAvailableFunds");

        uint256 wethCap = s_capPerSwap;
        if (wethAmount > wethCap) wethAmount = wethCap;

        uint256 incentiveFee = (wethAmount * INCENTIVE_FEE) /
            INCENTIVE_FEE_PERCENT_BASE;
        IWETH9(WETH9).withdraw(incentiveFee);

        wethAmount -= incentiveFee;
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
            TITANX,
            POOLFEE1PERCENT
        );
        require(address(pool) == TITANX_WETH_POOL, "WrongPool");

        //swap weth for titan
        TransferHelper.safeTransferFrom(
            WETH9,
            address(this),
            msg.sender,
            amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta)
        );

        s_totalWethBuyAndBurn += amount0Delta > 0
            ? uint256(amount0Delta)
            : uint256(amount1Delta);
    }

    // ==================== Private Functions =======================================
    /** @dev call uniswap swap function to swap weth for titan, then burn all titan
     * @param amountWETH weth amount
     */
    function _swapWETHForTitan(uint256 amountWETH) private {
        //calculate minimum amount for slippage protection
        uint256 minTokenAmount = ((amountWETH * 1 ether * (100 - s_slippage)) /
            getCurrentEthPrice()) / 100;

        (int256 amount0, int256 amount1) = IUniswapV3Pool(TITANX_WETH_POOL)
            .swap(
                address(this),
                WETH9 < TITANX,
                int256(amountWETH),
                WETH9 < TITANX ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
                ""
            );
        uint256 titan = WETH9 < TITANX
            ? uint256(amount1 >= 0 ? amount1 : -amount1)
            : uint256(amount0 >= 0 ? amount0 : -amount0);

        //slippage protection check
        require(titan >= minTokenAmount, "TooLittleReceived");

        s_totalTitanBuyAndBurn += titan;
        burnLPTitan();
        emit BoughtAndBurned(amountWETH, titan, msg.sender);
    }

    //views
    /** @notice get titanx weth pool address
     * @return address titanx weth pool address
     */
    function getPoolAddress() public pure returns (address) {
        return TITANX_WETH_POOL;
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
        return ITITANX(TITANX).balanceOf(account);
    }

    /** @notice get buy and burn current contract day
     * @return day current contract day
     */
    function getCurrentContractDay() public view returns (uint256) {
        return ((block.timestamp - i_genesisTs) / SECONDS_IN_DAY) + 1;
    }

    /** @notice get current sqrt price
     * @return sqrtPrice sqrt Price X96
     */
    function getCurrentSqrtPriceX96() public view returns (uint160) {
        IUniswapV3Pool pool = IUniswapV3Pool(TITANX_WETH_POOL);
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        return sqrtPriceX96;
    }

    /** @notice get current eth price
     * @return ethPrice eth price
     */
    function getCurrentEthPrice() public view returns (uint256) {
        IUniswapV3Pool pool = IUniswapV3Pool(TITANX_WETH_POOL);
        (uint256 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint256 numerator1 = sqrtPriceX96 * sqrtPriceX96;
        uint256 numerator2 = 10 ** 18;
        uint256 price = FullMath.mulDiv(numerator1, numerator2, 1 << 192);
        price = WETH9 < TITANX ? (1 ether * 1 ether) / price : price;
        return price;
    }

    /** @notice get cap amount per buy and burn
     * @return cap amount
     */
    function getWethBuyAndBurnCap() public view returns (uint256) {
        return s_capPerSwap;
    }

    /** @notice get buynburn slippage
     * @return slippage
     */
    function getSlippage() public view returns (uint256) {
        return s_slippage;
    }

    /** @notice get the buynburn interval between each call in seconds
     * @return seconds
     */
    function getBuynBurnInterval() public view returns (uint256) {
        return s_interval;
    }

    /** @notice since burnLPTokens in TitanX reads the BuyAndBurn CA, TitanX in V1 will not be burned when CA we migrate to V2,
     * so we just have remove the supply owned by V1
     * @return return the actual total supply
     */
    function totalTitanXLiquidSupply() public view returns (uint256) {
        return ITITANX(TITANX).totalSupply() - getTitanBalance(BUYANDBURNV1);
    }

    // ==================== BuyAndBurnV2 Getters =======================================
    /** @notice get buy and burn funds (exclude weth fees)
     * @return amount weth amount
     */
    function getBuyAndBurnFundsV2() public view returns (uint256) {
        return getWethBalance(address(this));
    }

    /** @notice get total weth amount used to buy and burn (exclude weth fees)
     * @return amount total weth amount
     */
    function getTotalWethBuyAndBurnV2() public view returns (uint256) {
        return s_totalWethBuyAndBurn;
    }

    /** @notice get total titan amount burned from all buy and burn
     * @return amount total titan amount
     */
    function getTotalTitanBuyAndBurnV2() public view returns (uint256) {
        return s_totalTitanBuyAndBurn;
    }
}
