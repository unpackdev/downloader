// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import "./Imports.sol";

import "./Imports.sol";

import "./Imports.sol";

import "./Imports.sol";

/**
 * @title Oracle Adapter
 * @author APY.Finance
 * @notice Acts as a gateway to oracle values and implements oracle safeguards.
 *
 * Oracle Safeguard Flows:
 *
 *      - Unlocked → No Manual Submitted Value → Use Chainlink Value (default)
 *      - Unlocked → No Manual Submitted Value → Chainlink Value == 0 → mAPT totalSupply == 0 → Use 0
 *      - Unlocked → No Manual Submitted Value → Chainlink Value == 0 → mAPT totalSupply > 0 → Reverts
 *      - Unlocked → No Manual Submitted Value → No Chainlink Source → Reverts
 *      - Unlocked → No Manual Submitted Value → Chainlink Value Call Reverts → Reverts
 *      - Unlocked → No Manual Submitted Value → Chainlink Value > 24 hours → Reverts
 *      - Unlocked → Use Manual Submitted Value (emergency)
 *      - Locked → Reverts (nominal)
 *
 * @dev It is important to note that zero values are allowed for manual
 * submission but may result in a revert when pulling from Chainlink.
 *
 * This is because there are uncommon situations where the zero TVL is valid,
 * such as when all funds are unwound and moved back to the liquidity
 * pools, but total mAPT supply would be zero in those cases.  Outside those
 * situations, a zero TVL with nonzero supply likely indicates a Chainlink
 * failure, hence we revert out of an abundance of caution.
 *
 * In the rare situation where Chainlink *should* be returning zero TVL
 * with nonzero mAPT supply, we can set the zero TVL manually via the
 * Emergency Safe.  Such a situation is not expected to persist long.
 */
contract OracleAdapter is
    AccessControl,
    IOracleAdapter,
    IOverrideOracle,
    ILockingOracle
{
    using SafeMath for uint256;
    using Address for address;

    IAddressRegistryV2 public addressRegistry;

    uint256 public override defaultLockPeriod;

    /// @notice Contract is locked until this block number is passed.
    uint256 public lockEnd;

    /// @notice Chainlink heartbeat duration in seconds
    uint256 public chainlinkStalePeriod;

    AggregatorV3Interface public tvlSource;
    mapping(address => AggregatorV3Interface) public assetSources;

    /// @notice Submitted values that override Chainlink values until stale.
    mapping(address => Value) public submittedAssetValues;
    Value public submittedTvlValue;

    event AddressRegistryChanged(address);

    modifier unlocked() {
        require(!isLocked(), "ORACLE_LOCKED");
        _;
    }

    /**
     * @param addressRegistry_ The address registry
     * @param tvlSource_ The source for the TVL value
     * @param assets The assets priced by sources
     * @param sources The source for each asset
     * @param chainlinkStalePeriod_ The number of seconds until a source value is stale
     * @param defaultLockPeriod_ The default number of blocks a lock should last
     */
    constructor(
        address addressRegistry_,
        address tvlSource_,
        address[] memory assets,
        address[] memory sources,
        uint256 chainlinkStalePeriod_,
        uint256 defaultLockPeriod_
    ) public {
        _setAddressRegistry(addressRegistry_);
        _setTvlSource(tvlSource_);
        _setAssetSources(assets, sources);
        _setChainlinkStalePeriod(chainlinkStalePeriod_);
        _setDefaultLockPeriod(defaultLockPeriod_);

        _setupRole(DEFAULT_ADMIN_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(CONTRACT_ROLE, addressRegistry.mAptAddress());
        _setupRole(CONTRACT_ROLE, addressRegistry.tvlManagerAddress());
        _setupRole(ADMIN_ROLE, addressRegistry.adminSafeAddress());
        _setupRole(EMERGENCY_ROLE, addressRegistry.emergencySafeAddress());
    }

    function setDefaultLockPeriod(uint256 newPeriod)
        external
        override
        onlyAdminRole
    {
        _setDefaultLockPeriod(newPeriod);
        emit DefaultLockPeriodChanged(newPeriod);
    }

    function lock() external override onlyContractRole {
        _lockFor(defaultLockPeriod);
        emit DefaultLocked(msg.sender, defaultLockPeriod, lockEnd);
    }

    function emergencyUnlock() external override onlyEmergencyRole {
        _lockFor(0);
        emit Unlocked();
    }

    /**
     * @dev Can only increase the remaining locking duration.
     * @dev If no lock exists, this allows setting of any defined locking period
     */
    function lockFor(uint256 activePeriod) external override onlyContractRole {
        uint256 oldLockEnd = lockEnd;
        _lockFor(activePeriod);
        require(lockEnd > oldLockEnd, "CANNOT_SHORTEN_LOCK");
        emit Locked(msg.sender, activePeriod, lockEnd);
    }

    /**
     * @notice Sets the address registry
     * @param addressRegistry_ the address of the registry
     */
    function emergencySetAddressRegistry(address addressRegistry_)
        external
        onlyEmergencyRole
    {
        _setAddressRegistry(addressRegistry_);
    }

    //------------------------------------------------------------
    // MANUAL SUBMISSION SETTERS
    //------------------------------------------------------------

    function emergencySetAssetValue(
        address asset,
        uint256 value,
        uint256 period
    ) external override onlyEmergencyRole {
        // We do allow 0 values for submitted values
        uint256 periodEnd = block.number.add(period);
        submittedAssetValues[asset] = Value(value, periodEnd);
        emit AssetValueSet(asset, value, period, periodEnd);
    }

    function emergencyUnsetAssetValue(address asset)
        external
        override
        onlyEmergencyRole
    {
        require(
            submittedAssetValues[asset].periodEnd != 0,
            "NO_ASSET_VALUE_SET"
        );
        submittedAssetValues[asset].periodEnd = block.number;
        emit AssetValueUnset(asset);
    }

    function emergencySetTvl(uint256 value, uint256 period)
        external
        override
        onlyEmergencyRole
    {
        // We do allow 0 values for submitted values
        uint256 periodEnd = block.number.add(period);
        submittedTvlValue = Value(value, periodEnd);
        emit TvlSet(value, period, periodEnd);
    }

    function emergencyUnsetTvl() external override onlyEmergencyRole {
        require(submittedTvlValue.periodEnd != 0, "NO_TVL_SET");
        submittedTvlValue.periodEnd = block.number;
        emit TvlUnset();
    }

    //------------------------------------------------------------
    // CHAINLINK SETTERS
    //------------------------------------------------------------

    function emergencySetTvlSource(address source)
        external
        override
        onlyEmergencyRole
    {
        _setTvlSource(source);
    }

    function emergencySetAssetSources(
        address[] memory assets,
        address[] memory sources
    ) external override onlyEmergencyRole {
        _setAssetSources(assets, sources);
    }

    function emergencySetAssetSource(address asset, address source)
        external
        override
        onlyEmergencyRole
    {
        _setAssetSource(asset, source);
    }

    function setChainlinkStalePeriod(uint256 chainlinkStalePeriod_)
        external
        override
        onlyAdminRole
    {
        _setChainlinkStalePeriod(chainlinkStalePeriod_);
    }

    //------------------------------------------------------------
    // ORACLE VALUE GETTERS
    //------------------------------------------------------------

    /**
     * @dev Zero values are considered valid if there is no mAPT minted,
     * and therefore no PoolTokenV2 liquidity in the LP Safe.
     */
    function getTvl() external view override unlocked returns (uint256) {
        if (hasTvlOverride()) {
            return submittedTvlValue.value;
        }

        uint256 price = _getPriceFromSource(tvlSource);

        require(
            price > 0 ||
                IERC20(addressRegistry.mAptAddress()).totalSupply() == 0,
            "INVALID_ZERO_TVL"
        );

        return price;
    }

    function hasTvlOverride() public view override returns (bool) {
        return block.number < submittedTvlValue.periodEnd;
    }

    function getAssetPrice(address asset)
        external
        view
        override
        unlocked
        returns (uint256)
    {
        if (hasAssetOverride(asset)) {
            return submittedAssetValues[asset].value;
        }

        AggregatorV3Interface source = assetSources[asset];
        uint256 price = _getPriceFromSource(source);

        //we do not allow 0 values for chainlink
        require(price > 0, "MISSING_ASSET_VALUE");

        return price;
    }

    function hasAssetOverride(address asset)
        public
        view
        override
        returns (bool)
    {
        return block.number < submittedAssetValues[asset].periodEnd;
    }

    function isLocked() public view override returns (bool) {
        return block.number < lockEnd;
    }

    function _setDefaultLockPeriod(uint256 newPeriod) internal {
        defaultLockPeriod = newPeriod;
    }

    function _lockFor(uint256 activePeriod) internal {
        lockEnd = block.number.add(activePeriod);
    }

    function _setAddressRegistry(address addressRegistry_) internal {
        require(Address.isContract(addressRegistry_), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(addressRegistry_);
        emit AddressRegistryChanged(addressRegistry_);
    }

    function _setChainlinkStalePeriod(uint256 chainlinkStalePeriod_) internal {
        require(chainlinkStalePeriod_ > 0, "INVALID_STALE_PERIOD");
        chainlinkStalePeriod = chainlinkStalePeriod_;
        emit ChainlinkStalePeriodUpdated(chainlinkStalePeriod_);
    }

    function _setTvlSource(address source) internal {
        require(source.isContract(), "INVALID_SOURCE");
        tvlSource = AggregatorV3Interface(source);
        emit TvlSourceUpdated(source);
    }

    function _setAssetSources(address[] memory assets, address[] memory sources)
        internal
    {
        require(assets.length == sources.length, "INCONSISTENT_PARAMS_LENGTH");
        for (uint256 i = 0; i < assets.length; i++) {
            _setAssetSource(assets[i], sources[i]);
        }
    }

    function _setAssetSource(address asset, address source) internal {
        require(source.isContract(), "INVALID_SOURCE");
        assetSources[asset] = AggregatorV3Interface(source);
        emit AssetSourceUpdated(asset, source);
    }

    /**
     * @notice Get the price from a source (aggregator)
     * @param source The Chainlink aggregator
     * @return the price from the source
     */
    function _getPriceFromSource(AggregatorV3Interface source)
        internal
        view
        returns (uint256)
    {
        require(address(source).isContract(), "INVALID_SOURCE");
        (, int256 price, , uint256 updatedAt, ) = source.latestRoundData();

        // must be negative for cast to uint
        require(price >= 0, "NEGATIVE_VALUE");

        // solhint-disable not-rely-on-time
        require(
            block.timestamp.sub(updatedAt) <= chainlinkStalePeriod,
            "CHAINLINK_STALE_DATA"
        );
        // solhint-enable not-rely-on-time

        return uint256(price);
    }
}
