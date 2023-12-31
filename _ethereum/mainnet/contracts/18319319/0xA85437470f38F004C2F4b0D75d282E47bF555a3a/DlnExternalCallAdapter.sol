// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./DlnOrderLib.sol";
import "./DlnExternalCallLib.sol";
import "./IExternalCallExecutor.sol";
import "./BytesLib.sol";
import "./IExternalCallAdapter.sol";

contract DlnExternalCallAdapter is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IExternalCallAdapter
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using BytesLib for bytes;

    /* ========== STATE VARIABLES ========== */

    address public dlnDestination;

    /// @dev Default executor for external calls, used when specific executor addresses are not provided.
    IExternalCallExecutor public defaultExecutor;

    /// @dev Stores the status of each external call, identified by a unique bytes32 call ID.
    ///      The status is represented by the CallStatus enum.
    mapping(bytes32 => CallStatus) public externalCallStatus;

    /// @dev Records the historical balance of tokens (including Ether) for this contract.
    ///      The key is the token address, with address(0) representing Ether.
    mapping(address => uint256) public tokenBalanceHistory;

    /* ========== ENUMS ========== */

    /**
     * @dev Enumerates the possible states of an external call.
     *      - NotSet (0): Initial state, indicating no status is set yet.
     *      - Created (1): Call has been created but not yet executed.
     *      - Executed (2): Call has been successfully executed.
     *      - Cancelled (3): Call has been cancelled.
     */
    enum CallStatus {
        NotSet, // 0
        Created, // 1
        Executed, // 2
        Cancelled // 3
    }

    /* ========== ERRORS ========== */

    error AdminBadRole();
    error DlnBadRole();
    error BadRole();
    error InvalideState();
    error InvalideAmount();
    error IncorrectExecutionFee(uint256 amount, uint256 executionFee);
    error EthTransferFailed();
    error UnknownEnvelopeVersion(uint8 version);
    error DisabledDelayedExecution();
    error FailedExecuteExternalCall();

    /* ========== EVENTS ========== */

    event ExternallCallRegistered(
        bytes32 callId,
        bytes32 orderId,
        address callAuthority,
        address tokenAddress,
        uint256 amount,
        bytes externalCall
    );
    event ExecutorUpdated(address oldExecutor, address newExecutor);
    event ExternalCallExecuted(bytes32 orderId, bool callSucceeded);
    event ExternalCallFailed(bytes32 orderId, bytes callResult);

    event ExternalCallCancelled(
        bytes32 callId,
        bytes32 orderId,
        address cancelBeneficiary,
        address tokenAddress,
        uint256 amount
    );

    /* ========== MODIFIERS ========== */

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert AdminBadRole();
        _;
    }

    modifier onlyDlnDestination() {
        if (dlnDestination != msg.sender) revert DlnBadRole();
        _;
    }

    /* ========== CONSTRUCTOR  ========== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _dlnDestination,
        address _executor
    ) public initializer {
        dlnDestination = _dlnDestination;
        _setExecutor(_executor);
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /* ========== PUBLIC METHODS ========== */

    /**
     * @notice Callback method invoked after the order has been fulfilled by the taker.
     * @param _orderId Hash of the order being processed
     * @param _callAuthority Address that can cancel external call and send tokens to fallback address
     * @param _tokenAddress  Token that was transferred to adapter
     * @param _transferredAmount Actual amount that was transferred to adapter
     * @param _externalCall Data for the external call.
     * @param _externalCallRewardBeneficiary Address to receive the execution fee;
     *    if set to address(0), external call will not be executed.
     *
     * # Functionality
     * - Validates the transferred amount and ensures the token balance has increased accordingly.
     * - Registers external calls if no reward beneficiary is set, otherwise executes them immediately.
     * - Emits an event for registered external calls.
     * - Reverts transaction on invalid amount or state inconsistencies.
     */
    function receiveCall(
        bytes32 _orderId,
        address _callAuthority,
        address _tokenAddress,
        uint256 _transferredAmount,
        bytes calldata _externalCall,
        address _externalCallRewardBeneficiary
    ) external nonReentrant whenNotPaused onlyDlnDestination {
        // check that balance changed on takingAmount
        uint256 balanceNow = _getBalance(_tokenAddress);
        if (
            balanceNow - tokenBalanceHistory[_tokenAddress] < _transferredAmount
        ) {
            revert InvalideState();
        }

        // registrate external call
        if (_externalCallRewardBeneficiary == address(0)) {
            _checkAllowDelayedExecution(_externalCall);
            bytes32 callId = getCallId(
                _orderId,
                _callAuthority,
                _tokenAddress,
                _transferredAmount,
                _externalCall
            );
            if (externalCallStatus[callId] != CallStatus.NotSet)
                revert InvalideState(); // impossible situation
            tokenBalanceHistory[_tokenAddress] = balanceNow;
            externalCallStatus[callId] = CallStatus.Created;
            emit ExternallCallRegistered(
                callId,
                _orderId,
                _callAuthority,
                _tokenAddress,
                _transferredAmount,
                _externalCall
            );
        }
        // execute external call if reward beneficiary is set
        else {
            _execute(
                _orderId,
                _tokenAddress,
                _transferredAmount,
                _externalCall,
                _externalCallRewardBeneficiary
            );
        }
    }

    /**
     * @dev Executes external calls related to an order.
     *
     * @param _orderId Unique identifier of the order.
     * @param _callAuthority Address that can cancel external call and send tokens to fallback address
     * @param _tokenAddress Token involved in the transaction.
     * @param _tokenAmount Amount of token used.
     * @param _externalCall Data for the external call.
     * @param _rewardBeneficiary Address receiving execution fee.
     *
     * Error Handling:
     * - Reverts if the call status is not set to 'Created'.
     */
    function executeCall(
        bytes32 _orderId,
        address _callAuthority,
        address _tokenAddress,
        uint256 _tokenAmount,
        bytes calldata _externalCall,
        address _rewardBeneficiary
    ) external nonReentrant whenNotPaused {
        bytes32 callId = getCallId(
            _orderId,
            _callAuthority,
            _tokenAddress,
            _tokenAmount,
            _externalCall
        );

        if (externalCallStatus[callId] != CallStatus.Created)
            revert InvalideState();

        _execute(
            _orderId,
            _tokenAddress,
            _tokenAmount,
            _externalCall,
            _rewardBeneficiary
        );
        externalCallStatus[callId] = CallStatus.Executed;
    }

    /**
     * @dev Cancels a previously created external call and refunds the associated funds.
     *
     * @param _orderId`: Unique identifier of the order.
     * @param _callAuthority`: Address that can cancel external call and send tokens to fallback address
     * @param _tokenAddress`: Address of the token involved in the call.
     * @param _tokenAmount`: Amount of the token to be refunded.
     * @param _recipient`: Address to receive the refunded tokens.
     * @param _externalCallHash`: Hash of the external call data.
     *
     * Functionality:
     * - Validates sender's authority for cancellation.
     * - Generates a unique call ID and checks if the call is in a 'Created' state.
     * - Refunds tokens to the specified recipient.
     * - Updates call status to 'Cancelled'.
     * - Emits an `ExternalCallCancelled` event with relevant details.
     *
     * Error Handling:
     * - Reverts if the sender is not the authorized call authority.
     * - Reverts if the call status is not set to 'Created'.
     */
    function cancelCall(
        bytes32 _orderId,
        address _callAuthority,
        address _tokenAddress,
        uint256 _tokenAmount,
        address _recipient,
        bytes32 _externalCallHash
    ) external nonReentrant whenNotPaused {
        if (msg.sender != _callAuthority) revert BadRole();
        bytes32 callId = getCallId(
            _orderId,
            _callAuthority,
            _tokenAddress,
            _tokenAmount,
            _externalCallHash
        );

        if (externalCallStatus[callId] != CallStatus.Created)
            revert InvalideState();

        _sendToken(_tokenAddress, _tokenAmount, _recipient);

        externalCallStatus[callId] = CallStatus.Cancelled;
        emit ExternalCallCancelled(
            callId,
            _orderId,
            _recipient,
            _tokenAddress,
            _tokenAmount
        );
    }

    receive() external payable onlyDlnDestination {}

    /* ========== ADMIN METHODS ========== */

    /**
     * @dev Updates the default executor address.
     *
     * @param _newExecutor The address of the new executor.
     *
     * Modifiers:
     * - `onlyAdmin`: Ensures that only an admin can call this function.
     *
     */
    function updateExecutor(address _newExecutor) external onlyAdmin {
        _setExecutor(_newExecutor);
    }

    /* ========== INTERNAL ========== */

    /**
     * @dev Internal function to process the execution of external calls.
     *
     * @param _orderId Unique identifier of the order.
     * @param _tokenAddress Token involved in the transaction.
     * @param _tokenAmount Amount of token used.
     * @param _externalCall Data for the external call.
     * @param _rewardBeneficiary Address receiving execution fee.
     *
     * Functionality:
     * - Parses and validates envelope data.
     * - Manages token transactions and execution fees.
     * - Chooses and executes call via correct executor.
     * - Updates token balance history.
     * - Emits events based on execution status.
     *
     * Error Handling:
     * - Reverts on incorrect fee, failed execution, or unknown envelope version.
     * - Emits failure event if external call execution fails.
     */
    function _execute(
        bytes32 _orderId,
        address _tokenAddress,
        uint256 _tokenAmount,
        bytes memory _externalCall,
        address _rewardBeneficiary
    ) internal {
        (uint8 envelopeVersion, bytes memory envelopData)= _getEnvelopeData(_externalCall);
        bool executionStatus;
        bytes memory callResult;
        if (envelopeVersion == 1) {
            DlnExternalCallLib.ExternalCallEnvelopV1 memory dataEnvelope = abi.decode(
                envelopData,
                (DlnExternalCallLib.ExternalCallEnvelopV1)
            );
            // pay execution fee
            if (_tokenAmount >= dataEnvelope.executionFee) {
                if (dataEnvelope.executionFee > 0) {
                    _tokenAmount = _tokenAmount - dataEnvelope.executionFee;
                    _sendToken(
                        _tokenAddress,
                        dataEnvelope.executionFee,
                        _rewardBeneficiary
                    );
                }
            }
            // if incorrect execution fee
            else {
                revert IncorrectExecutionFee(
                    _tokenAmount,
                    dataEnvelope.executionFee
                );
            }
            IExternalCallExecutor currentExecutor = dataEnvelope.executorAddress == address(0) 
                                                 ? defaultExecutor
                                                 : IExternalCallExecutor(dataEnvelope.executorAddress);

            // call external
            if (_tokenAddress == address(0)) {
                (executionStatus, callResult) = currentExecutor.onEtherReceived{
                    value: _tokenAmount
                }(_orderId, dataEnvelope.fallbackAddress, dataEnvelope.payload);
            } else {
                _sendToken(
                    _tokenAddress,
                    _tokenAmount,
                    address(currentExecutor)
                );
                (executionStatus, callResult) = currentExecutor.onERC20Received(
                    _orderId,
                    _tokenAddress,
                    _tokenAmount,
                    dataEnvelope.fallbackAddress,
                    dataEnvelope.payload
                );
            }
            if (dataEnvelope.requireSuccessfullExecution && !executionStatus)
                revert FailedExecuteExternalCall();
        } else {
            revert UnknownEnvelopeVersion(envelopeVersion);
        }

        tokenBalanceHistory[_tokenAddress] = _getBalance(_tokenAddress);
        emit ExternalCallExecuted(_orderId, executionStatus);
        // Emit an event if the external call failed, including the callResult.
        if (!executionStatus) {
            emit ExternalCallFailed(_orderId, callResult);
        }
    }

    /**
     * @dev Validates if delayed execution is allowed for a given external call.
     *
     * @param _externalCall The raw bytes of the external call data.
     *
     * Functionality:
     * - Extracts the envelope version and data from the external call.
     * - Decodes the data based on the envelope version.
     * - For version 1, checks if delayed execution is permitted.
     * - Reverts if delayed execution is not allowed or if the envelope version is unknown.
     *
     * Error Handling:
     * - Reverts with `DisabledDelayedExecution` if delayed execution is disabled in the data envelope.
     * - Reverts with `UnknownEnvelopeVersion` if the envelope version is not recognized.
     *
     */
    function _checkAllowDelayedExecution(
        bytes memory _externalCall
    ) internal pure {
        (uint8 envelopeVersion, bytes memory envelopData) = _getEnvelopeData(
            _externalCall
        );
        if (envelopeVersion == 1) {
            DlnExternalCallLib.ExternalCallEnvelopV1 memory dataEnvelope = abi.decode(
                envelopData,
                (DlnExternalCallLib.ExternalCallEnvelopV1)
            );
            if (!dataEnvelope.allowDelayedExecution) {
                revert DisabledDelayedExecution();
            }
        } else {
            revert UnknownEnvelopeVersion(envelopeVersion);
        }
    }

    /**
     * @dev Extracts the envelope version and data from a given external call.
     *
     * @param _externalCall The raw bytes of the external call data.
     *
     * @return envelopeVersion The version number of the envelope extracted from the call data.
     * @return envelopData The remaining data in the envelope after removing the version byte.
     *
     */
    function _getEnvelopeData(
        bytes memory _externalCall
    ) internal pure returns (uint8 envelopeVersion, bytes memory envelopData) {
        envelopeVersion = BytesLib.toUint8(_externalCall, 0);
        // Remove first byte from data
        envelopData = BytesLib.slice(
            _externalCall,
            1,
            _externalCall.length - 1
        );
    }

    /**
     * @dev Internal function that sets a new executor and emits an event.
     *
     * @param _newExecutor The address of the new executor.
     *
     * Functionality:
     * - Updates the `defaultExecutor` to the new executor address.
     * - Emits `ExecutorUpdated` event with the old and new executor addresses.
     *
     */
    function _setExecutor(address _newExecutor) internal {
        address oldExecutor = address(defaultExecutor);
        defaultExecutor = IExternalCallExecutor(_newExecutor);
        emit ExecutorUpdated(oldExecutor, address(defaultExecutor));
    }

    /**
     * @dev Retrieves the balance of the given token for this contract.
     *
     * @param _tokenAddress The address of the token. If address(0), it refers to Ether.
     *
     * @return The balance of the token (or Ether) held by the contract.
     *
     * Functionality:
     * - If `_tokenAddress` is address(0), returns the Ether balance of the contract.
     * - Otherwise, returns the balance of the specified ERC20 token for this contract.
     *
     */
    function _getBalance(
        address _tokenAddress
    ) internal view returns (uint256) {
        if (_tokenAddress == address(0)) {
            return address(this).balance;
        } else {
            return IERC20Upgradeable(_tokenAddress).balanceOf(address(this));
        }
    }

    /**
     * @dev Transfers a specified amount of tokens (or Ether) to a receiver.
     *
     * @param _tokenAddress The address of the token to transfer. If address(0), it refers to Ether.
     * @param _amount The amount of tokens (or Ether) to transfer.
     * @param _receiver The address of the recipient.
     *
     * Functionality:
     * - If `_tokenAddress` is address(0), transfers Ether using `_safeTransferETH`.
     * - Otherwise, transfers the specified ERC20 token using `safeTransfer`.
     *
     */
    function _sendToken(
        address _tokenAddress,
        uint256 _amount,
        address _receiver
    ) internal {
        if (_tokenAddress == address(0)) {
            _safeTransferETH(_receiver, _amount);
        } else {
            IERC20Upgradeable(_tokenAddress).safeTransfer(_receiver, _amount);
        }
    }

    /**
     * @dev Generates a unique identifier (call ID) for an external call.
     *
     * @param _orderId Unique identifier of the order.
     * @param _callAuthority Address that can cancel external call and send tokens to fallback address
     * @param _tokenAddress Address of the token involved in the transaction.
     * @param _transferredAmount Amount of the token that was transferred.
     * @param _externalCall Raw bytes of the external call data.
     * @return  A bytes32 hash representing the unique call ID.
     *
     */
    function getCallId(
        bytes32 _orderId,
        address _callAuthority,
        address _tokenAddress,
        uint256 _transferredAmount,
        bytes memory _externalCall
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _orderId,
                    _callAuthority,
                    _tokenAddress,
                    _transferredAmount,
                    keccak256(_externalCall)
                )
            );
    }

    /**
     * @dev Generates a unique identifier (call ID) for an external call.
     *
     * @param _orderId Unique identifier of the order.
     * @param _callAuthority Address that can cancel external call and send tokens to fallback address
     * @param _tokenAddress Address of the token involved in the transaction.
     * @param _transferredAmount Amount of the token that was transferred.
     * @param _externalCallHash Hash of external call data.
     * @return  A bytes32 hash representing the unique call ID.
     *
     */
    function getCallId(
        bytes32 _orderId,
        address _callAuthority,
        address _tokenAddress,
        uint256 _transferredAmount,
        bytes32 _externalCallHash
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _orderId,
                    _callAuthority,
                    _tokenAddress,
                    _transferredAmount,
                    _externalCallHash
                )
            );
    }

    /**
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (!success) revert EthTransferFailed();
    }

    /* ========== Version Control ========== */

    /**
     * @dev Returns the current version of the contract.
     *
     * @return The version number of the contract as a string.
     *
     */
    function version() external pure returns (string memory) {
        return "1.0.1";
    }
}
