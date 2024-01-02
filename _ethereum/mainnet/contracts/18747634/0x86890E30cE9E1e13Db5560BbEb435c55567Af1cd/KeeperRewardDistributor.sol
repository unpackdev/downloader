// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IERC20Metadata.sol";
import "./IERC20.sol";
import "./IERC165Upgradeable.sol";
import "./WadRayMath.sol";

import "./PrimexPricingLibrary.sol";
import "./TokenTransfersLibrary.sol";

import "./KeeperRewardDistributorStorage.sol";
import "./Constants.sol";
import "./IKeeperRewardDistributor.sol";
import "./IPriceOracle.sol";
import "./IWhiteBlackList.sol";
import "./IPositionManager.sol";
import "./ITreasury.sol";
import "./IPausable.sol";
import "./IArbGasInfo.sol";

contract KeeperRewardDistributor is IKeeperRewardDistributorV2, KeeperRewardDistributorStorageV2 {
    using WadRayMath for uint256;
    IArbGasInfo internal constant ARB_NITRO_ORACLE = IArbGasInfo(0x000000000000000000000000000000000000006C);
    uint256 internal constant GAS_FOR_BYTE = 16;
    uint256 internal constant TRASNSACTION_METADATA_BYTES = 140;

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
     * @dev Modifier to check if the sender is not blacklisted.
     */
    modifier notBlackListed() {
        _require(!whiteBlackList.isBlackListed(msg.sender), Errors.SENDER_IS_BLACKLISTED.selector);
        _;
    }
    /**
     * @dev Modifier that checks if the caller has a manager role.
     */

    modifier onlyManagerRole() {
        _require(
            IAccessControl(registry).hasRole(PM_ROLE, msg.sender) ||
                IAccessControl(registry).hasRole(LOM_ROLE, msg.sender) ||
                IAccessControl(registry).hasRole(BATCH_MANAGER_ROLE, msg.sender),
            Errors.FORBIDDEN.selector
        );
        _;
    }

    /**
     * @inheritdoc IKeeperRewardDistributor
     */
    function initialize(InitParams calldata _params) external override initializer {
        _require(
            IERC165Upgradeable(_params.registry).supportsInterface(type(IAccessControl).interfaceId) &&
                IERC165Upgradeable(_params.priceOracle).supportsInterface(type(IPriceOracle).interfaceId) &&
                IERC165Upgradeable(_params.treasury).supportsInterface(type(ITreasury).interfaceId) &&
                IERC165Upgradeable(_params.pmx).supportsInterface(type(IERC20).interfaceId) &&
                IERC165Upgradeable(_params.whiteBlackList).supportsInterface(type(IWhiteBlackList).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        pmx = _params.pmx;
        priceOracle = _params.priceOracle;
        registry = _params.registry;
        treasury = payable(_params.treasury);
        whiteBlackList = IWhiteBlackList(_params.whiteBlackList);
        pmxPartInReward = _params.pmxPartInReward;
        nativePartInReward = _params.nativePartInReward;
        positionSizeCoefficientA = _params.positionSizeCoefficientA;
        positionSizeCoefficientB = _params.positionSizeCoefficientB;
        additionalGas = _params.additionalGas;
        defaultMaxGasPrice = _params.defaultMaxGasPrice;
        oracleGasPriceTolerance = _params.oracleGasPriceTolerance;
        paymentModel = _params.paymentModel;
        for (uint i; i < _params.maxGasPerPositionParams.length; ++i) {
            _setMaxGasPerPosition(
                _params.maxGasPerPositionParams[i].actionType,
                _params.maxGasPerPositionParams[i].config
            );
        }
        for (uint i; i < _params.decreasingGasByReasonParams.length; ++i) {
            _setDecreasingGasByReason(
                _params.decreasingGasByReasonParams[i].reason,
                _params.decreasingGasByReasonParams[i].amount
            );
        }
        __ReentrancyGuard_init();
        __Pausable_init();
        __ERC165_init();
    }

    /**
     * @inheritdoc IKeeperRewardDistributor
     */
    function updateReward(UpdateRewardParams calldata _params) external override onlyManagerRole {
        int256 positionSizeMultiplier = int256(
            (
                PrimexPricingLibrary.getOracleAmountsOut(
                    _params.positionAsset,
                    NATIVE_CURRENCY,
                    _params.positionSize,
                    priceOracle
                )
            ).wmul(positionSizeCoefficientA)
        ) + positionSizeCoefficientB;
        if (positionSizeMultiplier <= 0) return;
        if (positionSizeMultiplier < minPositionSizeMultiplier) positionSizeMultiplier = minPositionSizeMultiplier;

        uint256 gasAmount = additionalGas + _pureGasSpent(_params.gasSpent, _params.decreasingCounter);
        uint256 maxGasAmount = _getMaxGasAmount(_params.action, _params.numberOfActions);
        if (gasAmount > maxGasAmount) {
            gasAmount = maxGasAmount;
        }
        uint256 gasPrice = tx.gasprice;
        int256 oracleGasPrice = IPriceOracle(priceOracle).getGasPrice();
        uint256 maxGasPriceForReward = oracleGasPrice > 0
            ? uint256(oracleGasPrice).wmul(WadRayMath.WAD + oracleGasPriceTolerance)
            : defaultMaxGasPrice;
        if (gasPrice > maxGasPriceForReward) {
            gasPrice = maxGasPriceForReward;
        }

        uint256 rewardInNativeCurrency;
        uint256 rewardInPmx;

        // to avoid stack too deep
        {
            uint256 l1CostWei;
            if (paymentModel == PaymentModel.ARBITRUM) {
                KeeperCallingMethod callingMethod;
                uint256 variableLength;
                if (_params.numberOfActions > 1) {
                    callingMethod = KeeperCallingMethod.CloseBatchPositions;
                    // 64 represents 1 slot (32bytes) of _ids and 1 slot (32 bytes) of _conditionIndexes
                    variableLength = _params.numberOfActions * 64;
                } else if (_params.action == KeeperActionType.OpenByOrder) {
                    callingMethod = KeeperCallingMethod.OpenPositionByOrder;
                } else {
                    callingMethod = KeeperCallingMethod.ClosePositionByCondition;
                }
                DataLengthRestrictions memory restrictions = dataLengthRestrictions[callingMethod];
                variableLength += _params.routesLength < restrictions.maxRoutesLength
                    ? _params.routesLength
                    : restrictions.maxRoutesLength;
                l1CostWei =
                    ARB_NITRO_ORACLE.getL1BaseFeeEstimate() *
                    GAS_FOR_BYTE *
                    (variableLength + restrictions.baseLength + TRASNSACTION_METADATA_BYTES);
            }

            uint256 reward = (gasAmount * gasPrice + l1CostWei).wmul(uint256(positionSizeMultiplier));
            rewardInNativeCurrency = reward.wmul(nativePartInReward);
            rewardInPmx = PrimexPricingLibrary.getOracleAmountsOut(NATIVE_CURRENCY, pmx, reward, priceOracle).wmul(
                pmxPartInReward
            );
        }
        keeperBalance[_params.keeper].pmxBalance += rewardInPmx;
        keeperBalance[_params.keeper].nativeBalance += rewardInNativeCurrency;

        totalBalance.pmxBalance += rewardInPmx;
        totalBalance.nativeBalance += rewardInNativeCurrency;
        emit KeeperRewardUpdated(_params.keeper, rewardInPmx, rewardInNativeCurrency);
    }

    /**
     * @inheritdoc IKeeperRewardDistributor
     */
    function claim(
        uint256 _pmxAmount,
        uint256 _nativeAmount
    ) external override nonReentrant whenNotPaused notBlackListed {
        KeeperBalance memory balance = keeperBalance[msg.sender];
        if (_pmxAmount > balance.pmxBalance) _pmxAmount = balance.pmxBalance;
        if (_nativeAmount > balance.nativeBalance) _nativeAmount = balance.nativeBalance;

        if (_pmxAmount > 0) {
            keeperBalance[msg.sender].pmxBalance -= _pmxAmount;
            totalBalance.pmxBalance -= _pmxAmount;
            ITreasury(treasury).transferFromTreasury(_pmxAmount, pmx, msg.sender);
            emit ClaimFees(msg.sender, pmx, _pmxAmount);
        }
        if (_nativeAmount > 0) {
            keeperBalance[msg.sender].nativeBalance -= _nativeAmount;
            totalBalance.nativeBalance -= _nativeAmount;
            ITreasury(treasury).transferFromTreasury(_nativeAmount, NATIVE_CURRENCY, msg.sender);
            emit ClaimFees(msg.sender, NATIVE_CURRENCY, _nativeAmount);
        }
    }

    /**
     * @inheritdoc IKeeperRewardDistributor
     */

    function setDecreasingGasByReason(
        DecreasingReason _reason,
        uint256 _amount
    ) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        _setDecreasingGasByReason(_reason, _amount);
    }

    /**
     * @inheritdoc IKeeperRewardDistributorV2
     */

    function setMinPositionSizeMultiplier(
        int256 _minPositionSizeMultiplier
    ) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        _require(
            _minPositionSizeMultiplier > 0 && uint256(_minPositionSizeMultiplier) <= WadRayMath.WAD * 2,
            Errors.INCORRECT_MULTIPLIER.selector
        );
        minPositionSizeMultiplier = _minPositionSizeMultiplier;
        emit MinPositionSizeMultiplierChanged(_minPositionSizeMultiplier);
    }

    /**
     * @inheritdoc IKeeperRewardDistributor
     */

    function setMaxGasPerPosition(
        KeeperActionType _actionType,
        KeeperActionRewardConfig calldata _config
    ) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        _setMaxGasPerPosition(_actionType, _config);
    }

    function setDataLengthRestrictions(
        KeeperCallingMethod _callingMethod,
        uint256 _maxRoutesLength,
        uint256 _baseLength
    ) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        DataLengthRestrictions storage restrictions = dataLengthRestrictions[_callingMethod];
        restrictions.maxRoutesLength = _maxRoutesLength;
        restrictions.baseLength = _baseLength;
        emit DataLengthRestrictionsChanged(_callingMethod, _maxRoutesLength, _baseLength);
    }

    /**
     * @inheritdoc IKeeperRewardDistributor
     */
    function setDefaultMaxGasPrice(uint256 _defaultMaxGasPrice) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        defaultMaxGasPrice = _defaultMaxGasPrice;
        emit DefaultMaxGasPriceChanged(_defaultMaxGasPrice);
    }

    /**
     * @inheritdoc IKeeperRewardDistributor
     */
    function setOracleGasPriceTolerance(
        uint256 _oracleGasPriceTolerance
    ) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        oracleGasPriceTolerance = _oracleGasPriceTolerance;
        emit OracleGasPriceToleranceChanged(_oracleGasPriceTolerance);
    }

    /**
     * @inheritdoc IKeeperRewardDistributor
     */
    function setPmxPartInReward(uint256 _pmxPartInReward) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        _require(_pmxPartInReward <= TEN_WAD, Errors.INCORRECT_PART_IN_REWARD.selector);
        pmxPartInReward = _pmxPartInReward;
        emit PmxPartInRewardChanged(_pmxPartInReward);
    }

    /**
     * @inheritdoc IKeeperRewardDistributor
     */
    function setNativePartInReward(uint256 _nativePartInReward) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        _require(_nativePartInReward <= TEN_WAD, Errors.INCORRECT_PART_IN_REWARD.selector);
        nativePartInReward = _nativePartInReward;
        emit NativePartInRewardChanged(_nativePartInReward);
    }

    /**
     * @inheritdoc IKeeperRewardDistributor
     */
    function setPositionSizeCoefficients(
        uint256 _positionSizeCoefficientA,
        int256 _positionSizeCoefficientB
    ) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        positionSizeCoefficientA = _positionSizeCoefficientA;
        positionSizeCoefficientB = _positionSizeCoefficientB;
        emit PositionSizeCoefficientsChanged(_positionSizeCoefficientA, _positionSizeCoefficientB);
    }

    /**
     * @inheritdoc IKeeperRewardDistributor
     */
    function setAdditionalGas(uint256 _additionalGas) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        additionalGas = _additionalGas;
        emit AdditionalGasChanged(_additionalGas);
    }

    /**
     * @inheritdoc IPausable
     */
    function pause() external override onlyRole(EMERGENCY_ADMIN) {
        _pause();
    }

    /**
     * @inheritdoc IPausable
     */
    function unpause() external override onlyRole(SMALL_TIMELOCK_ADMIN) {
        _unpause();
    }

    /**
     * @notice Interface checker
     * @param _interfaceId The interface id to check
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IKeeperRewardDistributorV2).interfaceId ||
            _interfaceId == type(IKeeperRewardDistributor).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    function _setMaxGasPerPosition(KeeperActionType _actionType, KeeperActionRewardConfig calldata _config) internal {
        maxGasPerPosition[_actionType] = _config;
        emit MaxGasPerPositionChanged(_actionType, _config);
    }

    function _setDecreasingGasByReason(DecreasingReason _reason, uint256 _amount) internal {
        decreasingGasByReason[_reason] = _amount;
        emit DecreasingGasByReasonChanged(_reason, _amount);
    }

    function _pureGasSpent(
        uint256 _totalGasSpent,
        uint256[] calldata _decreasingCounter
    ) internal view returns (uint256) {
        if (_decreasingCounter.length == 0) return _totalGasSpent;
        uint256 decreaseAmount;
        for (uint256 i; i < _decreasingCounter.length; ++i) {
            if (_decreasingCounter[i] > 0)
                decreaseAmount += _decreasingCounter[i] * decreasingGasByReason[DecreasingReason(i)];
        }
        return _totalGasSpent > decreaseAmount ? _totalGasSpent - decreaseAmount : 0;
    }

    function _getMaxGasAmount(KeeperActionType _actionType, uint256 _numberOfActions) internal view returns (uint256) {
        // at the moment the number of actions to open by order is always 1
        if (_actionType == KeeperActionType.OpenByOrder) return maxGasPerPosition[_actionType].multiplier1;
        KeeperActionRewardConfig storage config = maxGasPerPosition[_actionType];
        if (config.inflectionPoint == 0 || config.inflectionPoint > _numberOfActions)
            return config.baseMaxGas1 + config.multiplier1 * _numberOfActions;
        // We apply the multiplier2  only if numberOfActions >= inflectionPoint
        return config.baseMaxGas2 + config.multiplier2 * _numberOfActions;
    }
}
