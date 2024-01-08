// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./Imports.sol";
import "./Imports.sol";
import "./Imports.sol";
import "./Imports.sol";
import "./Imports.sol";
import "./MetaPoolToken.sol";

import "./Imports.sol";

/**
 * @notice Collect user deposits so they can be lent to the LP Account
 * @notice Depositors share pool liquidity
 * @notice Reserves are maintained to process withdrawals
 * @notice Reserve tokens cannot be lent to the LP Account
 * @notice If a user withdraws too early after their deposit, there's a fee
 * @notice Tokens borrowed from the pool are tracked with the `MetaPoolToken`
 */
contract PoolTokenV2 is
    ILiquidityPoolV2,
    IPoolToken,
    IReservePool,
    IWithdrawFeePool,
    ILockingPool,
    Initializable,
    AccessControlUpgradeSafe,
    ReentrancyGuardUpgradeSafe,
    PausableUpgradeSafe,
    ERC20UpgradeSafe
{
    using AddressUpgradeSafe for address;
    using SafeMathUpgradeSafe for uint256;
    using SignedSafeMathUpgradeSafe for int256;
    using SafeERC20 for IDetailedERC20;

    uint256 public constant DEFAULT_APT_TO_UNDERLYER_FACTOR = 1000;
    uint256 internal constant _MAX_INT256 = 2**255 - 1;

    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */

    // V1
    /** @notice used to protect init functions for upgrades */
    address public proxyAdmin;
    /** @notice true if depositing is locked */
    bool public addLiquidityLock;
    /** @notice true if withdrawing is locked */
    bool public redeemLock;
    /** @notice underlying stablecoin */
    IDetailedERC20 public override underlyer;
    /** @notice USD price feed for the stablecoin */
    // AggregatorV3Interface public priceAgg; <-- removed in V2

    // V2
    /**
     * @notice registry to fetch core platform addresses from
     * @dev this slot replaces the last V1 slot for the price agg
     */
    IAddressRegistryV2 public addressRegistry;
    /** @notice seconds since last deposit during which withdrawal fee is charged */
    uint256 public override feePeriod;
    /** @notice percentage charged for withdrawal fee */
    uint256 public override feePercentage;
    /** @notice time of last deposit */
    mapping(address => uint256) public lastDepositTime;
    /** @notice percentage of pool total value available for immediate withdrawal */
    uint256 public override reservePercentage;

    /* ------------------------------- */

    /** @notice Log when the proxy admin is changed */
    event AdminChanged(address);

    /** @notice Log when the address registry is changed */
    event AddressRegistryChanged(address);

    /**
     * @dev Throw if called by any account other than the proxy admin.
     */
    modifier onlyAdmin() {
        require(msg.sender == proxyAdmin, "ADMIN_ONLY");
        _;
    }

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
        IDetailedERC20 underlyer_,
        AggregatorV3Interface priceAgg
    ) external initializer {
        require(adminAddress != address(0), "INVALID_ADMIN");
        require(address(underlyer_) != address(0), "INVALID_TOKEN");
        require(address(priceAgg) != address(0), "INVALID_AGG");

        // initialize ancestor storage
        __Context_init_unchained();
        // __Ownable_init_unchained();  <-- Comment-out for compiler; replaced by AccessControl
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained("APY Pool Token", "APT");

        // initialize impl-specific storage
        _setAdminAddress(adminAddress);
        addLiquidityLock = false;
        redeemLock = false;
        underlyer = underlyer_;
        // setPriceAggregator(priceAgg);  <-- deprecated in V2.
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
    function initializeUpgrade(address addressRegistry_) external onlyAdmin {
        _setAddressRegistry(addressRegistry_);

        // Sadly, the AccessControl init is protected by `initializer` so can't
        // be called ever again (see above natspec).  Fortunately, the init body
        // is empty, so we don't actually need to call it.
        // __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(ADMIN_ROLE, addressRegistry.adminSafeAddress());
        _setupRole(EMERGENCY_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(CONTRACT_ROLE, addressRegistry.mAptAddress());

        feePeriod = 1 days;
        feePercentage = 5;
        reservePercentage = 5;
    }

    function emergencyLock() external override onlyEmergencyRole {
        _pause();
    }

    function emergencyUnlock() external override onlyEmergencyRole {
        _unpause();
    }

    /**
     * @dev If no APT tokens have been minted yet, fallback to a fixed ratio.
     */
    function addLiquidity(uint256 depositAmount)
        external
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

    function emergencyLockAddLiquidity() external override onlyEmergencyRole {
        addLiquidityLock = true;
        emit AddLiquidityLocked();
    }

    function emergencyUnlockAddLiquidity() external override onlyEmergencyRole {
        addLiquidityLock = false;
        emit AddLiquidityUnlocked();
    }

    /**
     * @dev May revert if there is not enough in the pool.
     */
    function redeem(uint256 aptAmount)
        external
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

    function emergencyLockRedeem() external override onlyEmergencyRole {
        redeemLock = true;
        emit RedeemLocked();
    }

    function emergencyUnlockRedeem() external override onlyEmergencyRole {
        redeemLock = false;
        emit RedeemUnlocked();
    }

    /**
     * @dev permissioned with CONTRACT_ROLE
     */
    function transferToLpAccount(uint256 amount)
        external
        override
        nonReentrant
        whenNotPaused
        onlyContractRole
    {
        underlyer.safeTransfer(addressRegistry.lpAccountAddress(), amount);
    }

    /**
     * @notice Set the new proxy admin
     * @param adminAddress The new proxy admin
     */
    function emergencySetAdminAddress(address adminAddress)
        external
        onlyEmergencyRole
    {
        _setAdminAddress(adminAddress);
    }

    /**
     * @notice Set the new address registry
     * @param addressRegistry_ The new address registry
     */
    function emergencySetAddressRegistry(address addressRegistry_)
        external
        onlyEmergencyRole
    {
        _setAddressRegistry(addressRegistry_);
    }

    function setFeePeriod(uint256 feePeriod_) external override onlyAdminRole {
        feePeriod = feePeriod_;
        emit FeePeriodChanged(feePeriod_);
    }

    function setFeePercentage(uint256 feePercentage_)
        external
        override
        onlyAdminRole
    {
        feePercentage = feePercentage_;
        emit FeePercentageChanged(feePercentage_);
    }

    function setReservePercentage(uint256 reservePercentage_)
        external
        override
        onlyAdminRole
    {
        reservePercentage = reservePercentage_;
        emit ReservePercentageChanged(reservePercentage_);
    }

    function calculateMintAmount(uint256 depositAmount)
        external
        view
        override
        returns (uint256)
    {
        uint256 depositValue = getValueFromUnderlyerAmount(depositAmount);
        uint256 poolTotalValue = getPoolTotalValue();
        return _calculateMintAmount(depositValue, poolTotalValue);
    }

    /**
     * @dev To check if fee will be applied, use `isEarlyRedeem`.
     */
    function getUnderlyerAmountWithFee(uint256 aptAmount)
        public
        view
        override
        returns (uint256)
    {
        uint256 redeemUnderlyerAmt = getUnderlyerAmount(aptAmount);
        if (isEarlyRedeem()) {
            uint256 fee = redeemUnderlyerAmt.mul(feePercentage).div(100);
            redeemUnderlyerAmt = redeemUnderlyerAmt.sub(fee);
        }
        return redeemUnderlyerAmt;
    }

    function getUnderlyerAmount(uint256 aptAmount)
        public
        view
        override
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
     * @dev `lastDepositTime` is stored each time user makes a deposit, so
     * the waiting period is restarted on each deposit.
     */
    function isEarlyRedeem() public view override returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp.sub(lastDepositTime[msg.sender]) < feePeriod;
    }

    /**
     * @dev Total value also includes that have been borrowed from the pool
     * @dev Typically it is the LP Account that borrows from the pool
     */
    function getPoolTotalValue() public view override returns (uint256) {
        uint256 underlyerValue = _getPoolUnderlyerValue();
        uint256 mAptValue = _getDeployedValue();
        return underlyerValue.add(mAptValue);
    }

    function getAPTValue(uint256 aptAmount)
        external
        view
        override
        returns (uint256)
    {
        require(totalSupply() > 0, "INSUFFICIENT_TOTAL_SUPPLY");
        return aptAmount.mul(getPoolTotalValue()).div(totalSupply());
    }

    function getValueFromUnderlyerAmount(uint256 underlyerAmount)
        public
        view
        override
        returns (uint256)
    {
        if (underlyerAmount == 0) {
            return 0;
        }
        uint256 decimals = underlyer.decimals();
        return getUnderlyerPrice().mul(underlyerAmount).div(10**decimals);
    }

    function getUnderlyerPrice() public view override returns (uint256) {
        IOracleAdapter oracleAdapter =
            IOracleAdapter(addressRegistry.oracleAdapterAddress());
        return oracleAdapter.getAssetPrice(address(underlyer));
    }

    /**
     * @dev This "top-up" value should satisfy:
     *
     * top-up USD value + pool underlyer USD value
     * = (reserve %) * pool deployed value (after unwinding)
     *
     * @dev Taking the percentage of the pool's current deployed value
     * is not sufficient, because the requirement is to have the
     * resulting values after unwinding capital satisfy the
     * above equation.
     *
     * More precisely:
     *
     * R_pre = pool underlyer USD value before pushing unwound
     *         capital to the pool
     * R_post = pool underlyer USD value after pushing
     * DV_pre = pool's deployed USD value before unwinding
     * DV_post = pool's deployed USD value after unwinding
     * rPerc = the reserve percentage as a whole number
     *                     out of 100
     *
     * We want:
     *
     *     R_post = (rPerc / 100) * DV_post          (equation 1)
     *
     *     where R_post = R_pre + top-up value
     *           DV_post = DV_pre - top-up value
     *
     * Making the latter substitutions in equation 1, gives:
     *
     * top-up value = (rPerc * DV_pre - 100 * R_pre) / (100 + rPerc)
     */
    function getReserveTopUpValue() external view override returns (int256) {
        uint256 unnormalizedTargetValue =
            _getDeployedValue().mul(reservePercentage);
        uint256 unnormalizedUnderlyerValue = _getPoolUnderlyerValue().mul(100);

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

    function _setAdminAddress(address adminAddress) internal {
        require(adminAddress != address(0), "INVALID_ADMIN");
        proxyAdmin = adminAddress;
        emit AdminChanged(adminAddress);
    }

    function _setAddressRegistry(address addressRegistry_) internal {
        require(addressRegistry_.isContract(), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(addressRegistry_);
        emit AddressRegistryChanged(addressRegistry_);
    }

    /**
     * @dev This hook is in-place to block inter-user APT transfers, as it
     * is one avenue that can be used by arbitrageurs to drain the
     * reserves.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
        // allow minting and burning
        if (from == address(0) || to == address(0)) return;
        // block transfer between users
        revert("INVALID_TRANSFER");
    }

    /**
     * @dev amount of APT minted should be in same ratio to APT supply
     * as deposit value is to pool's total value, i.e.:
     *
     * mint amount / total supply
     * = deposit value / pool total value
     *
     * For denominators, pre or post-deposit amounts can be used.
     * The important thing is they are consistent, i.e. both pre-deposit
     * or both post-deposit.
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
     * @notice Get the USD value of tokens in the pool
     * @return The USD value
     */
    function _getPoolUnderlyerValue() internal view returns (uint256) {
        return getValueFromUnderlyerAmount(underlyer.balanceOf(address(this)));
    }

    /**
     * @notice Get the USD value of tokens owed to the pool
     * @dev Tokens from the pool are typically borrowed by the LP Account
     * @dev Tokens borrowed from the pool are tracked with mAPT
     * @return The USD value
     */
    function _getDeployedValue() internal view returns (uint256) {
        MetaPoolToken mApt = MetaPoolToken(addressRegistry.mAptAddress());
        return mApt.getDeployedValue(address(this));
    }
}
