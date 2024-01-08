// SPDX-License-Identifier: ISC

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./BlockLock.sol";

import "./IxALPHA.sol";
import "./IxTokenManager.sol";
import "./IWETH.sol";
import "./IALPHAStaking.sol";
import "./ISushiswapRouter.sol";
import "./IUniswapV3SwapRouter.sol";
import "./IStakingProxy.sol";

import "./StakingFactory.sol";

// solhint-disable-next-line contract-name-camelcase
contract xALPHA is Initializable, ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable, IxALPHA, BlockLock {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for SafeERC20Upgradeable;
    using SafeERC20 for IERC20;

    uint256 private constant LIQUIDATION_TIME_PERIOD = 4 weeks;
    uint256 private constant INITIAL_SUPPLY_MULTIPLIER = 10;
    uint256 private constant STAKING_PROXIES_AMOUNT = 5;
    uint256 private constant MAX_UINT = 2**256 - 1;

    address private constant ETH_ADDRESS = address(0);
    IWETH private weth;
    IERC20 private alphaToken;
    StakingFactory private stakingFactory;
    address private stakingProxyImplementation;

    // The total amount staked across all proxies
    uint256 public totalStakedBalance;

    uint256 public adminActiveTimestamp;
    uint256 public withdrawableAlphaFees;
    uint256 public emergencyUnbondTimestamp;
    uint256 public lastStakeTimestamp;

    IxTokenManager private xTokenManager; // xToken manager contract
    address private uniswapRouter;
    address private sushiswapRouter;
    SwapMode private swapMode;
    FeeDivisors public feeDivisors;
    uint24 public v3AlphaPoolFee;

    function initialize(
        string calldata _symbol,
        IWETH _wethToken,
        IERC20 _alphaToken,
        address _alphaStaking,
        StakingFactory _stakingFactory,
        IxTokenManager _xTokenManager,
        address _uniswapRouter,
        address _sushiswapRouter,
        FeeDivisors calldata _feeDivisors
    ) external override initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained("xALPHA", _symbol);

        weth = _wethToken;
        alphaToken = _alphaToken;
        stakingFactory = _stakingFactory;
        xTokenManager = _xTokenManager;
        uniswapRouter = _uniswapRouter;
        sushiswapRouter = _sushiswapRouter;
        updateSwapRouter(SwapMode.UNISWAP_V3);

        // Approve WETH and ALPHA for both swap routers
        alphaToken.safeApprove(sushiswapRouter, MAX_UINT);
        IERC20(address(weth)).safeApprove(sushiswapRouter, MAX_UINT);

        alphaToken.safeApprove(uniswapRouter, MAX_UINT);
        IERC20(address(weth)).safeApprove(uniswapRouter, MAX_UINT);

        v3AlphaPoolFee = 10000;

        _setFeeDivisors(_feeDivisors.mintFee, _feeDivisors.burnFee, _feeDivisors.claimFee);

        // Initialize the staking proxies
        for (uint256 i = 0; i < STAKING_PROXIES_AMOUNT; ++i) {
            // Deploy the proxy
            stakingFactory.deployProxy();

            // Initialize
            IStakingProxy(stakingFactory.stakingProxyProxies(i)).initialize(_alphaStaking);
        }
    }

    /* ========================================================================================= */
    /*                                          User functions                                   */
    /* ========================================================================================= */

    /*
     * @dev Mint xALPHA using ETH
     * @notice Assesses mint fee
     * @param minReturn: Min return to pass to Uniswap trade
     *
     * This function swaps ETH to ALPHA using 1inch.
     */
    function mint(uint256 minReturn) external payable override whenNotPaused notLocked(msg.sender) {
        require(msg.value > 0, "Must send ETH");
        _lock(msg.sender);

        // Swap ETH for ALPHA
        uint256 alphaAmount = _swapETHforALPHAInternal(msg.value, minReturn);

        uint256 fee = _calculateFee(alphaAmount, feeDivisors.mintFee);
        _incrementWithdrawableAlphaFees(fee);

        return _mintInternal(alphaAmount.sub(fee));
    }

    /*
     * @dev Mint xALPHA using ALPHA
     * @notice Assesses mint fee
     *
     * @param alphaAmount: ALPHA tokens to contribute
     *
     * The xALPHA contract must be approved to withdraw ALPHA from the
     * sender's wallet.
     */
    function mintWithToken(uint256 alphaAmount) external override whenNotPaused notLocked(msg.sender) {
        require(alphaAmount > 0, "Must send token");
        _lock(msg.sender);

        alphaToken.safeTransferFrom(msg.sender, address(this), alphaAmount);

        uint256 fee = _calculateFee(alphaAmount, feeDivisors.mintFee);
        _incrementWithdrawableAlphaFees(fee);

        return _mintInternal(alphaAmount.sub(fee));
    }

    /*
     * @dev Perform mint action
     * @param _incrementalAlpha: ALPHA tokens to contribute
     *
     * No safety checks since internal function. After calculating
     * the mintAmount based on the current liquidity ratio, it mints
     * xALPHA (using ERC20 mint).
     */
    function _mintInternal(uint256 _incrementalAlpha) private {
        uint256 mintAmount = calculateMintAmount(_incrementalAlpha, totalSupply());

        return super._mint(msg.sender, mintAmount);
    }

    /*
     * @dev Calculate mint amount for xALPHA
     *
     * @param _incrementalAlpha: ALPHA tokens to contribute
     * @param totalSupply: total supply of xALPHA tokens to calculate against
     *
     * @return mintAmount: the amount of xALPHA that will be minted
     *
     * Calculate the amount of xALPHA that will be minted for a
     * proportionate amount of ALPHA. In practice, totalSupply will
     * equal the total supply of xALPHA.
     */
    function calculateMintAmount(uint256 incrementalAlpha, uint256 totalSupply)
        public
        view
        override
        returns (uint256 mintAmount)
    {
        if (totalSupply == 0) return incrementalAlpha.mul(INITIAL_SUPPLY_MULTIPLIER);
        uint256 previousNav = getNav().sub(incrementalAlpha);
        mintAmount = incrementalAlpha.mul(totalSupply).div(previousNav);
    }

    /*
     * @dev Burn xALPHA tokens
     * @notice Will fail if pro rata balance exceeds available liquidity
     * @notice Assesses burn fee
     *
     * @param tokenAmount: xALPHA tokens to burn
     * @param redeemForEth: Redeem for ETH or ALPHA
     * @param minReturn: Min return to pass to 1inch trade
     *
     * Burns the sent amount of xALPHA and calculates the proportionate
     * amount of ALPHA. Either sends the ALPHA to the caller or exchanges
     * it for ETH.
     */
    function burn(
        uint256 tokenAmount,
        bool redeemForEth,
        uint256 minReturn
    ) external override notLocked(msg.sender) {
        require(tokenAmount > 0, "Must send xALPHA");
        _lock(msg.sender);

        (uint256 stakedBalance, uint256 bufferBalance) = getFundBalances();
        uint256 alphaHoldings = stakedBalance.add(bufferBalance);
        uint256 proRataAlpha = alphaHoldings.mul(tokenAmount).div(totalSupply());

        require(proRataAlpha <= bufferBalance, "Insufficient exit liquidity");
        super._burn(msg.sender, tokenAmount);

        uint256 fee = _calculateFee(proRataAlpha, feeDivisors.burnFee);
        _incrementWithdrawableAlphaFees(fee);

        uint256 withdrawAmount = proRataAlpha.sub(fee);

        if (redeemForEth) {
            uint256 ethAmount = _swapALPHAForETHInternal(withdrawAmount, minReturn);
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = msg.sender.call{ value: ethAmount }(new bytes(0));
            require(success, "ETH burn transfer failed");
        } else {
            alphaToken.safeTransfer(msg.sender, withdrawAmount);
        }
    }

    /*
     * @inheritdoc ERC20
     */
    function transfer(address recipient, uint256 amount) public override notLocked(msg.sender) returns (bool) {
        return super.transfer(recipient, amount);
    }

    /*
     * @inheritdoc ERC20
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override notLocked(sender) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    /*
     * @dev Swap ETH for ALPHA
     * @notice uses either Sushiswap or Uniswap V3 depending on version
     *
     * @param ethAmount: amount of ETH to swap
     * @param minReturn: Min return to pass to Uniswap trade
     *
     * @return amount of ALPHA returned in the swap
     *
     * These swaps always use 'exact input' - they send exactly the amount specified
     * in arguments to the swap, and the output amount is calculated.
     */
    function _swapETHforALPHAInternal(uint256 ethAmount, uint256 minReturn) private returns (uint256) {
        uint256 deadline = MAX_UINT;

        if (swapMode == SwapMode.SUSHISWAP) {
            // SUSHISWAP
            IUniswapV2Router02 routerV2 = IUniswapV2Router02(sushiswapRouter);

            address[] memory path = new address[](2);
            path[0] = address(weth);
            path[1] = address(alphaToken);

            uint256[] memory amounts = routerV2.swapExactETHForTokens{ value: ethAmount }(
                minReturn,
                path,
                address(this),
                deadline
            );

            return amounts[1];
        } else {
            // UNISWAP V3
            IUniswapV3SwapRouter routerV3 = IUniswapV3SwapRouter(uniswapRouter);

            weth.deposit{ value: ethAmount }();

            IUniswapV3SwapRouter.ExactInputSingleParams memory params = IUniswapV3SwapRouter.ExactInputSingleParams({
                tokenIn: address(weth),
                tokenOut: address(alphaToken),
                fee: v3AlphaPoolFee,
                recipient: address(this),
                deadline: deadline,
                amountIn: ethAmount,
                amountOutMinimum: minReturn,
                sqrtPriceLimitX96: 0
            });

            uint256 amountOut = routerV3.exactInputSingle(params);

            return amountOut;
        }
    }

    /*
     * @dev Swap ALPHA for ETH using Uniswap
     * @notice uses either Sushiswap or Uniswap V3 depending on version
     *
     * @param alphaAmount: amount of ALPHA to swap
     * @param minReturn: Min return to pass to Uniswap trade
     *
     * @return amount of ETH returned in the swap
     *
     * These swaps always use 'exact input' - they send exactly the amount specified
     * in arguments to the swap, and the output amount is calculated. The output ETH
     * is held in the contract.
     */
    function _swapALPHAForETHInternal(uint256 alphaAmount, uint256 minReturn) private returns (uint256) {
        uint256 deadline = MAX_UINT;

        if (swapMode == SwapMode.SUSHISWAP) {
            // SUSHISWAP
            IUniswapV2Router02 routerV2 = IUniswapV2Router02(sushiswapRouter);

            address[] memory path = new address[](2);
            path[0] = address(alphaToken);
            path[1] = address(weth);

            uint256[] memory amounts = routerV2.swapExactTokensForETH(
                alphaAmount,
                minReturn,
                path,
                address(this),
                deadline
            );

            return amounts[1];
        } else {
            // UNISWAP V3
            IUniswapV3SwapRouter routerV3 = IUniswapV3SwapRouter(uniswapRouter);

            IUniswapV3SwapRouter.ExactInputSingleParams memory params = IUniswapV3SwapRouter.ExactInputSingleParams({
                tokenIn: address(alphaToken),
                tokenOut: address(weth),
                fee: v3AlphaPoolFee,
                recipient: address(this),
                deadline: deadline,
                amountIn: alphaAmount,
                amountOutMinimum: minReturn,
                sqrtPriceLimitX96: 0
            });

            uint256 amountOut = routerV3.exactInputSingle(params);

            // Withdraw WETH
            weth.withdraw(amountOut);

            return amountOut;
        }
    }

    /* ========================================================================================= */
    /*                                            Management                                     */
    /* ========================================================================================= */

    /*
     * @dev Get NAV of the xALPHA contract
     * @notice Combination of staked balance held in staking contract
     *         and unstaked buffer balance held in xALPHA contract. Also
     *         includes stake currently being unbonded (as part of staked balance)
     *
     * @return Total NAV in ALPHA
     *
     */
    function getNav() public view override returns (uint256) {
        return totalStakedBalance.add(getBufferBalance());
    }

    /*
     * @dev Get buffer balance of the xALPHA contract
     *
     * @return Total unstaked ALPHA balance held by xALPHA, minus accrued fees
     */
    function getBufferBalance() public view override returns (uint256) {
        return alphaToken.balanceOf(address(this)).sub(withdrawableAlphaFees);
    }

    /*
     * @dev Get staked and buffer balance of the xALPHA contract, as separate values
     *
     * @return Staked and buffer balance as a tuple
     */
    function getFundBalances() public view override returns (uint256, uint256) {
        return (totalStakedBalance, getBufferBalance());
    }

    /**
     * @dev Get the withdrawable amount from a staking proxy

     * @param proxyIndex The proxy index

     * @return The withdrawable amount
     */
    function getWithdrawableAmount(uint256 proxyIndex) public view override returns (uint256) {
        require(proxyIndex < stakingFactory.getStakingProxyProxiesLength(), "Invalid index");
        return IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).getWithdrawableAmount();
    }

    /**
     * @dev Get the withdrawable fee amounts

     * @return feeAsset The fee asset
     * @return feeAmount The withdrawable amount
     */
    function getWithdrawableFees() public view returns (address feeAsset, uint256 feeAmount) {
        feeAsset = address(alphaToken);
        feeAmount = withdrawableAlphaFees;
    }

    /*
     * @dev Admin function to stake tokens from the buffer.
     *
     * @param proxyIndex: The proxy index to stake with
     * @param amount: allocation to staked balance
     * @param force: stake regardless of unbonding status
     */
    function stake(
        uint256 proxyIndex,
        uint256 amount,
        bool force
    ) public override onlyOwnerOrManager {
        _certifyAdmin();

        _stake(proxyIndex, amount, force);

        updateStakedBalance();
    }

    /*
     * @dev Updates the staked balance of the xALPHA contract.
     * @notice Includes any stake currently unbonding.
     *
     * @return Total staked balance in ALPHA staking contract
     */
    function updateStakedBalance() public override onlyOwnerOrManager {
        uint256 _totalStakedBalance;

        for (uint256 i = 0; i < stakingFactory.getStakingProxyProxiesLength(); i++) {
            _totalStakedBalance = _totalStakedBalance.add(
                IStakingProxy(stakingFactory.stakingProxyProxies(i)).getTotalStaked()
            );
        }

        // Update staked balance
        totalStakedBalance = _totalStakedBalance;

        emit UpdateStakedBalance(totalStakedBalance);
    }

    /*
     * @notice Admin-callable function in case of persistent depletion of buffer reserve
     * or emergency shutdown
     * @notice Incremental ALPHA will only be allocated to buffer reserve
     * @notice Starting a new unbonding period cancels the last one. Need to use 'force'
     * explicitly cancel a current unbonding.s
     */
    function unbond(uint256 proxyIndex, bool force) public override onlyOwnerOrManager {
        _certifyAdmin();
        _unbond(proxyIndex, force);
    }

    /*
     * @notice Admin-callable function to withdraw unbonded stake back into the buffer
     * @notice Incremental ALPHA will only be allocated to buffer reserve
     * @notice There is a 72-hour deadline to claim unbonded stake after the 30-day unbonding
     * period ends. This call will fail in the alpha staking contract if the 72-hour deadline
     * is expired.
     */
    function claimUnbonded(uint256 proxyIndex) public override onlyOwnerOrManager {
        _certifyAdmin();
        _claim(proxyIndex);

        updateStakedBalance();
    }

    /*
     * @notice Staking ALPHA cancels any currently open
     * unbonding. This will not stake unless the contract
     * is not unbonding, or the force param is sent
     * @param proxyIndex: the proxy index to stake with
     * @param amount: allocation to staked balance
     * @param force: stake regardless of unbonding status
     */
    function _stake(
        uint256 proxyIndex,
        uint256 amount,
        bool force
    ) private {
        require(amount > 0, "Cannot stake zero tokens");
        require(
            !IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).isUnbonding() || force,
            "Cannot stake during unbonding"
        );

        // Update the most recent stake timestamp
        lastStakeTimestamp = block.timestamp;

        alphaToken.safeTransfer(address(stakingFactory.stakingProxyProxies(proxyIndex)), amount);
        IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).stake(amount);

        emit Stake(proxyIndex, block.timestamp, amount);
    }

    /*
     * @notice Unbonding ALPHA cancels any currently open
     * unbonding. This will not unbond unless the contract
     * is not already unbonding, or the force param is sent
     * @param proxyIndex: the proxy index to unbond
     * @param force: unbond regardless of status
     */
    function _unbond(uint256 proxyIndex, bool force) internal {
        require(
            !IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).isUnbonding() || force,
            "Cannot unbond during unbonding"
        );

        IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).unbond();

        emit Unbond(
            proxyIndex,
            block.timestamp,
            IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).getUnbondingAmount()
        );
    }

    /*
     * @notice Claims any fully unbonded ALPHA. Must be called
     * within 72 hours after unbonding period expires, or
     * funds are re-staked.
     *
     * @param proxyIndex: the proxy index to claim rewards for
     */
    function _claim(uint256 proxyIndex) internal {
        require(IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).isUnbonding(), "Not unbonding");

        uint256 claimedAmount = IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).withdraw();

        emit Claim(proxyIndex, claimedAmount);
    }

    /*
     * @dev Get fee for a specific action
     *
     * @param _value: the value on which to assess the fee
     * @param _feeDivisor: the inverse of the percentage of the fee (i.e. 1% = 100)
     *
     * @return fee: total amount of fee to be assessed
     */
    function _calculateFee(uint256 _value, uint256 _feeDivisor) internal pure returns (uint256 fee) {
        if (_feeDivisor > 0) {
            fee = _value.div(_feeDivisor);
        }
    }

    /*
     * @dev Increase tracked amount of fees for management
     *
     * @param _feeAmount: the amount to increase management fees by
     */
    function _incrementWithdrawableAlphaFees(uint256 _feeAmount) private {
        withdrawableAlphaFees = withdrawableAlphaFees.add(_feeAmount);
    }

    /* ========================================================================================= */
    /*                                       Emergency Functions                                 */
    /* ========================================================================================= */

    /*
     * @dev Admin function for pausing contract operations. Pausing prevents mints.
     *
     */
    function pauseContract() public override onlyOwnerOrManager {
        _pause();
    }

    /*
     * @dev Admin function for unpausing contract operations.
     *
     */
    function unpauseContract() public override onlyOwnerOrManager {
        _unpause();
    }

    /*
     * @dev Public callable function for unstaking in event of admin failure/incapacitation.
     *
     * @notice Can only be called after a period of manager inactivity. Starts a 30-day unbonding
     * period. emergencyClaim must be called within 72 hours after the 30 day unbounding period expires.
     * Cancels any previous unbonding on the first call. Cannot be called again otherwise a caller
     * could indefinitely delay unbonding. Unbonds all staking proxy contracts.
     *
     * Once emergencyUnbondingTimestamp has been set, it is never reset unless an admin decides to.
     */
    function emergencyUnbond() external override {
        require(adminActiveTimestamp.add(LIQUIDATION_TIME_PERIOD) < block.timestamp, "Liquidation time not elapsed");

        uint256 thirtyThreeDaysAgo = block.timestamp - 33 days;
        require(emergencyUnbondTimestamp < thirtyThreeDaysAgo, "In unbonding period");

        emergencyUnbondTimestamp = block.timestamp;

        // Unstake everything
        for (uint256 i = 0; i < stakingFactory.getStakingProxyProxiesLength(); i++) {
            _unbond(i, true);
        }
    }

    /*
     * @dev Public callable function for claiming unbonded stake in the event of admin failure/incapacitation.
     *
     * @notice Can only be called after a period of manager inactivity. Can only be called
     * after a 30-day unbonding period, and must be called within 72 hours of unbound period expiry. Makes a claim
     * for all staking proxies
     */
    function emergencyClaim() external override {
        require(adminActiveTimestamp.add(LIQUIDATION_TIME_PERIOD) < block.timestamp, "Liquidation time not elapsed");
        require(emergencyUnbondTimestamp != 0, "Emergency unbond not called");

        emergencyUnbondTimestamp = 0;

        // Claim everything
        for (uint256 i = 0; i < stakingFactory.getStakingProxyProxiesLength(); i++) {
            _claim(i);
        }
    }

    /* ========================================================================================= */
    /*                                          Utils/Fallback                                   */
    /* ========================================================================================= */

    /*
     * @notice Inverse of fee i.e., a fee divisor of 100 == 1%
     * @notice Three fee types
     * @dev Mint fee 0 or <= 2%
     * @dev Burn fee 0 or <= 1%
     * @dev Claim fee 0 <= 4%
     */
    function setFeeDivisors(
        uint256 mintFeeDivisor,
        uint256 burnFeeDivisor,
        uint256 claimFeeDivisor
    ) public override onlyOwner {
        _setFeeDivisors(mintFeeDivisor, burnFeeDivisor, claimFeeDivisor);
    }

    /*
     * @dev Internal setter for the fee divisors, with enforced maximum fees.
     */
    function _setFeeDivisors(
        uint256 _mintFeeDivisor,
        uint256 _burnFeeDivisor,
        uint256 _claimFeeDivisor
    ) private {
        require(_mintFeeDivisor == 0 || _mintFeeDivisor >= 50, "Invalid fee");
        require(_burnFeeDivisor == 0 || _burnFeeDivisor >= 100, "Invalid fee");
        require(_claimFeeDivisor >= 25, "Invalid fee");
        feeDivisors.mintFee = _mintFeeDivisor;
        feeDivisors.burnFee = _burnFeeDivisor;
        feeDivisors.claimFee = _claimFeeDivisor;

        emit FeeDivisorsSet(_mintFeeDivisor, _burnFeeDivisor, _claimFeeDivisor);
    }

    /*
     * @dev Registers that admin is present and active
     * @notice If admin isn't certified within liquidation time period,
     *         emergencyUnstake function becomes callable
     */
    function _certifyAdmin() private {
        adminActiveTimestamp = block.timestamp;
    }

    /*
     * @dev Update the AMM to use for swaps.
     * @param version: the swap mode - 0 for sushiswap, 1 for Uniswap V3.
     *
     * Should be used when e.g. pricing is better on one version vs.
     * the other. Only valid values are 0 and 1. A new version of Uniswap
     * or integration with another liquidity protocol will require a full
     * contract upgrade.
     */
    function updateSwapRouter(SwapMode version) public override onlyOwnerOrManager {
        require(version == SwapMode.SUSHISWAP || version == SwapMode.UNISWAP_V3, "Invalid swap router version");

        swapMode = version;

        emit UpdateSwapRouter(version);
    }

    /*
     * @dev Update the fee tier for the ETH/ALPHA Uniswap V3 pool.
     * @param fee: the fee tier to use.
     *
     * Should be used when trades can be executed more efficiently at a certain
     * fee tier, based on the combination of fees and slippage.
     *
     * Fees are expressed in 1/100th of a basis point.
     * Only three fee tiers currently exist.
     * 500 - (0.05%)
     * 3000 - (0.3%)
     * 10000 - (1%)
     * Not enforcing these values because Uniswap's contracts
     * allow them to set arbitrary fee tiers in the future.
     * Take care when calling this function to make sure a pool
     * actually exists for a given fee, and it is the most liquid
     * pool for the ALPHA/ETH pair.
     */
    function updateUniswapV3AlphaPoolFee(uint24 fee) external override onlyOwnerOrManager {
        v3AlphaPoolFee = fee;

        emit UpdateUniswapV3AlphaPoolFee(v3AlphaPoolFee);
    }

    /*
     * @dev Emergency function in case of errant transfer of
     *         xALPHA token directly to contract.
     *
     * Errant xALPHA can only be sent back to management.
     */
    function withdrawNativeToken() public override onlyOwnerOrManager {
        uint256 tokenBal = balanceOf(address(this));
        require(tokenBal > 0, "No tokens to withdraw");
        IERC20(address(this)).safeTransfer(msg.sender, tokenBal);
    }

    /*
     * @dev Emergency function in case of errant transfer of
     *         ERC20 token directly to proxy contracts.
     *
     * Errant ERC20 token can only be sent back to management.
     */
    function withdrawTokenFromProxy(uint256 proxyIndex, address token) external override onlyOwnerOrManager {
        IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).withdrawToken(token);
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    /*
     * @dev Withdraw function for ALPHA fees.
     *
     * All fees are denominated in ALPHA, so this should cover all
     * fees earned via contract interactions. Fees can only be
     * sent to management.
     */
    function withdrawFees() public override {
        require(xTokenManager.isRevenueController(msg.sender), "Callable only by Revenue Controller");

        uint256 alphaFees = withdrawableAlphaFees;
        withdrawableAlphaFees = 0;
        alphaToken.safeTransfer(msg.sender, alphaFees);

        emit FeeWithdraw(alphaFees);
    }

    /**
     * @dev Exempts an address from blocklock
     * @param lockAddress The address to exempt
     */
    function exemptFromBlockLock(address lockAddress) external onlyOwnerOrManager {
        _exemptFromBlockLock(lockAddress);
    }

    /**
     * @dev Removes exemption for an address from blocklock
     * @param lockAddress The address to remove exemption
     */
    function removeBlockLockExemption(address lockAddress) external onlyOwnerOrManager {
        _removeBlockLockExemption(lockAddress);
    }

    /*
     * @dev Enforce functions only called by management.
     */
    modifier onlyOwnerOrManager() {
        require(msg.sender == owner() || xTokenManager.isManager(msg.sender, address(this)), "Non-admin caller");
        _;
    }

    /*
     * @dev Fallback function for received ETH.
     *
     * The contract may receive ETH as part of swaps, so only reject
     * if the ETH is sent directly.
     */
    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "Errant ETH deposit");
    }
}
