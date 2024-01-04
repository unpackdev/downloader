// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.0;

import "./Address.sol";

// Gelato Data Types
struct Provider {
    address addr;  //  if msg.sender == provider => self-Provider
    address module;  //  e.g. DSA Provider Module
}

struct Condition {
    address inst;  // can be AddressZero for self-conditional Actions
    bytes data;  // can be bytes32(0) for self-conditional Actions
}

enum Operation { Call, Delegatecall }

enum DataFlow { None, In, Out, InAndOut }

struct Action {
    address addr;
    bytes data;
    Operation operation;
    DataFlow dataFlow;
    uint256 value;
    bool termsOkCheck;
}

struct Task {
    Condition[] conditions;  // optional
    Action[] actions;
    uint256 selfProviderGasLimit;  // optional: 0 defaults to gelatoMaxGas
    uint256 selfProviderGasPriceCeil;  // optional: 0 defaults to NO_CEIL
}

struct TaskReceipt {
    uint256 id;
    address userProxy;
    Provider provider;
    uint256 index;
    Task[] tasks;
    uint256 expiryDate;
    uint256 cycleId;  // auto-filled by GelatoCore. 0 for non-cyclic/chained tasks
    uint256 submissionsLeft;
}

struct TaskSpec {
    address[] conditions;   // Address: optional AddressZero for self-conditional actions
    Action[] actions;
    uint256 gasPriceCeil;
}

// Gelato Interface
interface IGelatoCore {

    /**
     * @dev API to submit a single Task.
    */
    function submitTask(
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    )
        external;


    /**
     * @dev A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
     * the next one, after they have been executed, where the total number of tasks can
     * be only be an even number
    */
    function submitTaskCycle(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        external;


    /**
     * @dev A Gelato Task Chain consists of 1 or more Tasks that automatically submit
     * the next one, after they have been executed, where the total number of tasks can
     * be an odd number
    */
    function submitTaskChain(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    )
        external;

    /**
     * @dev Cancel multiple tasks at once
    */
    function multiCancelTasks(TaskReceipt[] calldata _taskReceipts) external;

    /**
     * @dev Whitelist new executor, TaskSpec(s) and Module(s) in one tx
    */
    function multiProvide(
        address _executor,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules
    )
        external
        payable;


    /**
     * @dev De-Whitelist TaskSpec(s), Module(s) and withdraw funds from gelato in one tx
    */
    function multiUnprovide(
        uint256 _withdrawAmount,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules
    )
        external;


    /**
     * @dev Deposits funds on Gelato Core
    */
    function provideFunds(address _provider) external payable;

    /**
     * @dev Withdraws funds on Gelato Core
    */
    function unprovideFunds(uint256 _withdrawAmount) external returns(uint256);
}


/// @title ActionGelatoV1
/// @author Hilmar Orth
/// @notice Gelato Action that
contract ActionGelatoV1 {

    using Address for address payable;
    address constant GELATO_CORE = 0x025030BdAa159f281cAe63873E68313a703725A5;

    // ===== Gelato ENTRY APIs ======

    /**
     * @dev Enables first time users to  pre-fund eth, whitelist an executor & register the
     * ProviderModuleDSA.sol to be able to use Gelato
     * @param _executor address of single execot node or gelato'S decentralized execution market
     * @param _taskSpecs enables external providers to whitelist TaskSpecs on gelato
     * @param _modules address of ProviderModuleDSA
     * @param _ethToDeposit amount of eth to deposit on Gelato, only for self-providers
     */
    function multiProvide(
        address _executor,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules,
        uint256 _ethToDeposit
    ) external payable {
        uint256 ethToDeposit = _ethToDeposit == type(uint256).max
            ? address(this).balance
            : _ethToDeposit;

        IGelatoCore(GELATO_CORE).multiProvide{value: ethToDeposit}(
            _executor,
            _taskSpecs,
            _modules
        );
    }

    /**
     * @dev Deposit Funds on Gelato to a given address
     * @param _provider address of balance to top up on Gelato
     * @param _ethToDeposit amount of eth to deposit on Gelato
     */
    function provideFunds(
        address _provider,
        uint256 _ethToDeposit
    ) external payable {
        uint256 ethToDeposit = _ethToDeposit == type(uint256).max
            ? address(this).balance
            : _ethToDeposit;

        IGelatoCore(GELATO_CORE).provideFunds{value: ethToDeposit}(
            _provider
        );
    }

    /**
     * @dev Withdraw funds previously deposited on Gelato
     * @param _ethToWithdraw amount of eth to withdraw from Gelato
     */
    function unprovideFunds(
        uint256 _ethToWithdraw,
        address payable _receiver
    ) external payable {
        uint256 withdrawAmount = IGelatoCore(GELATO_CORE).unprovideFunds(
            _ethToWithdraw
        );
        if (_receiver != address(0) && _receiver != address(this))
            _receiver.sendValue(withdrawAmount);
    }

    /**
     * @dev Submits a single, one-time task to Gelato
     * @param _provider Consists of proxy module address (DSA) and provider address ()
     * who will pay for the transaction execution
     * @param _task Task specifying the condition and the action connectors
     * @param _expiryDate Default 0, othweise timestamp after which the task expires
     */
    function submitTask(
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    ) external payable {
        IGelatoCore(GELATO_CORE).submitTask(_provider, _task, _expiryDate);
    }

    /**
     * @dev Submits single or mulitple Task Sequences to Gelato
     * @param _provider Consists of proxy module address (DSA) and provider address ()
     * who will pay for the transaction execution
     * @param _tasks A sequence of Tasks, can be a single or multiples
     * @param _expiryDate Default 0, othweise timestamp after which the task expires
     * @param _cycles How often the Task List should be executed, e.g. 5 times
     */
    function submitTaskCycle(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    ) external payable {
        IGelatoCore(GELATO_CORE).submitTaskCycle(
            _provider,
            _tasks,
            _expiryDate,
            _cycles
        );
    }

    /**
     * @dev Submits single or mulitple Task Chains to Gelato
     * @param _provider Consists of proxy module address (DSA) and provider address ()
     * who will pay for the transaction execution
     * @param _tasks A sequence of Tasks, can be a single or multiples
     * @param _expiryDate Default 0, othweise timestamp after which the task expires
     * @param _sumOfRequestedTaskSubmits The TOTAL number of Task auto-submits
     * that should have occured once the cycle is complete
     */
    function submitTaskChain(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    ) external payable {
        IGelatoCore(GELATO_CORE).submitTaskChain(
            _provider,
            _tasks,
            _expiryDate,
            _sumOfRequestedTaskSubmits
        );
    }

    // ===== Gelato EXIT APIs ======

    /**
     * @dev Withdraws funds from Gelato, de-whitelists TaskSpecs and Provider Modules
     * in one tx
     * @param _withdrawAmount Amount of ETH to withdraw from Gelato
     * @param _taskSpecs List of Task Specs to de-whitelist, default empty []
     * @param _modules List of Provider Modules to de-whitelist, default empty []
     */
    function multiUnprovide(
        uint256 _withdrawAmount,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules
    ) external payable {

        IGelatoCore(GELATO_CORE).multiUnprovide(
            _withdrawAmount,
            _taskSpecs,
            _modules
        );
    }

    /**
     * @dev Cancels outstanding Tasks
     * @param _taskReceipts List of Task Receipts to cancel
     */
    function multiCancelTasks(TaskReceipt[] calldata _taskReceipts)
        external payable
    {
        IGelatoCore(GELATO_CORE).multiCancelTasks(_taskReceipts);
    }
}