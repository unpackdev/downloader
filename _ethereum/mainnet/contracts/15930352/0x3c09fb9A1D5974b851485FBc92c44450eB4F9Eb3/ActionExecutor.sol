// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import "./ITokenMint.sol";
import "./IVault.sol";
import "./ISettings.sol";
import "./IRegistry.sol";
import "./IGateway.sol";
import "./IGatewayClient.sol";
import "./IVariableTokenRecords.sol";
import "./IActionDataStructures.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./CallerGuard.sol";
import "./BalanceManagement.sol";
import "./Errors.sol";


contract ActionExecutor is
    Pausable,
    ReentrancyGuard,
    CallerGuard,
    BalanceManagement,
    IGatewayClient,
    ISettings,
    IActionDataStructures
{

    error OnlyGatewayError();
    error OnlySelfError();

    error SameTokenError();
    error SameChainIdError();

    error VaultNotSetError();
    error GatewayNotSetError();
    error RouterNotSetError();

    error TargetSwapInfoError();
    error SwapAmountMinError();
    error SwapAmountMaxError();
    error SwapError();

    error VariableTokenClaimFeeError();
    error VariableTokenNotSetError();

    IRegistry public registry;
    IVariableTokenRecords public variableTokenRecords;

    uint256 private constant DECIMALS_DEFAULT = 18;
    uint256 private constant INFINITY = type(uint256).max;
    uint256 private constant MILLIPERCENT_FACTOR = 1e5;

    uint256 private lastActionId = block.chainid * 1e7 + 555 ** 2;

    event ActionSource(
        uint256 indexed actionId,
        uint256 indexed targetChainId,
        address indexed sourceSender,
        address targetRecipient,
        uint256 gatewayType,
        address sourceToken,
        address targetToken,
        uint256 amount,
        uint256 fee,
        uint256 timestamp
    );

    event ActionTarget(
        uint256 indexed actionId,
        uint256 indexed sourceChainId,
        bool indexed isSuccess
    );

    event ActionFallback(
        uint256 indexed actionId,
        uint256 indexed targetChainId
    );

    event SourceProcessed(
        uint256 indexed actionId,
        bool indexed isLocal,
        address indexed sender,
        uint256 routerType,
        address fromTokenAddress,
        address toTokenAddress,
        uint256 fromAmount,
        uint256 resultAmount
    );

    event TargetProcessed(
        uint256 indexed actionId,
        address indexed recipient,
        uint256 routerType,
        address fromTokenAddress,
        address toTokenAddress,
        uint256 fromAmount,
        uint256 resultAmount
    );

    event VariableTokenAllocated(
        uint256 indexed actionId,
        bool indexed isTargetChain,
        address indexed tokenRecipient,
        uint256 vaultType,
        uint256 tokenAmount
    );

    constructor(
        IRegistry _registry,
        IVariableTokenRecords _variableTokenRecords,
        address _ownerAddress,
        bool _grantManagerRoleToOwner
    ) {
        _setRegistry(_registry);
        _setVariableTokenRecords(_variableTokenRecords);

        _initRoles(_ownerAddress, _grantManagerRoleToOwner);
    }

    modifier onlyGateway {
        if (!registry.isGatewayAddress(msg.sender)) {
            revert OnlyGatewayError();
        }

        _;
    }

    modifier onlySelf {
        if (msg.sender != address(this)) {
            revert OnlySelfError();
        }

        _;
    }

    receive() external payable {
    }

    fallback() external {
    }

    function setRegistry(IRegistry _registry) external onlyManager {
        _setRegistry(_registry);
    }

    function setVariableTokenRecords(IVariableTokenRecords _variableTokenRecords) external onlyManager {
        _setVariableTokenRecords(_variableTokenRecords);
    }

    function executeLocal(LocalAction calldata _localAction)
        external
        payable
        nonReentrant
        checkCaller
        whenNotPaused
        returns (uint256 actionId)
    {
        if (_localAction.fromTokenAddress == _localAction.toTokenAddress) {
            revert SameTokenError();
        }

        uint256 initialBalance = address(this).balance - msg.value;

        lastActionId++;
        actionId = lastActionId;

        LocalSettings memory settings = registry.localSettings(
            msg.sender,
            _localAction.swapInfo.routerType
        );

        uint256 processedAmount = _processSource(
            actionId,
            true,
            _localAction.fromTokenAddress,
            _localAction.toTokenAddress,
            _localAction.swapInfo,
            settings.router
        );

        address recipient =
            _localAction.recipient == address(0) ?
                msg.sender :
                _localAction.recipient;

        uint256 recipientAmount = _calculateLocalAmount(
            processedAmount,
            true,
            settings.systemFee,
            settings.isWhitelist
        );

        if (_localAction.toTokenAddress == NATIVE_TOKEN_ADDRESS) {
            safeTransferNative(recipient, recipientAmount);
        } else {
            safeTransfer(_localAction.toTokenAddress, recipient, recipientAmount);
        }

        // - - - System fee transfer - - -

        uint256 systemFeeAmount = processedAmount - recipientAmount;

        if (systemFeeAmount > 0) {
            address feeCollector = settings.feeCollectorLocal;

            if (feeCollector != address(0)) {
                if (_localAction.toTokenAddress == NATIVE_TOKEN_ADDRESS) {
                    safeTransferNative(feeCollector, systemFeeAmount);
                } else {
                    safeTransfer(_localAction.toTokenAddress, feeCollector, systemFeeAmount);
                }
            } else if (_localAction.toTokenAddress == NATIVE_TOKEN_ADDRESS) {
                initialBalance += systemFeeAmount; // Keep at the contract address
            }
        }

        // - - -

        // - - - Extra balance transfer - - -

        _transferExtraBalance(initialBalance);

        // - - -
    }

    function execute(Action calldata _action)
        external
        payable
        nonReentrant
        checkCaller
        whenNotPaused
        returns (uint256 actionId)
    {
        if (_action.targetChainId == block.chainid) {
            revert SameChainIdError();
        }

        uint256 initialBalance = address(this).balance - msg.value;

        lastActionId++;
        actionId = lastActionId;

        SourceSettings memory settings = registry.sourceSettings(
            msg.sender,
            _action.targetChainId,
            _action.gatewayType,
            _action.sourceSwapInfo.routerType,
            _action.vaultType
        );

        if (settings.vault == address(0)) {
            revert VaultNotSetError();
        }

        address vaultAsset = IVault(settings.vault).asset();

        uint256 processedAmount = _processSource(
            actionId,
            false,
            _action.sourceTokenAddress,
            vaultAsset,
            _action.sourceSwapInfo,
            settings.router
        );

        uint256 targetVaultAmountMax = _calculateVaultAmount(
            settings.sourceVaultDecimals,
            settings.targetVaultDecimals,
            processedAmount,
            true,
            settings.systemFee,
            settings.isWhitelist
        );

        SwapInfo memory targetSwapInfo;

        uint256 targetOptionsLength = _action.targetSwapInfoOptions.length;

        if (targetOptionsLength == 0) {
            targetSwapInfo = SwapInfo({
                fromAmount: targetVaultAmountMax,
                routerType: uint256(0),
                routerData: new bytes(0)
            });
        } else {
            for (uint256 index; index < targetOptionsLength; index++) {
                SwapInfo memory targetSwapInfoOption = _action.targetSwapInfoOptions[index];

                if (targetSwapInfoOption.fromAmount <= targetVaultAmountMax) {
                    targetSwapInfo = targetSwapInfoOption;

                    break;
                }
            }

            if (targetSwapInfo.fromAmount == 0) {
                revert TargetSwapInfoError();
            }
        }

        uint256 sourceVaultAmount = _convertDecimals(
            settings.targetVaultDecimals,
            settings.sourceVaultDecimals,
            targetSwapInfo.fromAmount
        );

        uint256 normalizedAmount = _convertDecimals(
             settings.sourceVaultDecimals,
             DECIMALS_DEFAULT,
             sourceVaultAmount
        );

        _checkSwapAmountLimits(
            normalizedAmount,
            settings.swapAmountMin,
            settings.swapAmountMax
        );

        // - - - Transfer to vault - - -

        safeTransfer(vaultAsset, settings.vault, sourceVaultAmount);

        // - - -

        address targetRecipient =
            _action.targetRecipient == address(0) ?
                msg.sender :
                _action.targetRecipient;

        bytes memory targetMessageData = abi.encode(
            TargetMessage({
                actionId: actionId,
                sourceSender: msg.sender,
                vaultType: _action.vaultType,
                targetTokenAddress: _action.targetTokenAddress,
                targetSwapInfo: targetSwapInfo,
                targetRecipient: targetRecipient
            })
        );

        _sendMessage(
            settings,
            _action.targetChainId,
            targetMessageData
        );

        // - - - System fee transfer - - -

        uint256 systemFeeAmount = processedAmount - sourceVaultAmount;

        if (systemFeeAmount > 0 && settings.feeCollector != address(0)) {
            safeTransfer(vaultAsset, settings.feeCollector, systemFeeAmount);
        }

        // - - -

        // - - - Extra balance transfer - - -

        _transferExtraBalance(initialBalance);

        // - - -

        _emitActionSourceEvent(
            actionId,
            _action,
            normalizedAmount,
            _convertDecimals(
                settings.sourceVaultDecimals,
                DECIMALS_DEFAULT,
                systemFeeAmount
            )
        );
    }

    function claimVariableToken(uint256 _vaultType) external payable nonReentrant checkCaller {
        _processVariableTokenClaim(_vaultType, false);
    }

    function convertVariableTokenToVaultAsset(uint256 _vaultType) external payable nonReentrant checkCaller {
        _processVariableTokenClaim(_vaultType, true);
    }

    function messageFeeEstimate(
        uint256 _gatewayType,
        uint256 _targetChainId,
        bytes[] calldata _targetRouterDataOptions
    )
        external
        view
        returns (uint256)
    {
        if (_targetChainId == block.chainid) {
            return 0;
        }

        MessageFeeEstimateSettings memory settings = registry.messageFeeEstimateSettings(_gatewayType);

        if (settings.gateway == address(0)) {
            revert GatewayNotSetError();
        }

        uint256 result = 0;

        for (uint256 index; index < _targetRouterDataOptions.length; index++) {
            bytes calldata targetRouterData = _targetRouterDataOptions[index];

            bytes memory messageData = abi.encode(
                TargetMessage({
                    actionId: uint256(0),
                    sourceSender: address(0),
                    vaultType: uint256(0),
                    targetTokenAddress: address(0),
                    targetSwapInfo: SwapInfo({
                        fromAmount: uint256(0),
                        routerType: uint256(0),
                        routerData: targetRouterData
                    }),
                    targetRecipient: address(0)
                })
            );

            uint256 value = IGateway(settings.gateway).messageFee(_targetChainId, messageData.length);

            if (value > result) {
                result = value;
            }
        }

        return result;
    }

    function variableTokenFeeAmount(address _account, uint256 _vaultType) external view returns (uint256) {
        uint256 fallbackFee = registry.fallbackFee();
        (, uint256 fallbackCount) = variableTokenRecords.getAccountState(_account, _vaultType);

        return fallbackFee * fallbackCount;
    }

    function calculateLocalAmount(uint256 _fromAmount, bool _isForward) external view returns (uint256 result) {
        LocalAmountCalculationSettings memory settings =
            registry.localAmountCalculationSettings(msg.sender);

        return _calculateLocalAmount(
            _fromAmount,
            _isForward,
            settings.systemFee,
            settings.isWhitelist
        );
    }

    function calculateVaultAmount(
        uint256 _vaultType,
        uint256 _fromChainId,
        uint256 _toChainId,
        uint256 _fromAmount,
        bool _isForward
    )
        external
        view
        returns (uint256 result)
    {
        VaultAmountCalculationSettings memory settings =
            registry.vaultAmountCalculationSettings(
                msg.sender,
                _vaultType,
                _fromChainId,
                _toChainId
            );

        return _calculateVaultAmount(
            settings.fromDecimals,
            settings.toDecimals,
            _fromAmount,
            _isForward,
            settings.systemFee,
            settings.isWhitelist
        );
    }

    function variableTokenBalance(address _account, uint256 _vaultType) public view returns (uint256) {
        (uint256 balance, ) = variableTokenRecords.getAccountState(_account, _vaultType);

        return balance;
    }

    function handleExecutionPayload(
        uint256 _messageSourceChainId,
        bytes calldata _payloadData
    )
        external
        onlyGateway
        whenNotPaused
        returns (bool success, bytes memory result)
    {
        TargetMessage memory targetMessage = abi.decode(_payloadData, (TargetMessage));

        TargetSettings memory settings =
            registry.targetSettings(
                targetMessage.vaultType,
                targetMessage.targetSwapInfo.routerType
            );

        bool selfCallSuccess;
        bytes memory selfCallResult;

        try this.selfCallTarget(settings, targetMessage) {
            selfCallSuccess = true;
        } catch Error(string memory reason) {
            (selfCallSuccess, selfCallResult) = (false, bytes(reason));
        } catch {
            (selfCallSuccess, selfCallResult) = (false, "failed-call");
        }

        if (!selfCallSuccess) {
            _targetAllocateVariableToken(targetMessage);
        }

        emit ActionTarget(targetMessage.actionId, _messageSourceChainId, selfCallSuccess);

        return (true, "");
    }

    function handleFallbackPayload(
        uint256 _messageTargetChainId,
        bytes calldata _payloadData
    )
        external
        onlyGateway
        whenNotPaused
    {
        TargetMessage memory targetMessage = abi.decode(_payloadData, (TargetMessage));

        FallbackSettings memory settings = registry.fallbackSettings(_messageTargetChainId, targetMessage.vaultType);

        _fallbackAllocateVariableToken(settings, targetMessage);

        emit ActionFallback(targetMessage.actionId, _messageTargetChainId);
    }

    function selfCallTarget(TargetSettings calldata settings, TargetMessage calldata _targetMessage) external onlySelf {
        if (settings.vault == address(0)) {
            revert VaultNotSetError();
        }

        // - - - Transfer from vault - - -

        address assetAddress =
            IVault(settings.vault).requestAsset(
                _targetMessage.targetSwapInfo.fromAmount,
                address(this),
                false
            );

        // - - -

        _processTarget(
            settings,
            _targetMessage.actionId,
            assetAddress,
            _targetMessage.targetTokenAddress,
            _targetMessage.targetSwapInfo,
            _targetMessage.targetRecipient
        );
    }

    function _processSource(
        uint256 _actionId,
        bool _isLocal,
        address _fromTokenAddress,
        address _toTokenAddress,
        SwapInfo memory _sourceSwapInfo,
        address _routerAddress
    )
        private
        returns (uint256 resultAmount)
    {
        uint256 toTokenBalanceBefore = tokenBalance(_toTokenAddress);

        if (_fromTokenAddress == NATIVE_TOKEN_ADDRESS) {
            if (_routerAddress == address(0)) {
                revert RouterNotSetError();
            }

            // - - - Source swap (native token) - - -

            (bool routerCallSuccess, ) =
                payable(_routerAddress).call{value: _sourceSwapInfo.fromAmount}(_sourceSwapInfo.routerData);

            if (!routerCallSuccess) {
                revert SwapError();
            }

            // - - -
        } else {
            safeTransferFrom(_fromTokenAddress, msg.sender, address(this), _sourceSwapInfo.fromAmount);

            if (_fromTokenAddress != _toTokenAddress) {
                if (_routerAddress == address(0)) {
                    revert RouterNotSetError();
                }

                // - - - Source swap (non-native token) - - -

                safeApprove(_fromTokenAddress, _routerAddress, _sourceSwapInfo.fromAmount);

                (bool routerCallSuccess, ) = _routerAddress.call(_sourceSwapInfo.routerData);

                if (!routerCallSuccess) {
                    revert SwapError();
                }

                safeApprove(_fromTokenAddress, _routerAddress, 0);

                // - - -
            }
        }

        resultAmount = tokenBalance(_toTokenAddress) - toTokenBalanceBefore;

        emit SourceProcessed(
            _actionId,
            _isLocal,
            msg.sender,
            _sourceSwapInfo.routerType,
            _fromTokenAddress,
            _toTokenAddress,
            _sourceSwapInfo.fromAmount,
            resultAmount
        );
    }

    function _processTarget(
        TargetSettings memory settings,
        uint256 _actionId,
        address _fromTokenAddress,
        address _toTokenAddress,
        SwapInfo memory _targetSwapInfo,
        address _targetRecipient
    )
        private
    {
        uint256 resultAmount;

        if (_toTokenAddress == _fromTokenAddress) {
            resultAmount = _targetSwapInfo.fromAmount;
        } else {
            if (settings.router == address(0)) {
                revert RouterNotSetError();
            }

            uint256 toTokenBalanceBefore = tokenBalance(_toTokenAddress);

            // - - - Target swap - - -

            safeApprove(_fromTokenAddress, settings.router, _targetSwapInfo.fromAmount);

            (bool success, ) = settings.router.call(_targetSwapInfo.routerData);

            if (!success) {
                revert SwapError();
            }

            safeApprove(_fromTokenAddress, settings.router, 0);

            // - - -

            resultAmount = tokenBalance(_toTokenAddress) - toTokenBalanceBefore;
        }

        if (_toTokenAddress == NATIVE_TOKEN_ADDRESS) {
            safeTransferNative(_targetRecipient, resultAmount);
        } else {
            safeTransfer(_toTokenAddress, _targetRecipient, resultAmount);
        }

        emit TargetProcessed(
            _actionId,
            _targetRecipient,
            _targetSwapInfo.routerType,
            _fromTokenAddress,
            _toTokenAddress,
            _targetSwapInfo.fromAmount,
            resultAmount
        );
    }

    function _targetAllocateVariableToken(TargetMessage memory _targetMessage) private {
        address tokenRecipient = _targetMessage.targetRecipient;
        uint256 vaultType = _targetMessage.vaultType;
        uint256 tokenAmount = _targetMessage.targetSwapInfo.fromAmount;

        variableTokenRecords.increaseBalance(
            tokenRecipient,
            vaultType,
            tokenAmount,
            false
        );

        emit VariableTokenAllocated(
            _targetMessage.actionId,
            true,
            tokenRecipient,
            vaultType,
            tokenAmount
        );
    }

    function _fallbackAllocateVariableToken(FallbackSettings memory _settings, TargetMessage memory _targetMessage) private {
        address tokenRecipient = _targetMessage.sourceSender;
        uint256 vaultType = _targetMessage.vaultType;

        uint256 tokenAmount = _convertDecimals(
            _settings.targetVaultDecimals,
            _settings.sourceVaultDecimals,
            _targetMessage.targetSwapInfo.fromAmount
        );

        variableTokenRecords.increaseBalance(
            tokenRecipient,
            vaultType,
            tokenAmount,
            true
        );

        emit VariableTokenAllocated(
            _targetMessage.actionId,
            false,
            tokenRecipient,
            vaultType,
            tokenAmount
        );
    }

    function _processVariableTokenClaim(uint256 _vaultType, bool _convertToVaultAsset) private {
        VariableTokenClaimSettings memory settings = registry.variableTokenClaimSettings(_vaultType);

        if (settings.vault == address(0)) {
            revert VaultNotSetError();
        }

        (uint256 tokenAmount, uint256 fallbackCount) =
            variableTokenRecords.getAccountState(msg.sender, _vaultType);

        uint256 feeAmount = settings.fallbackFee * fallbackCount;

        if (msg.value < feeAmount) {
            revert VariableTokenClaimFeeError();
        }

        uint256 initialBalance = address(this).balance - msg.value;

        // - - - Fallback fee transfer

        if (feeAmount > 0) {
            address feeCollector = settings.feeCollectorForVariableToken;

            if (feeCollector != address(0)) {
                safeTransferNative(feeCollector, feeAmount);
            } else {
                initialBalance += feeAmount; // Keep at the contract address
            }
        }

        // - - -

        variableTokenRecords.clearBalance(msg.sender, _vaultType);

        if (tokenAmount > 0) {
            if (_convertToVaultAsset) {
                IVault(settings.vault).requestAsset(
                    tokenAmount,
                    msg.sender,
                    true
                );
            } else {
                address variableTokenAddress = IVault(settings.vault).variableToken();

                if (variableTokenAddress == address(0)) {
                    revert VariableTokenNotSetError();
                }

                ITokenMint(variableTokenAddress).mint(msg.sender, tokenAmount);
            }
        }

        // - - - Extra balance transfer - - -

        _transferExtraBalance(initialBalance);

        // - - -
    }

    function _setRegistry(IRegistry _registry) private {
        if (address(_registry) == address(0)) {
            revert ZeroAddressError();
        }

        registry = _registry;
    }

    function _setVariableTokenRecords(IVariableTokenRecords _variableTokenRecords) private {
        if (address(_variableTokenRecords) == address(0)) {
            revert ZeroAddressError();
        }

        variableTokenRecords = _variableTokenRecords;
    }

    function _initRoles(address _ownerAddress, bool _grantManagerRoleToOwner) private {
        address ownerAddress =
            _ownerAddress == address(0) ?
                msg.sender :
                _ownerAddress;

        if (_grantManagerRoleToOwner) {
            setManager(ownerAddress, true);
        }

        if (ownerAddress != msg.sender) {
            transferOwnership(ownerAddress);
        }
    }

    function _sendMessage(SourceSettings memory settings, uint256 _targetChainId, bytes memory _messageData) private {
        if (settings.gateway == address(0)) {
            revert GatewayNotSetError();
        }

        uint256 messageFee = IGateway(settings.gateway).messageFee(_targetChainId, _messageData.length);

        IGateway(settings.gateway).sendMessage{value: messageFee}(
            _targetChainId,
            _messageData,
            settings.useGatewayFallback
        );
    }

    function _transferExtraBalance(uint256 _initialBalance) private {
        uint256 extraBalance = address(this).balance - _initialBalance;

        if (extraBalance > 0) {
            safeTransferNativeUnchecked(msg.sender, extraBalance);
        }
    }

    function _emitActionSourceEvent(
        uint256 _actionId,
        Action calldata _action,
        uint256 _amount,
        uint256 _fee
    )
        private
    {
        emit ActionSource(
            _actionId,
            _action.targetChainId,
            msg.sender,
            _action.targetRecipient,
            _action.gatewayType,
            _action.sourceTokenAddress,
            _action.targetTokenAddress,
            _amount,
            _fee,
            block.timestamp
        );
    }

    function _checkSwapAmountLimits(uint256 _normalizedAmount, uint256 _swapAmountMin, uint256 _swapAmountMax) private pure {
        if (_normalizedAmount < _swapAmountMin) {
            revert SwapAmountMinError();
        }

        if (_normalizedAmount > _swapAmountMax) {
            revert SwapAmountMaxError();
        }
    }

    function _calculateLocalAmount(
        uint256 _fromAmount,
        bool _isForward,
        uint256 _systemFee,
        bool _isWhitelist
    )
        private
        pure
        returns (uint256 result)
    {
        if (_isWhitelist || _systemFee == 0) {
            return _fromAmount;
        }

        return _isForward ?
            _fromAmount * (MILLIPERCENT_FACTOR - _systemFee) / MILLIPERCENT_FACTOR :
            _fromAmount *  MILLIPERCENT_FACTOR / (MILLIPERCENT_FACTOR - _systemFee);
    }

    function _calculateVaultAmount(
        uint256 _fromDecimals,
        uint256 _toDecimals,
        uint256 _fromAmount,
        bool _isForward,
        uint256 _systemFee,
        bool _isWhitelist
    )
        private
        pure
        returns (uint256 result)
    {
        bool isZeroFee = _isWhitelist || _systemFee == 0;

        uint256 amountToConvert =
            (!_isForward || isZeroFee) ?
                _fromAmount :
                _fromAmount * (MILLIPERCENT_FACTOR - _systemFee) / MILLIPERCENT_FACTOR;

        uint256 convertedAmount = _convertDecimals(
            _fromDecimals,
            _toDecimals,
            amountToConvert
        );

        result =
            (_isForward || isZeroFee) ?
                convertedAmount :
                convertedAmount * MILLIPERCENT_FACTOR / (MILLIPERCENT_FACTOR - _systemFee);
    }

    function _convertDecimals(
        uint256 _fromDecimals,
        uint256 _toDecimals,
        uint256 _fromAmount
    )
        private
        pure
        returns (uint256)
    {
        if (_toDecimals == _fromDecimals) {
            return _fromAmount;
        } else if (_toDecimals > _fromDecimals) {
            return _fromAmount * 10 ** (_toDecimals - _fromDecimals);
        } else {
            return _fromAmount / 10 ** (_fromDecimals - _toDecimals);
        }
    }
}