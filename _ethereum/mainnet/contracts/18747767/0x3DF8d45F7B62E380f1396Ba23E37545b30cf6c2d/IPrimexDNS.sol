// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IPrimexDNSStorage.sol";

interface IPrimexDNS is IPrimexDNSStorage {
    event AddNewBucket(BucketData newBucketData);
    event BucketDeprecated(address bucketAddress, uint256 delistingTime);
    event AddNewDex(DexData newDexData);
    event ChangeFeeRate(OrderType orderType, address token, uint256 rate);
    event ConditionalManagerChanged(uint256 indexed cmType, address indexed cmAddress);
    event PMXchanged(address indexed pmx);
    event AavePoolChanged(address indexed aavePool);
    event BucketActivated(address indexed bucketAddress);
    event BucketFrozen(address indexed bucketAddress);
    event DexAdapterChanged(address indexed newAdapterAddress);
    event DexActivated(address indexed routerAddress);
    event DexFrozen(address indexed routerAddress);

    /**
     * @param orderType The order type for which the rate is set
     * @param feeToken The token address for which the rate is set
     * @param rate Setting rate in WAD format (1 WAD = 100%)
     */
    struct FeeRateParams {
        OrderType orderType;
        address feeToken;
        uint256 rate;
    }

    /**
     * @notice Initializes the contract with the specified parameters.
     * @param _registry The address of the PrimexRegistry contract.
     * @param _pmx The address of the PMX token contract.
     * @param _treasury The address of the Treasury contract.
     * @param _delistingDelay The time (in seconds) between deprecation and delisting of a bucket.
     * @param _adminWithdrawalDelay The time (in seconds) between delisting of a bucket and an adminDeadline.
     * @param _feeRateParams Initial fee params
     */
    function initialize(
        address _registry,
        address _pmx,
        address _treasury,
        uint256 _delistingDelay,
        uint256 _adminWithdrawalDelay,
        FeeRateParams[] calldata _feeRateParams
    ) external;

    /**
     * @notice Deprecates a bucket.
     * @dev This function is used to deprecate a bucket by changing its current status to "Deprecated".
     * Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _bucket The name of the bucket to deprecate.
     * Emits a BucketDeprecated event with the bucket address and the delisting time.
     */
    function deprecateBucket(string memory _bucket) external;

    /**
     * @notice This function is used to set the address of the Aave pool contract.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _aavePool The address of the Aave pool contract to be set.
     */
    function setAavePool(address _aavePool) external;

    /**
     * @notice Sets the protocol rate in PMX.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     */
    function setFeeRate(FeeRateParams calldata _feeRateParams) external;

    /**
     * @notice Sets the address of the PMX token contract.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _pmx The address of the PMX token contract.
     */
    function setPMX(address _pmx) external;

    /**
     * @notice Activates a bucket by changing its status from inactive to active.
     * @dev Only callable by the SMALL_TIMELOCK_ADMIN role.
     * @param _bucket The bucket to activate.
     */
    function activateBucket(string memory _bucket) external;

    /**
     * @notice Freezes a bucket, preventing further operations on it,
     * by changing its status from active to inactive.
     * @dev Only callable by the EMERGENCY_ADMIN role.
     * @param _bucket The bucket to be frozen.
     */
    function freezeBucket(string memory _bucket) external;

    /**
     * @notice Adds a new bucket.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _newBucket The address of the new bucket to be added.
     * @param _pmxRewardAmount The amount of PMX tokens to be rewarded from the bucket.
     * Emits a AddNewBucket event with the struct BucketData of the newly added bucket.
     */
    function addBucket(address _newBucket, uint256 _pmxRewardAmount) external;

    /**
     * @notice Activates a DEX by changing flag isActive on to true.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _dex The name of the DEX to activate.
     */
    function activateDEX(string memory _dex) external;

    /**
     * @notice Freezes a DEX by changing flag isActive to false.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _dex The name of the DEX to be frozen.
     */
    function freezeDEX(string memory _dex) external;

    /**
     * @notice Adds a new DEX to the protocol.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _name The name of the DEX.
     * @param _routerAddress The address of the DEX router.
     */
    function addDEX(string memory _name, address _routerAddress) external;

    /**
     * @notice Sets the address of the DEX adapter.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param newAdapterAddress The address of the new DEX adapter.
     */
    function setDexAdapter(address newAdapterAddress) external;

    /**
     * @dev The function to specify the address of conditional manager of some type
     * 1 => LimitPriceCOM
     * 2 => TakeProfitStopLossCCM
     * 3 => TrailingStopCCM
     * @param _address Address to be set for a conditional manager
     * @param _cmType The type of a conditional manager
     */
    function setConditionalManager(uint256 _cmType, address _address) external;

    /**
     * @notice Retrieves the address of a bucket by its name.
     * @param _name The name of the bucket.
     * @return The address of the bucket.
     */
    function getBucketAddress(string memory _name) external view returns (address);

    /**
     * @notice Retrieves the address of the DEX router based on the given DEX name.
     * @param _name The name of the DEX.
     * @return The address of the DEX router.
     */
    function getDexAddress(string memory _name) external view returns (address);

    /**
     * @notice Retrieves the names of Dexes registered in the protocol.
     * @return An array of strings containing the names of all Dexes.
     */
    function getAllDexes() external view returns (string[] memory);
}

interface IPrimexDNSV2 is IPrimexDNS, IPrimexDNSStorageV2 {
    event ChangeFeeRestrictions(OrderType indexed orderType, FeeRestrictions feeRestrictions);

    /**
     * @notice Set the protocol fee restriction for one type of order.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     */
    function setFeeRestrictions(OrderType _orderType, FeeRestrictions calldata _feeRestrictions) external;
}
