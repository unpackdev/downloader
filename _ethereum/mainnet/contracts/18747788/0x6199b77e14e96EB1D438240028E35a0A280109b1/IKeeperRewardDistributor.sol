// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IKeeperRewardDistributorStorage.sol";
import "./IPausable.sol";

interface IKeeperRewardDistributor is IKeeperRewardDistributorStorage, IPausable {
    struct DecreasingGasByReasonParams {
        DecreasingReason reason;
        uint256 amount;
    }
    struct MaxGasPerPositionParams {
        KeeperActionType actionType;
        KeeperActionRewardConfig config;
    }

    /**
     * @dev     Params for initialize() function
     * @param   priceOracle  Address of the PriceOracle contract
     * @param   registry  Address of the Registry contract
     * @param   pmx  Address of PMXToken
     * @param   treasury  Address of the Treasury contract
     * @param   pmxPartInReward  Percentage of PMX in reward (in WAD)
     * @param   nativePartInReward  Percentage of native token in reward (in WAD)
     * @param   positionSizeCoefficientA  CoefficientA in the formula positionSize * CoefficientA + CoefficientB
     * @param   positionSizeCoefficientB  CoefficientB in the formula positionSize * CoefficientA + CoefficientB
     * @param   additionalGas  Additional gas added to actual gas spent
     * @param   defaultMaxGasPrice  Max gas price allowed during reward calculation (used when no oracle price found)
     * @param   oracleGasPriceTolerance  Percentage by which oracle gas price can be exceeded (in WAD)
     * @param   paymentModel  The model of payment for gas in the network
     * @param   maxGasPerPositionParams  Parameters for the setMaxGasPerPosition function
     * @param   decreasingGasByReasonParams  Parameters for the setDecreasingGasByReason function
     */
    struct InitParams {
        address priceOracle;
        address registry;
        address pmx;
        address treasury;
        address whiteBlackList;
        uint256 pmxPartInReward;
        uint256 nativePartInReward;
        uint256 positionSizeCoefficientA;
        int256 positionSizeCoefficientB;
        uint256 additionalGas;
        uint256 defaultMaxGasPrice;
        uint256 oracleGasPriceTolerance;
        PaymentModel paymentModel;
        MaxGasPerPositionParams[] maxGasPerPositionParams;
        DecreasingGasByReasonParams[] decreasingGasByReasonParams;
    }

    event ClaimFees(address indexed keeper, address indexed asset, uint256 amount);
    event DefaultMaxGasPriceChanged(uint256 indexed defaultMaxGasPrice);
    event OracleGasPriceToleranceChanged(uint256 indexed oracleGasPriceTolerance);
    event MaxGasPerPositionChanged(KeeperActionType indexed actionType, KeeperActionRewardConfig config);
    event DataLengthRestrictionsChanged(KeeperCallingMethod callingMethod, uint256 maxRoutesLength, uint256 baseLength);
    event DecreasingGasByReasonChanged(DecreasingReason indexed reason, uint256 amount);
    event PmxPartInRewardChanged(uint256 indexed pmxPartInReward);
    event NativePartInRewardChanged(uint256 indexed nativePartInReward);
    event PositionSizeCoefficientsChanged(
        uint256 indexed positionSizeCoefficientA,
        int256 indexed positionSizeCoefficientB
    );
    event AdditionalGasChanged(uint256 indexed additionalGas);
    event KeeperRewardUpdated(address indexed keeper, uint256 rewardInPmx, uint256 rewardInNativeCurrency);

    /**
     * @notice Initializes the KeeperRewardDistributor contract.
     * @param _params  Parameters for initialization
     */
    function initialize(InitParams calldata _params) external;

    /**
     * @dev Params for the updateReward function
     * @param keeper  Address of the keeper
     * @param positionAsset  Address of the position asset
     * @param positionSize  Size of the position
     * @param action  The action that was performed by the keeper
     * @param numberOfActions  Number of actions performed by the keeper
     * @param gasSpent Gas spent on executing transaction
     * @param decreasingCounter An array where each index contains the number of decreasing reasons according to the DecreasingReason enum
     * @param routesLength  The length of routes provided as input to the protocol function,
     * subject to an additional commission in the ARBITRUM payment model.
     */

    struct UpdateRewardParams {
        address keeper;
        address positionAsset;
        uint256 positionSize;
        KeeperActionType action;
        uint256 numberOfActions;
        uint256 gasSpent;
        uint256[] decreasingCounter;
        uint256 routesLength;
    }

    /**
     * @notice Updates reward for keeper for closing position or executing order
     * @dev Only callable by the PM_ROLE, LOM_ROLE, BATCH_MANAGER_ROLE roles.
     * @param _params The UpdateRewardParams params
     */
    function updateReward(UpdateRewardParams calldata _params) external;

    /**
     * @notice Claims earned reward of the keeper
     * @param _pmxAmount  Amount of PMX token to claim
     * @param _nativeAmount  Amount of native token to claim
     */
    function claim(uint256 _pmxAmount, uint256 _nativeAmount) external;

    /**
     * @notice Sets the default maximum gas price allowed.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _defaultMaxGasPrice The new default maximum gas price value.
     */
    function setDefaultMaxGasPrice(uint256 _defaultMaxGasPrice) external;

    /**
     * @notice Sets the amount of gas to be removed for the specified reason
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _reason The reason for which an amount is set
     * @param _amount Gas amount.
     */
    function setDecreasingGasByReason(DecreasingReason _reason, uint256 _amount) external;

    /**
     * @notice Sets the KeeperActionRewardConfig for the specified action type
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _actionType The action type for which the config is set
     * @param _config The KeeperActionRewardConfig struct
     */

    function setMaxGasPerPosition(KeeperActionType _actionType, KeeperActionRewardConfig calldata _config) external;

    /**
     * @notice Sets the dataLengthRestrictions for the specified KeeperCallingMethod.
     * @param _callingMethod The calling method for which dataLengthRestrictions is set
     * @param _maxRoutesLength The maximum routes length for which an additional fee will be paid in the ARBITRUM payment model, in bytes
     * @param _baseLength The length of the data entering the protocol function including method signature
     * and excluding dynamic types(e.g, routesLength), in bytes
     */
    function setDataLengthRestrictions(
        KeeperCallingMethod _callingMethod,
        uint256 _maxRoutesLength,
        uint256 _baseLength
    ) external;

    /**
     * @notice Sets the tolerance for gas price fluctuations from the oracle price.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _oracleGasPriceTolerance The new oracle gas price tolerance value (percent expressed as WAD).
     */
    function setOracleGasPriceTolerance(uint256 _oracleGasPriceTolerance) external;

    /**
     * @notice Sets the PMX token's portion in the reward calculation.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _pmxPartInReward The new PMX token's portion in the reward calculation (percent expressed as WAD).
     */
    function setPmxPartInReward(uint256 _pmxPartInReward) external;

    /**
     * @notice Sets the native token's portion in the reward calculation.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _nativePartInReward The new native token's portion in the reward calculation (percent expressed as WAD).
     */
    function setNativePartInReward(uint256 _nativePartInReward) external;

    /**
     * @notice Sets the position size coefficients for reward calculations.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _positionSizeCoefficientA The new positionSizeCoefficientA value (in WAD).
     * @param _positionSizeCoefficientB The new positionSizeCoefficientB value (in WAD).
     */
    function setPositionSizeCoefficients(uint256 _positionSizeCoefficientA, int256 _positionSizeCoefficientB) external;

    /**
     * @notice Sets the additional gas value for reward calculations.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _additionalGas The new additionalGas value.
     */
    function setAdditionalGas(uint256 _additionalGas) external;
}

interface IKeeperRewardDistributorV2 is IKeeperRewardDistributor, IKeeperRewardDistributorStorageV2 {
    event MinPositionSizeMultiplierChanged(int256 newMinPositionSizeMultiplier);

    /**
     * @notice Sets the minPositionSizeMultiplier for reward calculations.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _minPositionSizeMultiplier The new minPositionSizeMultiplier value (in WAD).
     */

    function setMinPositionSizeMultiplier(int256 _minPositionSizeMultiplier) external;
}
