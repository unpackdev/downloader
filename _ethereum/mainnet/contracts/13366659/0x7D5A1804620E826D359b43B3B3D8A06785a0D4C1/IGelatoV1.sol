// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity >=0.6.10;
pragma experimental ABIEncoderV2;

import "./IGelatoCore.sol";

// TaskSpec - Will be whitelised by providers and selected by users
struct TaskSpec {
    IGelatoCondition[] conditions; // Address: optional AddressZero for self-conditional actions
    Action[] actions;
    uint256 gasPriceCeil;
}

interface IGelatoV1 {
    /// @notice API to query whether Task can be submitted successfully.
    /// @dev In submitTask the msg.sender must be the same as _userProxy here.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _userProxy The userProxy from which the task will be submitted.
    /// @param _task Selected provider, conditions, actions, expiry date of the task
    function canSubmitTask(
        address _userProxy,
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    ) external view returns (string memory);

    /// @notice API to submit a single Task.
    /// @dev You can let users submit multiple tasks at once by batching calls to this.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task A Gelato Task object: provider, conditions, actions.
    /// @param _expiryDate From then on the task cannot be executed. 0 for infinity.
    function submitTask(
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    ) external;

    /// @notice A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
    ///  the next one, after they have been executed.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _tasks This can be a single task or a sequence of tasks.
    /// @param _expiryDate  After this no task of the sequence can be executed any more.
    /// @param _cycles How many full cycles will be submitted
    function submitTaskCycle(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    ) external;

    /// @notice A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
    ///  the next one, after they have been executed.
    /// @dev CAUTION: _sumOfRequestedTaskSubmits does not mean the number of cycles.
    /// @dev If _sumOfRequestedTaskSubmits = 1 && _tasks.length = 2, only the first task
    ///  would be submitted, but not the second
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _tasks This can be a single task or a sequence of tasks.
    /// @param _expiryDate  After this no task of the sequence can be executed any more.
    /// @param _sumOfRequestedTaskSubmits The TOTAL number of Task auto-submits
    ///  that should have occured once the cycle is complete:
    ///  _sumOfRequestedTaskSubmits = 0 => One Task will resubmit the next Task infinitly
    ///  _sumOfRequestedTaskSubmits = 1 => One Task will resubmit no other task
    ///  _sumOfRequestedTaskSubmits = 2 => One Task will resubmit 1 other task
    ///  ...
    function submitTaskChain(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    ) external;

    // ================  Exec Suite =========================
    /// @notice Off-chain API for executors to check, if a TaskReceipt is executable
    /// @dev GelatoCore checks this during execution, in order to safeguard the Conditions
    /// @param _TR TaskReceipt, consisting of user task, user proxy address and id
    /// @param _gasLimit Task.selfProviderGasLimit is used for SelfProviders. All other
    ///  Providers must use gelatoMaxGas. If the _gasLimit is used by an Executor and the
    ///  tx reverts, a refund is paid by the Provider and the TaskReceipt is annulated.
    /// @param _execTxGasPrice Must be used by Executors. Gas Price fed by gelatoCore's
    ///  Gas Price Oracle. Executors can query the current gelatoGasPrice from events.
    function canExec(
        TaskReceipt calldata _TR,
        uint256 _gasLimit,
        uint256 _execTxGasPrice
    ) external view returns (string memory);

    /// @notice Executors call this when Conditions allow it to execute submitted Tasks.
    /// @dev Executors get rewarded for successful Execution. The Task remains open until
    ///   successfully executed, or when the execution failed, despite of gelatoMaxGas usage.
    ///   In the latter case Executors are refunded by the Task Provider.
    /// @param _TR TaskReceipt: id, userProxy, Task.
    function exec(TaskReceipt calldata _TR) external;

    /// @notice Cancel task
    /// @dev Callable only by userProxy or selected provider
    /// @param _TR TaskReceipt: id, userProxy, Task.
    function cancelTask(TaskReceipt calldata _TR) external;

    /// @notice Cancel multiple tasks at once
    /// @dev Callable only by userProxy or selected provider
    /// @param _taskReceipts TaskReceipts: id, userProxy, Task.
    function multiCancelTasks(TaskReceipt[] calldata _taskReceipts) external;

    /// @notice Compute hash of task receipt
    /// @param _TR TaskReceipt, consisting of user task, user proxy address and id
    /// @return hash of taskReceipt
    function hashTaskReceipt(TaskReceipt calldata _TR)
        external
        pure
        returns (bytes32);

    // ================  Getters =========================
    /// @notice Returns the taskReceiptId of the last TaskReceipt submitted
    /// @return currentId currentId, last TaskReceiptId submitted
    function currentTaskReceiptId() external view returns (uint256);

    /// @notice Returns computed taskReceipt hash, used to check for taskReceipt validity
    /// @param _taskReceiptId Id of taskReceipt emitted in submission event
    /// @return hash of taskReceipt
    function taskReceiptHash(uint256 _taskReceiptId)
        external
        view
        returns (bytes32);

    /// @notice Stake on Gelato to become a whitelisted executor
    /// @dev Msg.value has to be >= minExecutorStake
    function stakeExecutor() external payable;

    /// @notice Unstake on Gelato to become de-whitelisted and withdraw minExecutorStake
    function unstakeExecutor() external;

    /// @notice Re-assigns multiple providers to other executors
    /// @dev Executors must re-assign all providers before being able to unstake
    /// @param _providers List of providers to re-assign
    /// @param _newExecutor Address of new executor to assign providers to
    function multiReassignProviders(
        address[] calldata _providers,
        address _newExecutor
    ) external;

    /// @notice Withdraw excess Execur Stake
    /// @dev Can only be called if executor is isExecutorMinStaked
    /// @param _withdrawAmount Amount to withdraw
    /// @return Amount that was actually withdrawn
    function withdrawExcessExecutorStake(uint256 _withdrawAmount)
        external
        returns (uint256);

    // =========== GELATO PROVIDER APIs ==============

    /// @notice Validation that checks whether Task Spec is being offered by the selected provider
    /// @dev Checked in submitTask(), unless provider == userProxy
    /// @param _provider Address of selected provider
    /// @param _taskSpec Task Spec
    /// @return Expected to return "OK"
    function isTaskSpecProvided(address _provider, TaskSpec calldata _taskSpec)
        external
        view
        returns (string memory);

    /// @notice Validates that provider has provider module whitelisted + conducts isProvided check in ProviderModule
    /// @dev Checked in submitTask() if provider == userProxy
    /// @param _userProxy userProxy passed by GelatoCore during submission and exec
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task Task defined in IGelatoCore
    /// @return Expected to return "OK"
    function providerModuleChecks(
        address _userProxy,
        Provider calldata _provider,
        Task calldata _task
    ) external view returns (string memory);

    /// @notice Validate if provider module and seleced TaskSpec is whitelisted by provider
    /// @dev Combines "isTaskSpecProvided" and providerModuleChecks
    /// @param _userProxy userProxy passed by GelatoCore during submission and exec
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task Task defined in IGelatoCore
    /// @return res Expected to return "OK"
    function isTaskProvided(
        address _userProxy,
        Provider calldata _provider,
        Task calldata _task
    ) external view returns (string memory res);

    /// @notice Validate if selected TaskSpec is whitelisted by provider and that current gelatoGasPrice is below GasPriceCeil
    /// @dev If gasPriceCeil is != 0, Task Spec is whitelisted
    /// @param _userProxy userProxy passed by GelatoCore during submission and exec
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task Task defined in IGelatoCore
    /// @param _gelatoGasPrice Task Receipt defined in IGelatoCore
    /// @return res Expected to return "OK"
    function providerCanExec(
        address _userProxy,
        Provider calldata _provider,
        Task calldata _task,
        uint256 _gelatoGasPrice
    ) external view returns (string memory res);

    // =========== PROVIDER STATE WRITE APIs ==============
    // Provider Funding
    /// @notice Deposit ETH as provider on Gelato
    /// @param _provider Address of provider who receives ETH deposit
    function provideFunds(address _provider) external payable;

    /// @notice Withdraw provider funds from gelato
    /// @param _withdrawAmount Amount
    /// @return amount that will be withdrawn
    function unprovideFunds(uint256 _withdrawAmount) external returns (uint256);

    /// @notice Assign executor as provider
    /// @param _executor Address of new executor
    function providerAssignsExecutor(address _executor) external;

    /// @notice Assign executor as previous selected executor
    /// @param _provider Address of provider whose executor to change
    /// @param _newExecutor Address of new executor
    function executorAssignsExecutor(address _provider, address _newExecutor)
        external;

    // (Un-)provide Task Spec

    /// @notice Whitelist TaskSpecs (A combination of a Condition, Action(s) and a gasPriceCeil) that users can select from
    /// @dev If gasPriceCeil is == 0, Task Spec will be executed at any gas price (no ceil)
    /// @param _taskSpecs Task Receipt List defined in IGelatoCore
    function provideTaskSpecs(TaskSpec[] calldata _taskSpecs) external;

    /// @notice De-whitelist TaskSpecs (A combination of a Condition, Action(s) and a gasPriceCeil) that users can select from
    /// @dev If gasPriceCeil was set to NO_CEIL, Input NO_CEIL constant as GasPriceCeil
    /// @param _taskSpecs Task Receipt List defined in IGelatoCore
    function unprovideTaskSpecs(TaskSpec[] calldata _taskSpecs) external;

    /// @notice Update gasPriceCeil of selected Task Spec
    /// @param _taskSpecHash Result of hashTaskSpec()
    /// @param _gasPriceCeil New gas price ceil for Task Spec
    function setTaskSpecGasPriceCeil(
        bytes32 _taskSpecHash,
        uint256 _gasPriceCeil
    ) external;

    // Provider Module
    /// @notice Whitelist new provider Module(s)
    /// @param _modules Addresses of the modules which will be called during providerModuleChecks()
    function addProviderModules(IGelatoProviderModule[] calldata _modules)
        external;

    /// @notice De-Whitelist new provider Module(s)
    /// @param _modules Addresses of the modules which will be removed
    function removeProviderModules(IGelatoProviderModule[] calldata _modules)
        external;

    // Batch (un-)provide

    /// @notice Whitelist new executor, TaskSpec(s) and Module(s) in one tx
    /// @param _executor Address of new executor of provider
    /// @param _taskSpecs List of Task Spec which will be whitelisted by provider
    /// @param _modules List of module addresses which will be whitelisted by provider
    function multiProvide(
        address _executor,
        TaskSpec[] calldata _taskSpecs,
        IGelatoProviderModule[] calldata _modules
    ) external payable;

    /// @notice De-Whitelist TaskSpec(s), Module(s) and withdraw funds from gelato in one tx
    /// @param _withdrawAmount Amount to withdraw from ProviderFunds
    /// @param _taskSpecs List of Task Spec which will be de-whitelisted by provider
    /// @param _modules List of module addresses which will be de-whitelisted by provider
    function multiUnprovide(
        uint256 _withdrawAmount,
        TaskSpec[] calldata _taskSpecs,
        IGelatoProviderModule[] calldata _modules
    ) external;

    // =========== PROVIDER STATE READ APIs ==============
    // Provider Funding

    /// @notice Get balance of provider
    /// @param _provider Address of provider
    /// @return Provider Balance
    function providerFunds(address _provider) external view returns (uint256);

    /// @notice Get min stake required by all providers for executors to call exec
    /// @param _gelatoMaxGas Current gelatoMaxGas
    /// @param _gelatoGasPrice Current gelatoGasPrice
    /// @return How much provider balance is required for executor to submit exec tx
    function minExecProviderFunds(
        uint256 _gelatoMaxGas,
        uint256 _gelatoGasPrice
    ) external view returns (uint256);

    /// @notice Check if provider has sufficient funds for executor to call exec
    /// @param _provider Address of provider
    /// @param _gelatoMaxGas Currentt gelatoMaxGas
    /// @param _gelatoGasPrice Current gelatoGasPrice
    /// @return Whether provider is liquid (true) or not (false)
    function isProviderLiquid(
        address _provider,
        uint256 _gelatoMaxGas,
        uint256 _gelatoGasPrice
    ) external view returns (bool);

    // Executor Stake

    /// @notice Get balance of executor
    /// @param _executor Address of executor
    /// @return Executor Balance
    function executorStake(address _executor) external view returns (uint256);

    /// @notice Check if executor has sufficient stake on gelato
    /// @param _executor Address of provider
    /// @return Whether executor has sufficient stake (true) or not (false)
    function isExecutorMinStaked(address _executor)
        external
        view
        returns (bool);

    /// @notice Get executor of provider
    /// @param _provider Address of provider
    /// @return Provider's executor
    function executorByProvider(address _provider)
        external
        view
        returns (address);

    /// @notice Get num. of providers which haved assigned an executor
    /// @param _executor Address of executor
    /// @return Count of how many providers assigned the executor
    function executorProvidersCount(address _executor)
        external
        view
        returns (uint256);

    /// @notice Check if executor has one or more providers assigned
    /// @param _executor Address of provider
    /// @return Where 1 or more providers have assigned the executor
    function isExecutorAssigned(address _executor) external view returns (bool);

    // Task Spec and Gas Price Ceil
    /// @notice The maximum gas price the transaction will be executed with
    /// @param _provider Address of provider
    /// @param _taskSpecHash Hash of provider TaskSpec
    /// @return Max gas price an executor will execute the transaction with in wei
    function taskSpecGasPriceCeil(address _provider, bytes32 _taskSpecHash)
        external
        view
        returns (uint256);

    /// @notice Returns the hash of the formatted TaskSpec.
    /// @dev The action.data field of each Action is stripped before hashing.
    /// @param _taskSpec TaskSpec
    /// @return keccak256 hash of encoded condition address and Action List
    function hashTaskSpec(TaskSpec calldata _taskSpec)
        external
        view
        returns (bytes32);

    /// @notice Constant used to specify the highest gas price available in the gelato system
    /// @dev Input 0 as gasPriceCeil and it will be assigned to NO_CEIL
    /// @return MAX_UINT
    function NO_CEIL() external pure returns (uint256);

    // Providers' Module Getters

    /// @notice Check if inputted module is whitelisted by provider
    /// @param _provider Address of provider
    /// @param _module Address of module
    /// @return true if it is whitelisted
    function isModuleProvided(address _provider, IGelatoProviderModule _module)
        external
        view
        returns (bool);

    /// @notice Get all whitelisted provider modules from a given provider
    /// @param _provider Address of provider
    /// @return List of whitelisted provider modules
    function providerModules(address _provider)
        external
        view
        returns (IGelatoProviderModule[] memory);

    // State Writing

    /// @notice Assign new gas price oracle
    /// @dev Only callable by sysAdmin
    /// @param _newOracle Address of new oracle
    function setGelatoGasPriceOracle(address _newOracle) external;

    /// @notice Assign new gas price oracle
    /// @dev Only callable by sysAdmin
    /// @param _requestData The encoded payload for the staticcall to the oracle.
    function setOracleRequestData(bytes calldata _requestData) external;

    /// @notice Assign new maximum gas limit providers can consume in executionWrapper()
    /// @dev Only callable by sysAdmin
    /// @param _newMaxGas New maximum gas limit
    function setGelatoMaxGas(uint256 _newMaxGas) external;

    /// @notice Assign new interal gas limit requirement for exec()
    /// @dev Only callable by sysAdmin
    /// @param _newRequirement New internal gas requirement
    function setInternalGasRequirement(uint256 _newRequirement) external;

    /// @notice Assign new minimum executor stake
    /// @dev Only callable by sysAdmin
    /// @param _newMin New minimum executor stake
    function setMinExecutorStake(uint256 _newMin) external;

    /// @notice Assign new success share for executors to receive after successful execution
    /// @dev Only callable by sysAdmin
    /// @param _percentage New % success share of total gas consumed
    function setExecutorSuccessShare(uint256 _percentage) external;

    /// @notice Assign new success share for sysAdmin to receive after successful execution
    /// @dev Only callable by sysAdmin
    /// @param _percentage New % success share of total gas consumed
    function setSysAdminSuccessShare(uint256 _percentage) external;

    /// @notice Withdraw sysAdmin funds
    /// @dev Only callable by sysAdmin
    /// @param _amount Amount to withdraw
    /// @param _to Address to receive the funds
    function withdrawSysAdminFunds(uint256 _amount, address payable _to)
        external
        returns (uint256);

    // State Reading
    /// @notice Unaccounted tx overhead that will be refunded to executors
    function EXEC_TX_OVERHEAD() external pure returns (uint256);

    /// @notice Addess of current Gelato Gas Price Oracle
    function gelatoGasPriceOracle() external view returns (address);

    /// @notice Getter for oracleRequestData state variable
    function oracleRequestData() external view returns (bytes memory);

    /// @notice Gas limit an executor has to submit to get refunded even if actions revert
    function gelatoMaxGas() external view returns (uint256);

    /// @notice Internal gas limit requirements ti ensure executor payout
    function internalGasRequirement() external view returns (uint256);

    /// @notice Minimum stake required from executors
    function minExecutorStake() external view returns (uint256);

    /// @notice % Fee executors get as a reward for a successful execution
    function executorSuccessShare() external view returns (uint256);

    /// @notice Total % Fee executors and sysAdmin collectively get as a reward for a successful execution
    /// @dev Saves a state read
    function totalSuccessShare() external view returns (uint256);

    /// @notice Get total fee providers pay executors for a successful execution
    /// @param _gas Gas consumed by transaction
    /// @param _gasPrice Current gelato gas price
    function executorSuccessFee(uint256 _gas, uint256 _gasPrice)
        external
        view
        returns (uint256);

    /// @notice % Fee sysAdmin gets as a reward for a successful execution
    function sysAdminSuccessShare() external view returns (uint256);

    /// @notice Get total fee providers pay sysAdmin for a successful execution
    /// @param _gas Gas consumed by transaction
    /// @param _gasPrice Current gelato gas price
    function sysAdminSuccessFee(uint256 _gas, uint256 _gasPrice)
        external
        view
        returns (uint256);

    /// @notice Get sysAdminds funds
    function sysAdminFunds() external view returns (uint256);
}

/// @title IGelatoCondition - solidity interface of GelatoConditionsStandard
/// @notice all the APIs of GelatoConditionsStandard
/// @dev all the APIs are implemented inside GelatoConditionsStandard
interface IGelatoCondition {
    /// @notice GelatoCore calls this to verify securely the specified Condition securely
    /// @dev Be careful only to encode a Task's condition.data as is and not with the
    ///  "ok" selector or _taskReceiptId, since those two things are handled by GelatoCore.
    /// @param _taskReceiptId This is passed by GelatoCore so we can rely on it as a secure
    ///  source of Task identification.
    /// @param _conditionData This is the Condition.data field developers must encode their
    ///  Condition's specific parameters in.
    /// @param _cycleId For Tasks that are executed as part of a cycle.
    function ok(
        uint256 _taskReceiptId,
        bytes calldata _conditionData,
        uint256 _cycleId
    ) external view returns (string memory);
}

/// @notice all the APIs and events of GelatoActionsStandard
/// @dev all the APIs are implemented inside GelatoActionsStandard
interface IGelatoAction {
    /// @notice Providers can use this for pre-execution sanity checks, to prevent reverts.
    /// @dev GelatoCore checks this in canExec and passes the parameters.
    /// @param _taskReceiptId The id of the task from which all arguments are passed.
    /// @param _userProxy The userProxy of the task. Often address(this) for delegatecalls.
    /// @param _actionData The encoded payload to be used in the Action.
    /// @param _dataFlow The dataFlow of the Action.
    /// @param _value A special param for ETH sending Actions. If the Action sends ETH
    ///  in its Action function implementation, one should expect msg.value therein to be
    ///  equal to _value. So Providers can check in termsOk that a valid ETH value will
    ///  be used because they also have access to the same value when encoding the
    ///  execPayload on their ProviderModule.
    /// @param _cycleId For tasks that are part of a Cycle.
    /// @return Returns OK, if Task can be executed safely according to the Provider's
    ///  terms laid out in this function implementation.
    function termsOk(
        uint256 _taskReceiptId,
        address _userProxy,
        bytes calldata _actionData,
        DataFlow _dataFlow,
        uint256 _value,
        uint256 _cycleId
    ) external view returns (string memory);
}

interface IGelatoProviderModule {
    /// @notice Check if provider agrees to pay for inputted task receipt
    /// @dev Enables arbitrary checks by provider
    /// @param _userProxy The smart contract account of the user who submitted the Task.
    /// @param _provider The account of the Provider who uses the ProviderModule.
    /// @param _task Gelato Task to be executed.
    /// @return "OK" if provider agrees
    function isProvided(
        address _userProxy,
        address _provider,
        Task calldata _task
    ) external view returns (string memory);

    /// @notice Convert action specific payload into proxy specific payload
    /// @dev Encoded multiple actions into a multisend
    /// @param _taskReceiptId Unique ID of Gelato Task to be executed.
    /// @param _userProxy The smart contract account of the user who submitted the Task.
    /// @param _provider The account of the Provider who uses the ProviderModule.
    /// @param _task Gelato Task to be executed.
    /// @param _cycleId For Tasks that form part of a cycle/chain.
    /// @return Encoded payload that will be used for low-level .call on user proxy
    /// @return checkReturndata if true, fwd returndata from userProxy.call to ProviderModule
    function execPayload(
        uint256 _taskReceiptId,
        address _userProxy,
        address _provider,
        Task calldata _task,
        uint256 _cycleId
    ) external view returns (bytes memory, bool checkReturndata);

    /// @notice Called by GelatoCore.exec to verifiy that no revert happend on userProxy
    /// @dev If a caught revert is detected, this fn should revert with the detected error
    /// @param _proxyReturndata Data from GelatoCore._exec.userProxy.call(execPayload)
    function execRevertCheck(bytes calldata _proxyReturndata) external pure;
}
