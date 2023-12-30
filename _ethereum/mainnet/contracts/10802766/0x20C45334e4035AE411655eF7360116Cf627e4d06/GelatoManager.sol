// SPDX-License-Identifier: GPLv3
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

// Gelato Dependencies
import "./IGelatoCore.sol";
import "./IGelatoProviders.sol";
import "./IGelatoProviderModule.sol";
import "./GelatoBytes.sol";
import "./Address.sol";

/// @title GelatoManager
/// @author Hilmar X
/// @notice Deposits Funds, whitelits Tasks and Provider modules on Gelato.
contract GelatoManager {

    using GelatoBytes for bytes;

    address public gelatoCore;
    address public governance;
    address public strategist;

    using Address for address payable;

    modifier onlyGovernance() {
        _;
        require(msg.sender == governance, "GelatoManager: No Gov");
    }

    modifier onlyStrategist() {
        _;
        require(msg.sender == strategist, "GelatoManager: No Strat");
    }

    modifier onlyStratOrGov() {
        _;
        require(msg.sender == governance || msg.sender == strategist, "GelatoManager: No Gov nor Strat");
    }

    modifier noZeroAddress(address _) {
        require(_ != address(0), "GelatoUserProxy.noZeroAddress");
        _;
    }

    constructor(
        address _gelatoCore
    )
        public
        payable
    {
        // Set GelatoCore Address
        gelatoCore = _gelatoCore;

        // Set Governance
        governance = msg.sender;

        // Set Strategist
        strategist = msg.sender;
    }

    // This contract should receive ETH
    receive() external payable {}

    function setGelatoCore(address _gelatoCore)
        public
        onlyGovernance
    {
        require(_gelatoCore != address(0), "GelatoCore: Cannot be Address Zero");
        gelatoCore = _gelatoCore;
    }

    function setGov(address _newGov)
        public
        onlyGovernance
    {
        require(_newGov != address(0), "Governance: Cannot be Address Zero");
        governance = _newGov;
    }

    /// @dev Can be set to address(0) eventually
    function setStrat(address _newStrat)
        public
        onlyGovernance
    {
        strategist = _newStrat;
    }

    // === GELATO INTERACTIONS ===

    // 1. Deposit ETH on gelato
    function provideFunds()
        public
        payable
    {
        IGelatoProviders(gelatoCore).provideFunds{value: msg.value}(address(this));
    }

    // 2. Withdraw ETH from gelato
    function withdrawFunds(uint256 _amount, address payable _receiver)
        public
        onlyGovernance
    {
        uint256 realWithdrawAmount = IGelatoProviders(gelatoCore).unprovideFunds(_amount);
        _receiver.sendValue(realWithdrawAmount);
    }

    // 3. Set Standard Provider Module => Defines what kind of smart contract Gelato will interact with => Custom in this case
    function addProviderModules(IGelatoProviderModule[] memory _modules)
        public
        onlyStratOrGov
    {
        IGelatoProviders(gelatoCore).addProviderModules(_modules);
    }

    // 4. Select Executor => Can be your own relayer or the standard gelato execution network (recommended)
    function assignExecutor(address _executor)
        public
        onlyStratOrGov
    {
        IGelatoProviders(gelatoCore).providerAssignsExecutor(_executor);
    }

    // 5. Whitelist task spec
    function whitelistTaskSpecs(TaskSpec[] memory _taskSpecs)
        public
        onlyStratOrGov
    {
        IGelatoProviders(gelatoCore).provideTaskSpecs(_taskSpecs);
    }

    // 6. Submit Tasks
    function submitTask(
        Provider memory _provider,
        Task memory _task,
        uint256 _expiryDate
    )
        public
        onlyStratOrGov
    {
        IGelatoCore(gelatoCore).submitTask(_provider, _task, _expiryDate);
    }

    function submitTaskCycle(
        Provider memory _provider,
        Task[] memory _tasks,
        uint256 _expiryDate,
        uint256 _cycles  // how many full cycles should be submitted
    )
        public
        onlyStratOrGov
    {
        IGelatoCore(gelatoCore).submitTaskCycle(_provider, _tasks, _expiryDate, _cycles);
    }

    function submitTaskChain(
        Provider memory _provider,
        Task[] memory _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits  // see IGelatoCore for explanation
    )
        public
        onlyStratOrGov
    {
        IGelatoCore(gelatoCore).submitTaskChain(_provider, _tasks, _expiryDate, _sumOfRequestedTaskSubmits);
    }

    // 7. Exex Actions
    function execAction(Action calldata _action) external payable {
        require(msg.sender == governance || msg.sender == gelatoCore, "MultiExec: Gov nor GelatoCore");
        if (_action.operation == Operation.Call)
            _callAction(_action.addr, _action.data, _action.value);
        else if (_action.operation == Operation.Delegatecall)
            _delegatecallAction(_action.addr, _action.data);
        else
            revert("GelatoUserProxy.execAction: invalid operation");
    }

    function _callAction(address _action, bytes calldata _data, uint256 _value)
        internal
        noZeroAddress(_action)
    {
        (bool success, bytes memory returndata) = _action.call{value: _value}(_data);
        if (!success) returndata.revertWithErrorString("_callAction:");
    }

    function _delegatecallAction(address _action, bytes calldata _data)
        internal
        noZeroAddress(_action)
    {
        (bool success, bytes memory returndata) = _action.delegatecall(_data);
        if (!success) returndata.revertWithErrorString("_delegatecallAction:");
    }

}