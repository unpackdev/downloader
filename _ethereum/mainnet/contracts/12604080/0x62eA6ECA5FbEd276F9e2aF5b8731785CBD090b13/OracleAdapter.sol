// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./AggregatorV3Interface.sol";
import "./IOracleAdapter.sol";
import "./IAddressRegistryV2.sol";

/**
 * @title Oracle Adapter
 * @author APY.Finance
 * @notice Acts as a gateway to oracle values and implements oracle safeguards.
 *
 * Oracle Safeguard Flows:
 *
 *      - Unlocked → No Manual Submitted Value → Use Chainlink Value (default)
 *      - Unlocked → No Manual Submitted Value → No Chainlink Source → Reverts
 *      - Unlocked → No Manual Submitted Value → Chainlink Value Call Reverts → Reverts
 *      - Unlocked → No Manual Submitted Value → Chainlink Value > 24 hours → Reverts
 *      - Unlocked → Use Manual Submitted Value (emergency)
 *      - Locked → Reverts (nominal)
 *
 * @dev It is important to not that zero values are allowed for manual
 * submission, but will result in a revert for Chainlink.
 *
 * This is because there are very rare situations where the TVL value can
 * accurately be zero, such as a situation where all funds are unwound and
 * moved back to the liquidity pools, but a zero value can also indicate a
 * failure with Chainlink.
 *
 * Because accurate zero values are rare, and occur due to intentional system
 * states where no funds are deployed, they due not need to be detected
 * automatically by Chainlink.
 *
 * In addition, the impact of failing to manually set a zero value when
 * necessary compared to the impact of an incorrect zero value from Chainlink
 * is much lower.
 *
 * Failing to manually set a zero value can result in either a locked contract,
 * which can be unlocked by setting the value, or reduced deposit/withdraw
 * amounts. But never a loss of funds.
 *
 * Conversely, if Chainlink reports a zero value in error and the contract
 * were to accept it, funds up to the amount available in the reserve pools
 * could be lost.
 */
contract OracleAdapter is Ownable, IOracleAdapter {
    using SafeMath for uint256;
    using Address for address;

    IAddressRegistryV2 public addressRegistry;

    uint256 public override defaultLockPeriod;
    /// @notice Contract is locked until this block number is passed
    uint256 public lockEnd;

    /// @notice Chainlink variables
    uint256 public chainlinkStalePeriod; // Duration of Chainlink heartbeat
    AggregatorV3Interface public tvlSource;
    mapping(address => AggregatorV3Interface) public assetSources;

    /// @notice Submitted values that override Chainlink values until stale
    mapping(address => Value) public submittedAssetValues;
    Value public submittedTvlValue;

    event AssetSourceUpdated(address indexed asset, address indexed source);
    event TvlSourceUpdated(address indexed source);
    event ChainlinkStalePeriodUpdated(uint256 period);

    modifier unlocked() {
        require(!isLocked(), "ORACLE_LOCKED");
        _;
    }

    modifier locked() {
        require(isLocked(), "ORACLE_UNLOCKED");
        _;
    }

    /// @dev Reverts if non-permissioned account calls.
    /// Permissioned accounts are: owner, mAPT, and TVL manager
    modifier onlyPermissioned() {
        require(
            msg.sender == owner() ||
                msg.sender == addressRegistry.mAptAddress() ||
                msg.sender == addressRegistry.tvlManagerAddress(),
            "PERMISSIONED_ONLY"
        );
        _;
    }

    /**
     * @notice Constructor
     * @param _addressRegistry the address registry
     * @param assets the assets priced by sources
     * @param sources the source for each asset
     * @param tvlSource the source for the TVL value
     * @param _chainlinkStalePeriod the number of seconds until a source value is stale
     */
    constructor(
        address _addressRegistry,
        address tvlSource,
        address[] memory assets,
        address[] memory sources,
        uint256 _chainlinkStalePeriod,
        uint256 _defaultLockPeriod
    ) public {
        setAddressRegistry(_addressRegistry);
        setTvlSource(tvlSource);
        setAssetSources(assets, sources);
        setChainlinkStalePeriod(_chainlinkStalePeriod);
        setDefaultLockPeriod(_defaultLockPeriod);
    }

    function setDefaultLockPeriod(uint256 newPeriod) public override onlyOwner {
        defaultLockPeriod = newPeriod;
    }

    function lock() external override onlyPermissioned {
        lockFor(defaultLockPeriod);
    }

    function unlock() external override onlyPermissioned {
        lockFor(0);
    }

    function lockFor(uint256 activePeriod) public override onlyPermissioned {
        lockEnd = block.number.add(activePeriod);
    }

    /**
     * @notice Sets the address registry
     * @dev only callable by owner
     * @param _addressRegistry the address of the registry
     */
    function setAddressRegistry(address _addressRegistry) public onlyOwner {
        require(Address.isContract(_addressRegistry), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(_addressRegistry);
    }

    //------------------------------------------------------------
    // MANUAL SUBMISSION SETTERS
    //------------------------------------------------------------

    function setAssetValue(
        address asset,
        uint256 value,
        uint256 period
    ) external override locked onlyOwner {
        // We do allow 0 values for submitted values
        submittedAssetValues[asset] = Value(value, block.number.add(period));
    }

    function setTvl(uint256 value, uint256 period)
        external
        override
        locked
        onlyOwner
    {
        // We do allow 0 values for submitted values
        submittedTvlValue = Value(value, block.number.add(period));
    }

    //------------------------------------------------------------
    // CHAINLINK SETTERS
    //------------------------------------------------------------

    /**
     * @notice Set or replace the TVL source
     * @param source the TVL source address
     */
    function setTvlSource(address source) public onlyOwner {
        require(source.isContract(), "INVALID_SOURCE");
        tvlSource = AggregatorV3Interface(source);
        emit TvlSourceUpdated(source);
    }

    /**
     * @notice Set or replace asset price sources
     * @param assets the array of assets token addresses
     * @param sources the array of price sources (aggregators)
     */
    function setAssetSources(address[] memory assets, address[] memory sources)
        public
        onlyOwner
    {
        require(assets.length == sources.length, "INCONSISTENT_PARAMS_LENGTH");
        for (uint256 i = 0; i < assets.length; i++) {
            setAssetSource(assets[i], sources[i]);
        }
    }

    /**
     * @notice Set a single asset price source
     * @param asset asset token address
     * @param source the price source (aggregator)
     */
    function setAssetSource(address asset, address source) public onlyOwner {
        require(source.isContract(), "INVALID_SOURCE");
        assetSources[asset] = AggregatorV3Interface(source);
        emit AssetSourceUpdated(asset, source);
    }

    /**
     * @notice Set the length of time before an agg value is considered stale
     * @param _chainlinkStalePeriod the length of time in seconds
     */
    function setChainlinkStalePeriod(uint256 _chainlinkStalePeriod)
        public
        onlyOwner
    {
        require(_chainlinkStalePeriod > 0, "INVALID_STALE_PERIOD");
        chainlinkStalePeriod = _chainlinkStalePeriod;
        emit ChainlinkStalePeriodUpdated(_chainlinkStalePeriod);
    }

    function isLocked() public view override returns (bool) {
        return block.number < lockEnd;
    }

    //------------------------------------------------------------
    // ORACLE VALUE GETTERS
    //------------------------------------------------------------

    function getTvl() external view override unlocked returns (uint256) {
        if (block.number < submittedTvlValue.periodEnd) {
            return submittedTvlValue.value;
        }
        return _getPriceFromSource(tvlSource);
    }

    /**
     * @notice Gets an asset price by address
     * @param asset the asset address
     * @return the asset price
     */
    function getAssetPrice(address asset)
        public
        view
        override
        unlocked
        returns (uint256)
    {
        if (block.number < submittedAssetValues[asset].periodEnd) {
            return submittedAssetValues[asset].value;
        }
        AggregatorV3Interface source = assetSources[asset];
        return _getPriceFromSource(source);
    }

    /**
     * @notice Get the price from a source (aggregator)
     * @dev Prices and TVL values should always be positive
     * @return the price from the source
     */
    function _getPriceFromSource(AggregatorV3Interface source)
        internal
        view
        returns (uint256)
    {
        require(address(source).isContract(), "INVALID_SOURCE");
        (, int256 price, , uint256 updatedAt, ) = source.latestRoundData();

        //we do not allow 0 values for chainlink
        require(price > 0, "MISSING_ASSET_VALUE");

        // solhint-disable not-rely-on-time
        require(
            block.timestamp.sub(updatedAt) <= chainlinkStalePeriod,
            "CHAINLINK_STALE_DATA"
        );
        // solhint-enable not-rely-on-time

        return uint256(price);
    }
}
