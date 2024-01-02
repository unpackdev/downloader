// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import "./Strings.sol";
import "./AxelarExecutable.sol";
import "./IAxelarGasService.sol";
import "./IRootBridgeAdaptor.sol";
import "./IRootAxelarBridgeAdaptor.sol";
import "./IRootERC20Bridge.sol";
import "./AdaptorRoles.sol";

/**
 * @notice Facilitates communication between the RootERC20Bridge and the Axelar core contracts, to send and receive messages to and from the child chain.
 * @dev The contract ensures that any delivered message originated from the registered child chain and bridge adapter contract on the child chain. It will reject all other messages.
 * @dev Features:
 *      - Send messages to the child chain via the Axelar Gateway.
 *      - Receive and validate messages from the child chain via the Axelar Gateway.
 *      - Manage Role Based Access Control
 * @dev Roles:
 *      - An account with a BRIDGE_MANAGER_ROLE can update the root bridge address.
 *      - An account with a TARGET_MANAGER_ROLE can update the child chain name and the child bridge adaptor address.
 *      - An account with a GAS_SERVICE_MANAGER_ROLE can update the gas service address.
 *      - An account with a DEFAULT_ADMIN_ROLE can grant and revoke roles.
 * @dev Note:
 *      - This is an upgradeable contract that should be operated behind OpenZeppelin's TransparentUpgradeableProxy.
 *      - The initialize function is susceptible to front running, so precautions should be taken to account for this scenario.
 */
contract RootAxelarBridgeAdaptor is
    AdaptorRoles,
    AxelarExecutable,
    IRootBridgeAdaptor,
    IRootAxelarBridgeAdaptorEvents,
    IRootAxelarBridgeAdaptorErrors,
    IRootAxelarBridgeAdaptor
{
    /// @notice Address of the bridge contract on the root chain.
    IRootERC20Bridge public rootBridge;

    /// @notice Axelar's ID for the child chain. Axelar uses the chain name as the chain ID.
    string public childChainId;

    /// @notice Address of the bridge adaptor on the child chain, which this contract will communicate with.
    string public childBridgeAdaptor;

    /// @notice Address of the Axelar Gas Service contract.
    IAxelarGasService public gasService;

    /// @notice Address of the authorized initializer.
    address public immutable initializerAddress;

    /**
     * @notice Constructs the RootAxelarBridgeAdaptor contract.
     * @param _gateway The address of the Axelar gateway contract.
     * @param _initializerAddress The address of the authorized initializer.
     */
    constructor(address _gateway, address _initializerAddress) AxelarExecutable(_gateway) {
        if (_initializerAddress == address(0)) {
            revert ZeroAddresses();
        }
        initializerAddress = _initializerAddress;
    }

    /**
     * @notice Initialization function for RootAxelarBridgeAdaptor.
     * @param _adaptorRoles Struct containing addresses of roles.
     * @param _rootBridge Address of root bridge contract.
     * @param _childChainId Axelar's ID for the child chain.
     * @param _childBridgeAdaptor Address of the bridge adaptor on the child chain.
     * @param _gasService Address of Axelar Gas Service contract.
     */
    function initialize(
        InitializationRoles memory _adaptorRoles,
        address _rootBridge,
        string memory _childChainId,
        string memory _childBridgeAdaptor,
        address _gasService
    ) public initializer {
        if (msg.sender != initializerAddress) {
            revert UnauthorizedInitializer();
        }
        if (
            _rootBridge == address(0) || _gasService == address(0) || _adaptorRoles.defaultAdmin == address(0)
                || _adaptorRoles.bridgeManager == address(0) || _adaptorRoles.gasServiceManager == address(0)
                || _adaptorRoles.targetManager == address(0)
        ) {
            revert ZeroAddresses();
        }

        if (bytes(_childChainId).length == 0) {
            revert InvalidChildChain();
        }

        if (bytes(_childBridgeAdaptor).length == 0) {
            revert InvalidChildBridgeAdaptor();
        }

        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _adaptorRoles.defaultAdmin);
        _grantRole(BRIDGE_MANAGER_ROLE, _adaptorRoles.bridgeManager);
        _grantRole(GAS_SERVICE_MANAGER_ROLE, _adaptorRoles.gasServiceManager);
        _grantRole(TARGET_MANAGER_ROLE, _adaptorRoles.targetManager);

        rootBridge = IRootERC20Bridge(_rootBridge);
        childChainId = _childChainId;
        childBridgeAdaptor = _childBridgeAdaptor;
        gasService = IAxelarGasService(_gasService);
    }

    /**
     * @inheritdoc IRootAxelarBridgeAdaptor
     */
    function updateRootBridge(address newRootBridge) external override onlyRole(BRIDGE_MANAGER_ROLE) {
        if (newRootBridge == address(0)) {
            revert ZeroAddresses();
        }

        emit RootBridgeUpdated(address(rootBridge), newRootBridge);
        rootBridge = IRootERC20Bridge(newRootBridge);
    }

    /**
     * @inheritdoc IRootAxelarBridgeAdaptor
     */
    function updateChildChain(string memory newChildChain) external override onlyRole(TARGET_MANAGER_ROLE) {
        if (bytes(newChildChain).length == 0) {
            revert InvalidChildChain();
        }

        emit ChildChainUpdated(childChainId, newChildChain);
        childChainId = newChildChain;
    }

    /**
     * @inheritdoc IRootAxelarBridgeAdaptor
     */
    function updateChildBridgeAdaptor(string memory newChildBridgeAdaptor) external onlyRole(TARGET_MANAGER_ROLE) {
        if (bytes(newChildBridgeAdaptor).length == 0) {
            revert InvalidChildBridgeAdaptor();
        }
        emit ChildBridgeAdaptorUpdated(childBridgeAdaptor, newChildBridgeAdaptor);
        childBridgeAdaptor = newChildBridgeAdaptor;
    }

    /**
     * @inheritdoc IRootAxelarBridgeAdaptor
     */
    function updateGasService(address newGasService) external override onlyRole(GAS_SERVICE_MANAGER_ROLE) {
        if (newGasService == address(0)) {
            revert ZeroAddresses();
        }

        emit GasServiceUpdated(address(gasService), newGasService);
        gasService = IAxelarGasService(newGasService);
    }

    /**
     * @inheritdoc IRootBridgeAdaptor
     */
    function sendMessage(bytes calldata payload, address refundRecipient) external payable override {
        if (msg.value == 0) {
            revert NoGas();
        }
        if (msg.sender != address(rootBridge)) {
            revert CallerNotBridge();
        }

        // Load from storage.
        string memory _childBridgeAdaptor = childBridgeAdaptor;
        string memory _childChain = childChainId;

        gasService.payNativeGasForContractCall{value: msg.value}(
            address(this), _childChain, _childBridgeAdaptor, payload, refundRecipient
        );

        gateway.callContract(_childChain, _childBridgeAdaptor, payload);
        emit AxelarMessageSent(_childChain, _childBridgeAdaptor, payload);
    }

    /**
     * @dev This function is called by the parent `AxelarExecutable` contract to execute a message payload sent from the child chain.
     *      It is only called after the message has been validated by the Axelar core contracts.
     *      Validations include, ensuring that the Axelar validator set has signed the message and that the message has not been executed before.
     *      For more details see:
     *        - [AxelarExecutable.sol](https://github.com/axelarnetwork/axelar-cgp-solidity/blob/d4536599321774927bf9716178a9e360f8e0efac/contracts/AxelarGateway.sol#L233),
     *        - [AxelarGateway.sol](https://github.com/axelarnetwork/axelar-cgp-solidity/blob/d4536599321774927bf9716178a9e360f8e0efac/contracts/AxelarGateway.sol#L233)
     *
     * @dev The function first validates the message by checking that it originated from the registered
     *      child chain and bridge adaptor contract on the child chain. If not, the message is rejected.
     *      If a message is valid, it calls the root bridge contract's `onMessageReceive` function.
     * @param _sourceChain The chain id that the message originated from.
     * @param _sourceAddress The contract address that sent the message on the source chain.
     * @param _payload The message payload.
     * @custom:assumes `_sourceAddress` is a 20 byte address.
     */
    function _execute(string calldata _sourceChain, string calldata _sourceAddress, bytes calldata _payload)
        internal
        override
    {
        if (!Strings.equal(_sourceChain, childChainId)) {
            revert InvalidSourceChain();
        }

        if (!Strings.equal(_sourceAddress, childBridgeAdaptor)) {
            revert InvalidSourceAddress();
        }

        emit AdaptorExecute(_sourceChain, _sourceAddress, _payload);
        rootBridge.onMessageReceive(_payload);
    }

    /**
     * @inheritdoc AxelarExecutable
     * @dev This function is called by the parent `AxelarExecutable` contract's `executeWithToken()` function.
     *      However, this function is not required for the bridge, and thus reverts with an `UnsupportedOperation` error.
     */
    function _executeWithToken(string calldata, string calldata, bytes calldata, string calldata, uint256)
        internal
        pure
        override
    {
        revert UnsupportedOperation();
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gapRootAxelarBridgeAdaptor;
}
