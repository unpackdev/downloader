// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import "./ReentrancyGuard.sol";
import "./IERC165.sol";
import "./IAny2EVMMessageReceiver.sol";
import "./IRouterClient.sol";
import "./Client.sol";
import "./IActionDataStructures.sol";
import "./IGateway.sol";
import "./IGatewayClient.sol";
import "./IVariableBalanceRecords.sol";
import "./IVariableBalanceRecordsProvider.sol";
import "./GatewayBase.sol";
import "./SystemVersionId.sol";
import "./Errors.sol";
import '../../helpers/AddressHelper.sol' as AddressHelper;
import '../../helpers/GasReserveHelper.sol' as GasReserveHelper;
import '../../helpers/TransferHelper.sol' as TransferHelper;
import '../../DataStructures.sol' as DataStructures;

/**
 * @title ChainlinkCcipGateway
 * @notice The contract implementing the cross-chain messaging logic specific to Chainlink CCIP
 */
contract ChainlinkCcipGateway is
    SystemVersionId,
    GatewayBase,
    IAny2EVMMessageReceiver,
    IERC165,
    IActionDataStructures
{
    /**
     * @notice Chain ID pair structure
     * @param standardId The standard EVM chain ID
     * @param ccipId The CCIP chain selector
     */
    struct ChainIdPair {
        uint256 standardId;
        uint64 ccipId;
    }

    /**
     * @dev CCIP endpoint reference
     */
    IRouterClient public endpoint;

    /**
     * @dev Variable balance records contract reference for targetGasEstimate
     */
    IVariableBalanceRecords public variableBalanceRecords;

    /**
     * @dev Contract self-reference for targetGasEstimate
     */
    ChainlinkCcipGateway public self;

    /**
     * @dev The correspondence between standard EVM chain IDs and CCIP chain selectors
     */
    mapping(uint256 /*standardId*/ => uint64 /*ccipId*/) public standardToCcipChainId;

    /**
     * @dev The correspondence between CCIP chain selectors and standard EVM chain IDs
     */
    mapping(uint64 /*ccipId*/ => uint256 /*standardId*/) public ccipToStandardChainId;

    /**
     * @dev The default value of minimum target gas
     */
    uint256 public minTargetGasDefault;

    /**
     * @dev The custom values of minimum target gas by standard chain IDs
     */
    mapping(uint256 /*standardChainId*/ => DataStructures.OptionalValue /*minTargetGas*/)
        public minTargetGasCustom;

    /**
     * @dev The address of the processing fee collector
     */
    address public processingFeeCollector;

    address private constant ESTIMATOR_ADDRESS = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
    uint64 private constant ESTIMATE_SOURCE_CCIP_CHAIN_ID =
        uint64(uint256(keccak256('Source - CCIP Chain ID')));
    uint256 private constant ESTIMATE_SOURCE_STANDARD_CHAIN_ID =
        uint256(keccak256('Source - EVM Chain ID'));
    bytes32 private constant ESTIMATE_CCIP_MESSAGE_ID = keccak256('CCIP Message ID');
    address private constant ESTIMATE_SOURCE_ADDRESS = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

    /**
     * @notice Emitted when the cross-chain endpoint contract reference is set
     * @param endpointAddress The address of the cross-chain endpoint contract
     */
    event SetEndpoint(address indexed endpointAddress);

    /**
     * @notice Emitted when a chain ID pair is added or updated
     * @param standardId The standard EVM chain ID
     * @param ccipId The CCIP chain selector
     */
    event SetChainIdPair(uint256 indexed standardId, uint64 indexed ccipId);

    /**
     * @notice Emitted when a chain ID pair is removed
     * @param standardId The standard EVM chain ID
     * @param ccipId The CCIP chain selector
     */
    event RemoveChainIdPair(uint256 indexed standardId, uint64 indexed ccipId);

    /**
     * @notice Emitted when the default value of minimum target gas is set
     * @param minTargetGas The value of minimum target gas
     */
    event SetMinTargetGasDefault(uint256 minTargetGas);

    /**
     * @notice Emitted when the custom value of minimum target gas is set
     * @param standardChainId The standard EVM chain ID
     * @param minTargetGas The value of minimum target gas
     */
    event SetMinTargetGasCustom(uint256 standardChainId, uint256 minTargetGas);

    /**
     * @notice Emitted when the custom value of minimum target gas is removed
     * @param standardChainId The standard EVM chain ID
     */
    event RemoveMinTargetGasCustom(uint256 standardChainId);

    /**
     * @notice Emitted when the address of the processing fee collector is set
     * @param processingFeeCollector The address of the processing fee collector
     */
    event SetProcessingFeeCollector(address indexed processingFeeCollector);

    /**
     * @notice Emitted when the result info value is returned from targetGasEstimate
     * @param isSuccess The status of the action execution
     * @param gasUsed The amount of gas used
     */
    error ResultInfo(bool isSuccess, uint256 gasUsed);

    /**
     * @notice Emitted when there is no registered CCIP chain selector matching the standard EVM chain ID
     */
    error CcipChainIdNotSetError();

    /**
     * @notice Emitted when the provided target gas value is not sufficient for the message processing
     */
    error MinTargetGasError();

    /**
     * @notice Emitted when the provided call value is not sufficient for the message processing
     */
    error ProcessingFeeError();

    /**
     * @notice Emitted when the caller is not the CCIP endpoint
     */
    error OnlyEndpointError();

    /**
     * @notice Emitted when the caller is not the estimator account
     */
    error OnlyEstimatorError();

    /**
     * @dev Modifier to check if the caller is the CCIP endpoint
     */
    modifier onlyEndpointOrSelf() {
        if (msg.sender != address(endpoint) && msg.sender != address(this)) {
            revert OnlyEndpointError();
        }

        _;
    }

    /**
     * @dev Modifier to check if the caller is the estimator account
     */
    modifier onlyEstimator() {
        if (msg.sender != ESTIMATOR_ADDRESS) {
            revert OnlyEstimatorError();
        }

        _;
    }

    /**
     * @notice Deploys the ChainlinkCcipGateway contract
     * @param _endpointAddress The cross-chain endpoint address
     * @param _chainIdPairs The correspondence between standard EVM chain IDs and CCIP chain selectors
     * @param _minTargetGasDefault The default value of minimum target gas
     * @param _minTargetGasCustomData The custom values of minimum target gas by standard chain IDs
     * @param _targetGasReserve The initial gas reserve value for target chain action processing
     * @param _processingFeeCollector The initial address of the processing fee collector
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        address _endpointAddress,
        ChainIdPair[] memory _chainIdPairs,
        uint256 _minTargetGasDefault,
        DataStructures.KeyToValue[] memory _minTargetGasCustomData,
        uint256 _targetGasReserve,
        address _processingFeeCollector,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) {
        _setEndpoint(_endpointAddress);

        for (uint256 index; index < _chainIdPairs.length; index++) {
            ChainIdPair memory chainIdPair = _chainIdPairs[index];

            _setChainIdPair(chainIdPair.standardId, chainIdPair.ccipId);
        }

        _setMinTargetGasDefault(_minTargetGasDefault);

        for (uint256 index; index < _minTargetGasCustomData.length; index++) {
            DataStructures.KeyToValue memory minTargetGasCustomEntry = _minTargetGasCustomData[
                index
            ];

            _setMinTargetGasCustom(minTargetGasCustomEntry.key, minTargetGasCustomEntry.value);
        }

        _setTargetGasReserve(_targetGasReserve);

        _setProcessingFeeCollector(_processingFeeCollector);

        _initEstimate();

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice Sets the gateway client contract reference
     * @param _clientAddress The gateway client contract address
     */
    function setClient(address payable _clientAddress) external virtual override onlyManager {
        AddressHelper.requireContract(_clientAddress);

        client = IGatewayClient(_clientAddress);

        variableBalanceRecords = IVariableBalanceRecordsProvider(_clientAddress)
            .variableBalanceRecords();

        emit SetClient(_clientAddress);
    }

    /**
     * @notice Sets the cross-chain endpoint contract reference
     * @param _endpointAddress The address of the cross-chain endpoint contract
     */
    function setEndpoint(address _endpointAddress) external onlyManager {
        _setEndpoint(_endpointAddress);
    }

    /**
     * @notice Adds or updates registered chain ID pairs
     * @param _chainIdPairs The list of chain ID pairs
     */
    function setChainIdPairs(ChainIdPair[] calldata _chainIdPairs) external onlyManager {
        for (uint256 index; index < _chainIdPairs.length; index++) {
            ChainIdPair calldata chainIdPair = _chainIdPairs[index];

            _setChainIdPair(chainIdPair.standardId, chainIdPair.ccipId);
        }
    }

    /**
     * @notice Removes registered chain ID pairs
     * @param _standardChainIds The list of standard EVM chain IDs
     */
    function removeChainIdPairs(uint256[] calldata _standardChainIds) external onlyManager {
        for (uint256 index; index < _standardChainIds.length; index++) {
            uint256 standardId = _standardChainIds[index];

            _removeChainIdPair(standardId);
        }
    }

    /**
     * @notice Sets the default value of minimum target gas
     * @param _minTargetGas The value of minimum target gas
     */
    function setMinTargetGasDefault(uint256 _minTargetGas) external onlyManager {
        _setMinTargetGasDefault(_minTargetGas);
    }

    /**
     * @notice Sets the custom value of minimum target gas by the standard chain ID
     * @param _standardChainId The standard EVM ID of the target chain
     * @param _minTargetGas The value of minimum target gas
     */
    function setMinTargetGasCustom(
        uint256 _standardChainId,
        uint256 _minTargetGas
    ) external onlyManager {
        _setMinTargetGasCustom(_standardChainId, _minTargetGas);
    }

    /**
     * @notice Removes the custom value of minimum target gas by the standard chain ID
     * @param _standardChainId The standard EVM ID of the target chain
     */
    function removeMinTargetGasCustom(uint256 _standardChainId) external onlyManager {
        _removeMinTargetGasCustom(_standardChainId);
    }

    /**
     * @notice Sets the address of the processing fee collector
     * @param _processingFeeCollector The address of the processing fee collector
     */
    function setProcessingFeeCollector(address _processingFeeCollector) external onlyManager {
        _setProcessingFeeCollector(_processingFeeCollector);
    }

    /**
     * @notice Send a cross-chain message
     * @dev The settings parameter contains ABI-encoded values (targetGas, processingFee)
     * @param _targetChainId The message target chain ID
     * @param _message The message content
     * @param _settings The gateway-specific settings
     */
    function sendMessage(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external payable onlyClient whenNotPaused {
        (address peerAddress, uint64 targetCcipChainId) = _checkPeer(_targetChainId);

        (bytes memory adapterParameters, uint256 processingFee) = _checkSettings(
            _settings,
            _targetChainId
        );

        // - - - Processing fee transfer - - -

        if (msg.value < processingFee) {
            revert ProcessingFeeError();
        }

        if (processingFee > 0 && processingFeeCollector != address(0)) {
            TransferHelper.safeTransferNative(processingFeeCollector, processingFee);
        }

        // - - -

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = _createCcipMessage(
            peerAddress,
            _message,
            adapterParameters
        );

        // Send the message
        endpoint.ccipSend{ value: msg.value - processingFee }(targetCcipChainId, evm2AnyMessage);
    }

    /**
     * @notice Receives cross-chain messages
     * @dev The function is called by the cross-chain endpoint
     * @param _message The structure containing the message data
     */
    function ccipReceive(
        Client.Any2EVMMessage memory _message
    ) external override nonReentrant onlyEndpointOrSelf {
        if (paused()) {
            emit TargetPausedFailure();

            return;
        }

        if (address(client) == address(0)) {
            emit TargetClientNotSetFailure();

            return;
        }

        uint256 sourceStandardChainId = ccipToStandardChainId[_message.sourceChainSelector];

        address fromAddress = abi.decode(_message.sender, (address));

        bool condition = sourceStandardChainId != 0 &&
            fromAddress != address(0) &&
            fromAddress == peerMap[sourceStandardChainId];

        if (!condition) {
            emit TargetFromAddressFailure(sourceStandardChainId, fromAddress);

            return;
        }

        (bool hasGasReserve, uint256 gasAllowed) = GasReserveHelper.checkGasReserve(
            targetGasReserve
        );

        if (!hasGasReserve) {
            emit TargetGasReserveFailure(sourceStandardChainId);

            return;
        }

        try
            client.handleExecutionPayload{ gas: gasAllowed }(sourceStandardChainId, _message.data)
        {} catch {
            emit TargetExecutionFailure();
        }
    }

    /**
     * @notice Gas consumption estimate on the target chain
     * @param _targetMessage The content of the cross-chain message
     */
    function estimateTarget(
        TargetMessage calldata _targetMessage
    ) external onlyEstimator whenNotPaused {
        uint256 variableBalanceBefore = variableBalanceRecords.getAccountBalance(
            _targetMessage.targetRecipient,
            _targetMessage.vaultType
        );

        bytes memory payloadData = abi.encode(_targetMessage);

        Client.Any2EVMMessage memory ccipMessage = Client.Any2EVMMessage({
            messageId: ESTIMATE_CCIP_MESSAGE_ID,
            sourceChainSelector: ESTIMATE_SOURCE_CCIP_CHAIN_ID,
            sender: abi.encode(ESTIMATE_SOURCE_ADDRESS),
            data: payloadData,
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });

        uint256 gasBefore = gasleft();

        // - - - Target chain actions - - -

        self.ccipReceive(ccipMessage);

        // - - -

        uint256 gasUsed = gasBefore - gasleft();

        uint256 variableBalanceAfter = variableBalanceRecords.getAccountBalance(
            _targetMessage.targetRecipient,
            _targetMessage.vaultType
        );

        bool isSuccess = (variableBalanceAfter == variableBalanceBefore);

        revert ResultInfo(isSuccess, gasUsed);
    }

    /**
     * @notice Cross-chain message fee estimation
     * @dev The settings parameter contains ABI-encoded values (targetGas, processingFee)
     * @param _targetChainId The ID of the target chain
     * @param _message The message content
     * @param _settings The gateway-specific settings
     * @return Message fee
     */
    function messageFee(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external view returns (uint256) {
        (address peerAddress, uint64 targetCcipChainId) = _checkPeer(_targetChainId);

        (bytes memory adapterParameters, uint256 processingFee) = _checkSettings(
            _settings,
            _targetChainId
        );

        Client.EVM2AnyMessage memory ccipMessage = _createCcipMessage(
            peerAddress,
            _message,
            adapterParameters
        );

        uint256 endpointNativeFee = endpoint.getFee(targetCcipChainId, ccipMessage);

        return endpointNativeFee + processingFee;
    }

    /**
     * @notice IERC165 supports an interface ID
     * @param _interfaceId The interface ID to check
     * @return true if the interface ID is supported
     */
    function supportsInterface(bytes4 _interfaceId) external pure override returns (bool) {
        return
            _interfaceId == type(IAny2EVMMessageReceiver).interfaceId ||
            _interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @notice The value of minimum target gas by the standard chain ID
     * @param _standardChainId The standard EVM ID of the target chain
     * @return The value of minimum target gas
     */
    function minTargetGas(uint256 _standardChainId) public view returns (uint256) {
        DataStructures.OptionalValue storage optionalValue = minTargetGasCustom[_standardChainId];

        if (optionalValue.isSet) {
            return optionalValue.value;
        }

        return minTargetGasDefault;
    }

    function _setEndpoint(address _endpointAddress) private {
        AddressHelper.requireContract(_endpointAddress);

        endpoint = IRouterClient(_endpointAddress);

        emit SetEndpoint(_endpointAddress);
    }

    function _setChainIdPair(uint256 _standardId, uint64 _ccipId) private {
        standardToCcipChainId[_standardId] = _ccipId;
        ccipToStandardChainId[_ccipId] = _standardId;

        emit SetChainIdPair(_standardId, _ccipId);
    }

    function _removeChainIdPair(uint256 _standardId) private {
        uint64 ccipId = standardToCcipChainId[_standardId];

        delete standardToCcipChainId[_standardId];
        delete ccipToStandardChainId[ccipId];

        emit RemoveChainIdPair(_standardId, ccipId);
    }

    function _setMinTargetGasDefault(uint256 _minTargetGas) private {
        minTargetGasDefault = _minTargetGas;

        emit SetMinTargetGasDefault(_minTargetGas);
    }

    function _setMinTargetGasCustom(uint256 _standardChainId, uint256 _minTargetGas) private {
        minTargetGasCustom[_standardChainId] = DataStructures.OptionalValue({
            isSet: true,
            value: _minTargetGas
        });

        emit SetMinTargetGasCustom(_standardChainId, _minTargetGas);
    }

    function _removeMinTargetGasCustom(uint256 _standardChainId) private {
        delete minTargetGasCustom[_standardChainId];

        emit RemoveMinTargetGasCustom(_standardChainId);
    }

    function _setProcessingFeeCollector(address _processingFeeCollector) private {
        processingFeeCollector = _processingFeeCollector;

        emit SetProcessingFeeCollector(_processingFeeCollector);
    }

    function _checkPeer(
        uint256 _chainId
    ) private view returns (address peerAddress, uint64 ccipChainId) {
        peerAddress = peerMap[_chainId];

        if (peerAddress == address(0)) {
            revert PeerNotSetError();
        }

        ccipChainId = standardToCcipChainId[_chainId];

        if (ccipChainId == 0) {
            revert CcipChainIdNotSetError();
        }
    }

    function _checkSettings(
        bytes calldata _settings,
        uint256 _targetChainId
    ) private view returns (bytes memory adapterParameters, uint256 processingFee) {
        uint256 targetGas;
        (targetGas, processingFee) = abi.decode(_settings, (uint256, uint256));

        uint256 minTargetGasValue = minTargetGas(_targetChainId);

        if (targetGas < minTargetGasValue) {
            revert MinTargetGasError();
        }

        adapterParameters = Client._argsToBytes(
            Client.EVMExtraArgsV1({ gasLimit: targetGas, strict: false })
        );
    }

    function _createCcipMessage(
        address _peerAddress,
        bytes calldata _message,
        bytes memory _adapterParameters
    ) private pure returns (Client.EVM2AnyMessage memory) {
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_peerAddress), // ABI-encoded receiver address
                data: _message,
                tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array indicating no tokens are being sent
                extraArgs: _adapterParameters,
                feeToken: address(0) // Native token
            });
    }

    function _initEstimate() private {
        self = this;

        peerMap[ESTIMATE_SOURCE_STANDARD_CHAIN_ID] = ESTIMATE_SOURCE_ADDRESS;
        ccipToStandardChainId[ESTIMATE_SOURCE_CCIP_CHAIN_ID] = ESTIMATE_SOURCE_STANDARD_CHAIN_ID;
    }
}
