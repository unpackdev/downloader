// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IERC165Upgradeable.sol";
import "./IERC20.sol";
import "./IAccessControl.sol";

import "./Errors.sol";

import "./PrimexDNSStorage.sol";
import "./Constants.sol";
import "./IBucket.sol";
import "./WadRayMath.sol";
import "./IPrimexDNS.sol";
import "./IDexAdapter.sol";
import "./ILiquidityMiningRewardDistributor.sol";
import "./ITreasury.sol";
import "./IConditionalClosingManager.sol";
import "./IConditionalOpeningManager.sol";

contract PrimexDNS is IPrimexDNSV2, PrimexDNSStorageV2 {
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Modifier that checks if the caller has a specific role.
     * @param _role The role identifier to check.
     */
    modifier onlyRole(bytes32 _role) {
        _require(IAccessControl(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    /**
     * @inheritdoc IPrimexDNS
     */
    function initialize(
        address _registry,
        address _pmx,
        address _treasury,
        uint256 _delistingDelay,
        uint256 _adminWithdrawalDelay,
        FeeRateParams[] calldata _feeRateParams
    ) public override initializer {
        _require(
            IERC165Upgradeable(_pmx).supportsInterface(type(IERC20).interfaceId) &&
                IERC165Upgradeable(_registry).supportsInterface(type(IAccessControl).interfaceId) &&
                IERC165Upgradeable(_treasury).supportsInterface(type(ITreasury).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        for (uint256 i; i < _feeRateParams.length; i++) {
            _setFeeRate(_feeRateParams[i]);
        }
        pmx = _pmx;
        registry = _registry;
        treasury = _treasury;
        delistingDelay = _delistingDelay;
        adminWithdrawalDelay = _adminWithdrawalDelay;
        __ERC165_init();
    }

    /**
     * @inheritdoc IPrimexDNS
     */
    function setConditionalManager(uint256 _cmType, address _address) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        _require(
            IERC165Upgradeable(_address).supportsInterface(type(IConditionalOpeningManager).interfaceId) ||
                IERC165Upgradeable(_address).supportsInterface(type(IConditionalClosingManager).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        cmTypeToAddress[_cmType] = _address;
        emit ConditionalManagerChanged(_cmType, _address);
    }

    /**
     * @inheritdoc IPrimexDNS
     */
    function setPMX(address _pmx) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        _require(
            IERC165Upgradeable(_pmx).supportsInterface(type(IERC20).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        pmx = _pmx;
        emit PMXchanged(_pmx);
    }

    /**
     * @inheritdoc IPrimexDNS
     */
    function setFeeRate(FeeRateParams calldata _feeRateParams) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        _setFeeRate(_feeRateParams);
    }

    /**
     * @inheritdoc IPrimexDNSV2
     */
    function setFeeRestrictions(
        OrderType _orderType,
        FeeRestrictions calldata _feeRestrictions
    ) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        _require(
            _feeRestrictions.minProtocolFee <= _feeRestrictions.maxProtocolFee,
            Errors.INCORRECT_RESTRICTIONS.selector
        );
        feeRestrictions[_orderType] = _feeRestrictions;
        emit ChangeFeeRestrictions(_orderType, _feeRestrictions);
    }

    /**
     * @inheritdoc IPrimexDNS
     */
    function setAavePool(address _aavePool) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        aavePool = _aavePool;
        emit AavePoolChanged(_aavePool);
    }

    /**
     * @inheritdoc IPrimexDNS
     */
    function deprecateBucket(string memory _bucket) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        BucketData storage bucket = buckets[_bucket];
        _require(bucket.currentStatus != Status.Deprecated, Errors.BUCKET_IS_ALREADY_DEPRECATED.selector);
        bucket.currentStatus = Status.Deprecated;
        uint256 delistingDeadline = block.timestamp + delistingDelay;
        bucket.delistingDeadline = delistingDeadline;
        bucket.adminDeadline = delistingDeadline + adminWithdrawalDelay;
        emit BucketDeprecated(bucket.bucketAddress, delistingDeadline);
    }

    /**
     * @inheritdoc IPrimexDNS
     */
    function activateBucket(string memory _bucket) external override onlyRole(SMALL_TIMELOCK_ADMIN) {
        BucketData storage bucket = buckets[_bucket];
        _require(bucket.currentStatus == Status.Inactive, Errors.BUCKET_ALREADY_ACTIVATED.selector);
        _require(bucket.bucketAddress != address(0), Errors.BUCKET_NOT_ADDED.selector);
        bucket.currentStatus = Status.Active;
        emit BucketActivated(bucket.bucketAddress);
    }

    /**
     * @inheritdoc IPrimexDNS
     */
    function freezeBucket(string memory _bucket) external override onlyRole(EMERGENCY_ADMIN) {
        _require(buckets[_bucket].currentStatus == Status.Active, Errors.BUCKET_ALREADY_FROZEN.selector);
        buckets[_bucket].currentStatus = Status.Inactive;
        emit BucketFrozen(buckets[_bucket].bucketAddress);
    }

    /**
     * @inheritdoc IPrimexDNS
     */
    function addBucket(address _newBucket, uint256 _pmxRewardAmount) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        _require(
            IERC165Upgradeable(_newBucket).supportsInterface(type(IBucket).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        string memory name = IBucket(_newBucket).name();
        _require(buckets[name].bucketAddress == address(0), Errors.BUCKET_IS_ALREADY_ADDED.selector);

        IBucket.LiquidityMiningParams memory params = IBucket(_newBucket).getLiquidityMiningParams();
        if (params.accumulatingAmount != 0) {
            // can be changed on transferAsset in traderBalanceVault to moving untransferable token
            IERC20(pmx).transferFrom(msg.sender, address(params.liquidityMiningRewardDistributor), _pmxRewardAmount);
            params.liquidityMiningRewardDistributor.updateBucketReward(name, _pmxRewardAmount);
        }

        BucketData memory newBucket = BucketData(_newBucket, Status.Active, 0, 0);
        buckets[name] = newBucket;
        emit AddNewBucket(newBucket);
    }

    /**
     * @inheritdoc IPrimexDNS
     */
    function activateDEX(string memory _dex) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        _require(!dexes[_dex].isActive, Errors.DEX_IS_ALREADY_ACTIVATED.selector);
        dexes[_dex].isActive = true;
        emit DexActivated(dexes[_dex].routerAddress);
    }

    /**
     * @inheritdoc IPrimexDNS
     */
    function freezeDEX(string memory _dex) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        _require(dexes[_dex].isActive, Errors.DEX_IS_ALREADY_FROZEN.selector);
        dexes[_dex].isActive = false;
        emit DexFrozen(dexes[_dex].routerAddress);
    }

    /**
     * @inheritdoc IPrimexDNS
     */
    function addDEX(string memory _name, address _routerAddress) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        _require(dexes[_name].routerAddress == address(0), Errors.DEX_IS_ALREADY_ADDED.selector);
        _require(_routerAddress != address(0), Errors.CAN_NOT_ADD_WITH_ZERO_ADDRESS.selector);
        dexesNames.push(_name);
        DexData memory newDEX = DexData(_routerAddress, true);
        dexes[_name] = newDEX;
        emit AddNewDex(newDEX);
    }

    /**
     * @inheritdoc IPrimexDNS
     */
    function setDexAdapter(address _newAdapterAddress) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        _require(
            IERC165Upgradeable(_newAdapterAddress).supportsInterface(type(IDexAdapter).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        dexAdapter = _newAdapterAddress;
        emit DexAdapterChanged(_newAdapterAddress);
    }

    /**
     * @inheritdoc IPrimexDNS
     */
    function getAllDexes() external view override returns (string[] memory) {
        return dexesNames;
    }

    /**
     * @inheritdoc IPrimexDNS
     */
    function getBucketAddress(string memory _name) external view override returns (address) {
        BucketData memory bucket = buckets[_name];
        _require(bucket.bucketAddress != address(0), Errors.BUCKET_NOT_ADDED.selector);
        _require(bucket.currentStatus == Status.Active, Errors.BUCKET_IS_INACTIVE.selector);
        return bucket.bucketAddress;
    }

    /**
     * @inheritdoc IPrimexDNS
     */
    function getDexAddress(string memory _name) external view override returns (address) {
        DexData memory dex = dexes[_name];
        _require(dex.routerAddress != address(0), Errors.DEX_NOT_ADDED.selector);
        _require(dex.isActive, Errors.DEX_NOT_ACTIVE.selector);
        return dex.routerAddress;
    }

    /**
     * @notice Interface checker
     * @param interfaceId The interface id to check
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IPrimexDNSV2).interfaceId ||
            interfaceId == type(IPrimexDNS).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _setFeeRate(FeeRateParams calldata _feeRateParams) internal {
        _require(_feeRateParams.rate <= WadRayMath.WAD, Errors.INCORRECT_FEE_RATE.selector);
        feeRates[_feeRateParams.orderType][_feeRateParams.feeToken] = _feeRateParams.rate;
        emit ChangeFeeRate(_feeRateParams.orderType, _feeRateParams.feeToken, _feeRateParams.rate);
    }
}
