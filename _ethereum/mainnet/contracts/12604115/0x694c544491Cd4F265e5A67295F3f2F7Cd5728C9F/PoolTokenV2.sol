// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./Initializable.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./SignedSafeMath.sol";
import "./AggregatorV3Interface.sol";
import "./ILiquidityPoolV2.sol";
import "./IDetailedERC20.sol";
import "./IAddressRegistryV2.sol";
import "./MetaPoolToken.sol";

/**
 * @title APY.Finance Pool Token
 * @author APY.Finance
 * @notice This token (APT) is the basic liquidity-provider token used
 *         within the APY.Finance system.
 *
 *         For simplicity, it has been integrated with pool functionality
 *         enabling users to deposit and withdraw in an underlying token,
 *         currently one of three stablecoins.
 *
 *         Upon deposit of the underlyer, an appropriate amount of APT
 *         is minted.  This amount is calculated as a share of the pool's
 *         total value, which may change as strategies gain or lose.
 *
 *         The pool's total value is comprised of the value of its balance
 *         of the underlying stablecoin and also the value of its balance
 *         of mAPT, an internal token used by the system to track how much
 *         is owed to the pool.  Every time the PoolManager withdraws funds
 *         from the pool, mAPT is issued to the pool.
 *
 *         Upon redemption of APT (withdrawal), the user will get back
 *         in the underlying stablecoin, the amount equivalent in value
 *         to the user's APT share of the pool's total value.
 *
 *         Currently the user may not be able to redeem their full APT
 *         balance, as the majority of funds will be deployed at any
 *         given time.  Funds will periodically be pushed to the pools
 *         so that each pool maintains a reserve percentage of the
 *         pool's total value.
 *
 *         Later upgrades to the system will enable users to submit
 *         withdrawal requests, which will be processed periodically
 *         and unwind positions to free up funds.
 */
contract PoolTokenV2 is
    ILiquidityPoolV2,
    Initializable,
    OwnableUpgradeSafe,
    ReentrancyGuardUpgradeSafe,
    PausableUpgradeSafe,
    ERC20UpgradeSafe
{
    using Address for address;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeERC20 for IDetailedERC20;
    uint256 public constant DEFAULT_APT_TO_UNDERLYER_FACTOR = 1000;
    uint256 internal constant _MAX_INT256 = 2**255 - 1;

    event AdminChanged(address);

    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */

    // V1
    /// @notice used to protect init functions for upgrades
    address public proxyAdmin;
    /// @notice true if depositing is locked
    bool public addLiquidityLock;
    /// @notice true if withdrawing is locked
    bool public redeemLock;
    /// @notice underlying stablecoin
    IDetailedERC20 public underlyer;
    /// @notice USD price feed for the stablecoin
    // AggregatorV3Interface public priceAgg; <-- removed in V2

    // V2
    /// @notice registry to fetch core platform addresses from
    /// @dev this slot replaces the last V1 slot for the price agg
    IAddressRegistryV2 public addressRegistry;
    /// @notice seconds since last deposit during which withdrawal fee is charged
    uint256 public feePeriod;
    /// @notice percentage charged for withdrawal fee
    uint256 public feePercentage;
    /// @notice time of last deposit
    mapping(address => uint256) public lastDepositTime;
    /// @notice percentage of pool total value available for immediate withdrawal
    uint256 public reservePercentage;

    /* ------------------------------- */

    /**
     * @dev Since the proxy delegate calls to this "logic" contract, any
     * storage set by the logic contract's constructor during deploy is
     * disregarded and this function is needed to initialize the proxy
     * contract's storage according to this contract's layout.
     *
     * Since storage is not set yet, there is no simple way to protect
     * calling this function with owner modifiers.  Thus the OpenZeppelin
     * `initializer` modifier protects this function from being called
     * repeatedly.  It should be called during the deployment so that
     * it cannot be called by someone else later.
     *
     * NOTE: this function is copied from the V1 contract and has already
     * been called during V1 deployment.  It is included here for clarity.
     */
    function initialize(
        address adminAddress,
        IDetailedERC20 _underlyer,
        AggregatorV3Interface _priceAgg
    ) external initializer {
        require(adminAddress != address(0), "INVALID_ADMIN");
        require(address(_underlyer) != address(0), "INVALID_TOKEN");
        require(address(_priceAgg) != address(0), "INVALID_AGG");

        // initialize ancestor storage
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained("APY Pool Token", "APT");

        // initialize impl-specific storage
        setAdminAddress(adminAddress);
        addLiquidityLock = false;
        redeemLock = false;
        underlyer = _underlyer;
        // setPriceAggregator(_priceAgg);  <-- deprecated in V2.
    }

    /**
     * @dev Note the `initializer` modifier can only be used once in the
     * entire contract, so we can't use it here.  Instead, we protect
     * this function with `onlyAdmin`, which allows only the `proxyAdmin`
     * address to call this function.  Since that address is in fact
     * set to the actual proxy admin during deployment, this ensures
     * this function can only be called as part of a delegate call
     * during upgrades, i.e. in ProxyAdmin's `upgradeAndCall`.
     */
    function initializeUpgrade(address _addressRegistry)
        external
        virtual
        onlyAdmin
    {
        require(_addressRegistry.isContract(), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(_addressRegistry);
        feePeriod = 1 days;
        feePercentage = 5;
        reservePercentage = 5;
    }

    function setAdminAddress(address adminAddress) public onlyOwner {
        require(adminAddress != address(0), "INVALID_ADMIN");
        proxyAdmin = adminAddress;
        emit AdminChanged(adminAddress);
    }

    function setAddressRegistry(address payable _addressRegistry)
        public
        onlyOwner
    {
        require(Address.isContract(_addressRegistry), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(_addressRegistry);
    }

    function setFeePeriod(uint256 _feePeriod) public onlyOwner {
        feePeriod = _feePeriod;
    }

    function setFeePercentage(uint256 _feePercentage) public onlyOwner {
        feePercentage = _feePercentage;
    }

    function setReservePercentage(uint256 _reservePercentage) public onlyOwner {
        reservePercentage = _reservePercentage;
    }

    /**
     * @dev Throws if called by any account other than the proxy admin.
     */
    modifier onlyAdmin() {
        require(msg.sender == proxyAdmin, "ADMIN_ONLY");
        _;
    }

    /**
     * @notice Disable both depositing and withdrawals.
     *      Note that `addLiquidity` and `redeem` also have individual locks.
     */
    function lock() external onlyOwner {
        _pause();
    }

    /**
     * @notice Re-enable both depositing and withdrawals.
     *      Note that `addLiquidity` and `redeem` also have individual locks.
     */
    function unlock() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Mint corresponding amount of APT tokens for deposited stablecoin.
     * @dev If no APT tokens have been minted yet, fallback to a fixed ratio.
     * @param depositAmount Amount to deposit of the underlying stablecoin
     */
    function addLiquidity(uint256 depositAmount)
        external
        virtual
        override
        nonReentrant
        whenNotPaused
    {
        require(!addLiquidityLock, "LOCKED");
        require(depositAmount > 0, "AMOUNT_INSUFFICIENT");
        require(
            underlyer.allowance(msg.sender, address(this)) >= depositAmount,
            "ALLOWANCE_INSUFFICIENT"
        );
        // solhint-disable-next-line not-rely-on-time
        lastDepositTime[msg.sender] = block.timestamp;

        // calculateMintAmount() is not used because deposit value
        // is needed for the event
        uint256 depositValue = getValueFromUnderlyerAmount(depositAmount);
        uint256 poolTotalValue = getPoolTotalValue();
        uint256 mintAmount = _calculateMintAmount(depositValue, poolTotalValue);

        _mint(msg.sender, mintAmount);
        underlyer.safeTransferFrom(msg.sender, address(this), depositAmount);

        emit DepositedAPT(
            msg.sender,
            underlyer,
            depositAmount,
            mintAmount,
            depositValue,
            getPoolTotalValue()
        );
    }

    /** @notice Disable deposits. */
    function lockAddLiquidity() external onlyOwner {
        addLiquidityLock = true;
        emit AddLiquidityLocked();
    }

    /** @notice Enable deposits. */
    function unlockAddLiquidity() external onlyOwner {
        addLiquidityLock = false;
        emit AddLiquidityUnlocked();
    }

    /**
     * @notice Redeems APT amount for its underlying stablecoin amount.
     * @dev May revert if there is not enough in the pool.
     * @param aptAmount The amount of APT tokens to redeem
     */
    function redeem(uint256 aptAmount)
        external
        virtual
        override
        nonReentrant
        whenNotPaused
    {
        require(!redeemLock, "LOCKED");
        require(aptAmount > 0, "AMOUNT_INSUFFICIENT");
        require(aptAmount <= balanceOf(msg.sender), "BALANCE_INSUFFICIENT");

        uint256 redeemUnderlyerAmt = getUnderlyerAmountWithFee(aptAmount);
        require(
            redeemUnderlyerAmt <= underlyer.balanceOf(address(this)),
            "RESERVE_INSUFFICIENT"
        );

        _burn(msg.sender, aptAmount);
        underlyer.safeTransfer(msg.sender, redeemUnderlyerAmt);

        emit RedeemedAPT(
            msg.sender,
            underlyer,
            redeemUnderlyerAmt,
            aptAmount,
            getValueFromUnderlyerAmount(redeemUnderlyerAmt),
            getPoolTotalValue()
        );
    }

    /** @notice Disable APT redeeming. */
    function lockRedeem() external onlyOwner {
        redeemLock = true;
        emit RedeemLocked();
    }

    /** @notice Enable APT redeeming. */
    function unlockRedeem() external onlyOwner {
        redeemLock = false;
        emit RedeemUnlocked();
    }

    /**
     * @notice Calculate APT amount to be minted from deposit amount.
     * @param depositAmount The deposit amount of stablecoin
     * @return The mint amount
     */
    function calculateMintAmount(uint256 depositAmount)
        public
        view
        returns (uint256)
    {
        uint256 depositValue = getValueFromUnderlyerAmount(depositAmount);
        uint256 poolTotalValue = getPoolTotalValue();
        return _calculateMintAmount(depositValue, poolTotalValue);
    }

    /**
     *  @dev amount of APT minted should be in same ratio to APT supply
     *       as deposit value is to pool's total value, i.e.:
     *
     *       mint amount / total supply
     *       = deposit value / pool total value
     *
     *       For denominators, pre or post-deposit amounts can be used.
     *       The important thing is they are consistent, i.e. both pre-deposit
     *       or both post-deposit.
     */
    function _calculateMintAmount(uint256 depositValue, uint256 poolTotalValue)
        internal
        view
        returns (uint256)
    {
        uint256 totalSupply = totalSupply();

        if (poolTotalValue == 0 || totalSupply == 0) {
            return depositValue.mul(DEFAULT_APT_TO_UNDERLYER_FACTOR);
        }

        return (depositValue.mul(totalSupply)).div(poolTotalValue);
    }

    /**
     * @notice Get the underlying amount represented by APT amount,
     *         deducting early withdraw fee, if applicable.
     * @dev To check if fee will be applied, use `isEarlyRedeem`.
     * @param aptAmount The amount of APT tokens
     * @return uint256 The underlyer value of the APT tokens
     */
    function getUnderlyerAmountWithFee(uint256 aptAmount)
        public
        view
        returns (uint256)
    {
        uint256 redeemUnderlyerAmt = getUnderlyerAmount(aptAmount);
        if (isEarlyRedeem()) {
            uint256 fee = redeemUnderlyerAmt.mul(feePercentage).div(100);
            redeemUnderlyerAmt = redeemUnderlyerAmt.sub(fee);
        }
        return redeemUnderlyerAmt;
    }

    /**
     * @notice Get the underlying amount represented by APT amount.
     * @param aptAmount The amount of APT tokens
     * @return uint256 The underlying value of the APT tokens
     */
    function getUnderlyerAmount(uint256 aptAmount)
        public
        view
        returns (uint256)
    {
        if (aptAmount == 0) {
            return 0;
        }
        require(totalSupply() > 0, "INSUFFICIENT_TOTAL_SUPPLY");
        // the below is mathematically equivalent to:
        //
        // getUnderlyerAmountFromValue(getAPTValue(aptAmount));
        //
        // but composing the two functions leads to early loss
        // of precision from division, so it's better to do it
        // this way:
        uint256 underlyerPrice = getUnderlyerPrice();
        uint256 decimals = underlyer.decimals();
        return
            aptAmount
                .mul(getPoolTotalValue())
                .mul(10**decimals)
                .div(totalSupply())
                .div(underlyerPrice);
    }

    /**
     * @notice Checks if caller will be charged early withdrawal fee.
     * @dev `lastDepositTime` is stored each time user makes a deposit, so
     *      the waiting period is restarted on each deposit.
     * @return "true" when fee will apply, "false" when it won't.
     */
    function isEarlyRedeem() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp.sub(lastDepositTime[msg.sender]) < feePeriod;
    }

    /**
     * @notice Get the total USD-denominated value (in bits) of the pool's assets,
     *         including not only its underlyer balance, but any part of deployed
     *         capital that is owed to it.
     * @return USD value
     */
    function getPoolTotalValue() public view virtual returns (uint256) {
        uint256 underlyerValue = getPoolUnderlyerValue();
        uint256 mAptValue = getDeployedValue();
        return underlyerValue.add(mAptValue);
    }

    /**
     * @notice Get the USD-denominated value (in bits) of the pool's
     *         underlyer balance.
     * @return USD value
     */
    function getPoolUnderlyerValue() public view virtual returns (uint256) {
        return getValueFromUnderlyerAmount(underlyer.balanceOf(address(this)));
    }

    /**
     * @notice Get the USD-denominated value (in bits) of the pool's share
     *         of the deployed capital, as tracked by the mAPT token.
     * @return USD value
     */
    function getDeployedValue() public view virtual returns (uint256) {
        MetaPoolToken mApt = MetaPoolToken(addressRegistry.mAptAddress());
        return mApt.getDeployedValue(address(this));
    }

    /**
     * @notice Get the USD-denominated value (in bits) represented by APT amount.
     * @param aptAmount APT amount
     * @return USD value
     */
    function getAPTValue(uint256 aptAmount) public view returns (uint256) {
        require(totalSupply() > 0, "INSUFFICIENT_TOTAL_SUPPLY");
        return aptAmount.mul(getPoolTotalValue()).div(totalSupply());
    }

    /**
     * @notice Get the USD-denominated value (in bits) represented by stablecoin amount.
     * @param underlyerAmount amount of underlying stablecoin
     * @return USD value
     */
    function getValueFromUnderlyerAmount(uint256 underlyerAmount)
        public
        view
        returns (uint256)
    {
        if (underlyerAmount == 0) {
            return 0;
        }
        uint256 decimals = underlyer.decimals();
        return getUnderlyerPrice().mul(underlyerAmount).div(10**decimals);
    }

    /**
     * @notice Get the underlyer amount equivalent to given USD-denominated value (in bits).
     * @param value USD value
     * @return amount of underlying stablecoin
     */
    function getUnderlyerAmountFromValue(uint256 value)
        public
        view
        returns (uint256)
    {
        uint256 underlyerPrice = getUnderlyerPrice();
        uint256 decimals = underlyer.decimals();
        return (10**decimals).mul(value).div(underlyerPrice);
    }

    /**
     * @notice Get the underlyer stablecoin's USD price (in bits).
     * @return USD price
     */
    function getUnderlyerPrice() public view returns (uint256) {
        IOracleAdapter oracleAdapter =
            IOracleAdapter(addressRegistry.oracleAdapterAddress());
        return oracleAdapter.getAssetPrice(address(underlyer));
    }

    /**
     * @notice Get the USD value needed to meet the reserve percentage
     *         of the pool's deployed value.
     *
     *         This "top-up" value should satisfy:
     *
     *         top-up USD value + pool underlyer USD value
     *            = (reserve %) * pool deployed value (after unwinding)
     *
     * @dev Taking the percentage of the pool's current deployed value
     *      is not sufficient, because the requirement is to have the
     *      resulting values after unwinding capital satisfy the
     *      above equation.
     *
     *      More precisely:
     *
     *      R_pre = pool underlyer USD value before pushing unwound
     *              capital to the pool
     *      R_post = pool underlyer USD value after pushing
     *      DV_pre = pool's deployed USD value before unwinding
     *      DV_post = pool's deployed USD value after unwinding
     *      rPerc = the reserve percentage as a whole number
     *                          out of 100
     *
     *      We want:
     *
     *          R_post = (rPerc / 100) * DV_post          (equation 1)
     *
     *          where R_post = R_pre + top-up value
     *                DV_post = DV_pre - top-up value
     *
     *      Making the latter substitutions in equation 1, gives:
     *
     *      top-up value = (rPerc * DV_pre - 100 * R_pre) / (100 + rPerc)
     *
     * @return int256 The underlyer value to top-up the pool's reserve
     */
    function getReserveTopUpValue() public view returns (int256) {
        uint256 unnormalizedTargetValue =
            getDeployedValue().mul(reservePercentage);
        uint256 unnormalizedUnderlyerValue = getPoolUnderlyerValue().mul(100);

        require(unnormalizedTargetValue <= _MAX_INT256, "SIGNED_INT_OVERFLOW");
        require(
            unnormalizedUnderlyerValue <= _MAX_INT256,
            "SIGNED_INT_OVERFLOW"
        );
        int256 topUpValue =
            int256(unnormalizedTargetValue)
                .sub(int256(unnormalizedUnderlyerValue))
                .div(int256(reservePercentage).add(100));
        return topUpValue;
    }

    /**
     * @notice Allow `delegate` to withdraw any amount from the pool.
     * @dev Will fail if called twice, due to usage of `safeApprove`.
     * @param delegate Address to give infinite allowance to
     */
    function infiniteApprove(address delegate)
        external
        nonReentrant
        whenNotPaused
        onlyOwner
    {
        underlyer.safeApprove(delegate, type(uint256).max);
    }

    /**
     * @notice Revoke given allowance from `delegate`.
     * @dev Can be called even when the pool is locked.
     * @param delegate Address to remove allowance from
     */
    function revokeApprove(address delegate) external nonReentrant onlyOwner {
        underlyer.safeApprove(delegate, 0);
    }

    /**
     * @dev This hook is in-place to block inter-user APT transfers, as it
     *      is one avenue that can be used by arbitrageurs to drain the
     *      reserves.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        // allow minting and burning
        if (from == address(0) || to == address(0)) return;
        // block transfer between users
        revert("INVALID_TRANSFER");
    }
}
