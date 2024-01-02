// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./Pausable.sol";
import "./TimelockController.sol";

import "./Errors.sol";

import "./Constants.sol";
import "./IPausable.sol";

contract PrimexTimelock is IPausable, TimelockController, Pausable {
    address public immutable registry;

    /**
     * @dev Modifier that allows only the Guardian admin to access the function.
     * Throws an error if the sender does not have the GUARDIAN_ADMIN role.
     */
    modifier onlyGuardian() {
        _require(IAccessControl(registry).hasRole(GUARDIAN_ADMIN, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    constructor(
        uint256 _minDelay,
        address[] memory _proposers,
        address[] memory _executors,
        address _admin,
        address _registry
    ) TimelockController(_minDelay, _proposers, _executors, _admin) {
        _require(
            IERC165(_registry).supportsInterface(type(IAccessControl).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        registry = _registry;
    }

    /**
     * @inheritdoc IPausable
     */
    function pause() external override onlyGuardian {
        _pause();
    }

    /**
     * @inheritdoc IPausable
     */
    function unpause() external override onlyGuardian {
        _unpause();
    }

    /**
     * @notice This function overrides a function in the parent contract.
     * @dev The function will revert with the `OPERATION_NOT_SUPPORTED` error.
     */
    function updateDelay(uint256) external pure override {
        _revert(Errors.OPERATION_NOT_SUPPORTED.selector);
    }

    /**
     * @dev Schedules a transaction to be executed in the future.
     * This function can only be called when the contract is not paused.
     * Only callable by the PROPOSER_ROLE role.
     * @param target The address of the contract to be called.
     * @param value The amount of native tokens (in wei) to be sent with the transaction.
     * @param data The data to be passed to the contract's function.
     * @param predecessor The hash of the preceding transaction in the same function.
     * @param salt A random value used as a salt for the scheduled transaction.
     * @param delay The delay, in seconds, before the transaction can be executed.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public override whenNotPaused {
        super.schedule(target, value, data, predecessor, salt, delay);
    }

    /**
     * @dev Schedules a batch of transactions to be executed after a specified delay.
     * This function can only be called when the contract is not paused.
     * Only callable by the PROPOSER_ROLE role.
     * @param targets The array of target addresses for the transactions.
     * @param values The array of values to be sent with each transaction.
     * @param payloads The array of payload data for each transaction.
     * @param predecessor The predecessor hash for the batch of transactions.
     * @param salt The salt value for generating the schedule hash.
     * @param delay The delay in seconds after which the transactions can be executed.
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public override whenNotPaused {
        super.scheduleBatch(targets, values, payloads, predecessor, salt, delay);
    }

    /**
     * @notice Cancels a specific task by its ID.
     * @dev This function can only be called by a guardian admin.
     * @param id The ID of the task to be canceled.
     */
    function cancel(bytes32 id) public override {
        bool isGuardian = IAccessControl(registry).hasRole(GUARDIAN_ADMIN, msg.sender);
        if (isGuardian) {
            _grantRole(CANCELLER_ROLE, msg.sender);
        }
        super.cancel(id);
        if (isGuardian) {
            _revokeRole(CANCELLER_ROLE, msg.sender);
        }
    }

    /**
     * @notice Executes a transaction to the specified target with the given parameters.
     * @dev This function can only be called when the contract is not paused.
     * Only callable by the EXECUTOR_ROLE role.
     * @param target The address of the contract to execute the transaction on.
     * @param value The amount of native tokens (in wei) to send along with the transaction.
     * @param payload The data payload to include in the transaction.
     * @param predecessor The predecessor of the transaction (optional).
     * @param salt The salt value to use for the transaction (optional).
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata payload,
        bytes32 predecessor,
        bytes32 salt
    ) public payable override whenNotPaused {
        super.execute(target, value, payload, predecessor, salt);
    }

    /**
     * @notice Executes a batch of transactions.
     * @dev This function can only be called when the contract is not paused.
     * Only callable by the EXECUTOR_ROLE role.
     * @param targets The array of target addresses for the transactions.
     * @param values The array of values to be sent with each transaction.
     * @param payloads The array of payload data for each transaction.
     * @param predecessor The predecessor block's hash.
     * @param salt The salt value for generating a deterministic pseudo-random address.
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public payable override whenNotPaused {
        super.executeBatch(targets, values, payloads, predecessor, salt);
    }
}
