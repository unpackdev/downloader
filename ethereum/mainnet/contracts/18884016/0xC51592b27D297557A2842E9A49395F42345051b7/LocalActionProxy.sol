// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import "./IActionDataStructures.sol";
import "./BalanceManagement.sol";
import "./CallerGuard.sol";
import "./Pausable.sol";
import "./SystemVersionId.sol";
import "./Errors.sol";
import '../helpers/AddressHelper.sol' as AddressHelper;
import '../helpers/RefundHelper.sol' as RefundHelper;
import '../helpers/TransferHelper.sol' as TransferHelper;
import '../Constants.sol' as Constants;

/**
 * @title LocalActionProxy
 * @notice Local action proxy contract
 */
contract LocalActionProxy is
    SystemVersionId,
    Pausable,
    CallerGuard,
    BalanceManagement,
    IActionDataStructures
{
    /**
     * @dev The address of the action executor contract
     */
    ILocalActionExecutor public actionExecutor;

    /**
     * @dev The address of the fee collector
     */
    address public feeCollector;

    /**
     * @notice Emitted when the action executor contract reference is set
     * @param actionExecutor The action executor contract address
     */
    event SetActionExecutor(address indexed actionExecutor);

    /**
     * @notice Emitted when the address of the fee collector is set
     * @param feeCollector The address of the fee collector
     */
    event SetFeeCollector(address indexed feeCollector);

    /**
     * @notice Emitted when the extra balance is refunded
     * @param actionId The ID of the action
     * @param sender The address of the user
     */
    event LocalActionExecuted(uint256 indexed actionId, address indexed sender);

    /**
     * @notice Emitted when the extra balance is refunded
     * @param to The refund receiver's address
     * @param extraBalance The extra balance of the native token
     */
    event ExtraBalanceRefunded(address indexed to, uint256 extraBalance);

    /**
     * @notice Emitted when the native token value of the transaction does not correspond to the swap amount
     */
    error NativeTokenValueError();

    /**
     * @notice Initializes the LocalActionProxy contract
     * @param _actionExecutor The address of the action executor contract
     * @param _feeCollector The address of the fee collector
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        ILocalActionExecutor _actionExecutor,
        address _feeCollector,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) {
        _setActionExecutor(_actionExecutor);
        _setFeeCollector(_feeCollector);

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice Executes a single-chain action
     * @param _localAction The parameters of the action
     * @param _processingFee The processing fee value
     */
    function executeLocal(
        LocalAction memory _localAction,
        uint256 _processingFee
    ) external payable whenNotPaused checkCaller {
        uint256 initialBalance = address(this).balance - msg.value;

        address fromTokenAddress = _localAction.fromTokenAddress;
        uint256 fromAmount = _localAction.swapInfo.fromAmount;

        bool fromNative = fromTokenAddress == Constants.NATIVE_TOKEN_ADDRESS;

        uint256 requiredNativeTokenValue = fromNative
            ? fromAmount + _processingFee
            : _processingFee;

        if (msg.value < requiredNativeTokenValue) {
            revert NativeTokenValueError();
        }

        if (!fromNative) {
            TransferHelper.safeTransferFrom(
                fromTokenAddress,
                msg.sender,
                address(this),
                fromAmount
            );

            TransferHelper.safeApprove(fromTokenAddress, address(actionExecutor), fromAmount);
        }

        if (_localAction.recipient == address(0)) {
            _localAction.recipient = msg.sender;
        }

        uint256 actionId = actionExecutor.executeLocal{ value: fromNative ? fromAmount : 0 }(
            _localAction
        );

        emit LocalActionExecuted(actionId, msg.sender);

        if (!fromNative) {
            TransferHelper.safeApprove(fromTokenAddress, address(actionExecutor), 0);
        }

        TransferHelper.safeTransferNative(feeCollector, _processingFee);

        uint256 extraBalance = RefundHelper.refundExtraBalanceWithResult(
            address(this),
            initialBalance,
            payable(msg.sender)
        );

        if (extraBalance > 0) {
            emit ExtraBalanceRefunded(msg.sender, extraBalance);
        }
    }

    /**
     * @notice Sets the action executor contract reference
     * @param _actionExecutor The action executor contract address
     */
    function setActionExecutor(ILocalActionExecutor _actionExecutor) external onlyManager {
        _setActionExecutor(_actionExecutor);
    }

    /**
     * @notice Sets the address of the fee collector
     * @param _feeCollector The address of the fee collector
     */
    function setFeeCollector(address _feeCollector) external onlyManager {
        _setFeeCollector(_feeCollector);
    }

    function _setActionExecutor(ILocalActionExecutor _actionExecutor) private {
        AddressHelper.requireContract(address(_actionExecutor));

        actionExecutor = _actionExecutor;

        emit SetActionExecutor(address(_actionExecutor));
    }

    function _setFeeCollector(address _feeCollector) private {
        if (_feeCollector == address(0)) {
            revert ZeroAddressError();
        }

        feeCollector = _feeCollector;

        emit SetFeeCollector(_feeCollector);
    }
}

interface ILocalActionExecutor is IActionDataStructures {
    function executeLocal(
        LocalAction calldata _localAction
    ) external payable returns (uint256 actionId);
}
