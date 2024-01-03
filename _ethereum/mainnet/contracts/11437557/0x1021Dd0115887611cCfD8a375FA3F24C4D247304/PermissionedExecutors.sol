// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "./Proxied.sol";
import "./IGelatoCore.sol";
import "./IGelatoSysAdmin.sol";
import "./IGelatoProviders.sol";
import "./IGelatoExecutors.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./GelatoTaskReceipt.sol";
import "./GelatoString.sol";
import "./SafeMath.sol";

/// @title PermissionedExecutors
/// @notice Contract to organize a multitude of Executor accounts as one whole.
contract PermissionedExecutors is Proxied {
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using GelatoString for string;
    using GelatoTaskReceipt for TaskReceipt;
    using SafeMath for uint256;

    event LogProviderRefundFailed(
        address indexed executor,
        address indexed provider,
        string error
    );

    struct Reponse {
        uint256 taskReceiptId;
        uint256 taskGasLimit;
        string response;
    }

    address public immutable gelatoCore;
    address public immutable gelatoProvider;

    EnumerableSet.AddressSet internal _executors;

    mapping(address => uint256) private _testFunds;

    /// @dev only set immutable vars here as they can be read from Proxy, while
    /// state vars cannot be read from Proxy.
    constructor(address _gelatoCore, address _gelatoProvider) {
        gelatoCore = _gelatoCore;
        gelatoProvider = _gelatoProvider;
    }

    modifier onlyExecutors virtual {
        require(
            _executors.contains(msg.sender),
            "PermissionedExecutors.onlyExecutor"
        );
        _;
    }

    /// @dev only in case ETH gets stuck. Also withdraws any _testFunds.
    function withdrawContractBalance() public virtual onlyOwner {
        msg.sender.sendValue(address(this).balance);
    }

    function addExecutor(address _executor) public virtual onlyOwner {
        _executors.add(_executor);
    }

    function removeExecutor(address _executor) public virtual {
        require(
            _executors.contains(_executor),
            "removeExecutor: NOT_AN_EXECUTOR"
        );
        require(
            msg.sender == _owner() || _executor == msg.sender,
            "removeExecutor: NOT_AUTHORIZED"
        );
        _executors.remove(_executor);
    }

    function stakeExecutor() public payable virtual onlyOwner {
        IGelatoExecutors(gelatoCore).stakeExecutor{value: msg.value}();
    }

    function unstakeExecutor() public virtual onlyOwner {
        uint256 stake =
            IGelatoProviders(gelatoCore).executorStake(address(this));
        IGelatoExecutors(gelatoCore).unstakeExecutor();
        msg.sender.sendValue(stake);
    }

    function withdrawExcessExecutorStake(uint256 _withdrawAmount)
        external
        payable
        virtual
        onlyOwner
    {
        (uint256 amount, string memory error) =
            _withdrawExcessExecutorStake(_withdrawAmount);
        if (amount == 0) {
            revert(
                error.prefix(
                    "PermissionedExecutors.withdrawExcessExecutorStake:"
                )
            );
        }
        msg.sender.sendValue(amount);
    }

    function _withdrawExcessExecutorStake(uint256 _withdrawAmount)
        internal
        virtual
        returns (uint256, string memory)
    {
        try
            IGelatoExecutors(gelatoCore).withdrawExcessExecutorStake(
                _withdrawAmount
            )
        returns (uint256 realAmount) {
            return realAmount == 0 ? (0, "0 amount") : (realAmount, "");
        } catch Error(string memory error) {
            return (0, error);
        } catch {
            return (0, "undefined error");
        }
    }

    function multiReassignProviders(
        address[] calldata _providers,
        address _newExecutor
    ) public virtual onlyOwner {
        IGelatoExecutors(gelatoCore).multiReassignProviders(
            _providers,
            _newExecutor
        );
    }

    function providerRefund(address _provider, uint256 _amount)
        external
        virtual
        onlyOwner
    {
        (bool success, string memory error) =
            _providerRefund(_provider, _amount);
        if (!success)
            revert(error.prefix("PermissionedExecutors.providerRefund:"));
    }

    function _providerRefund(address _provider, uint256 _amount)
        internal
        virtual
        returns (bool, string memory error)
    {
        (_amount, error) = _withdrawExcessExecutorStake(_amount);

        if (_amount == 0) return (false, error);

        try
            IGelatoProviders(gelatoCore).provideFunds{value: _amount}(_provider)
        {
            return (true, "");
        } catch Error(string memory _error) {
            return (false, _error);
        } catch {
            return (false, "undefined");
        }
    }

    /// @dev This aggregates results and saves network provider requests
    function multiCanExec(
        TaskReceipt[] memory _taskReceipts,
        uint256 _gelatoGasPrice
    )
        external
        view
        virtual
        returns (uint256 blockNumber, Reponse[] memory responses)
    {
        return _multiCanExec(_taskReceipts, _gelatoGasPrice);
    }

    function _multiCanExec(
        TaskReceipt[] memory _taskReceipts,
        uint256 _gelatoGasPrice
    )
        internal
        view
        virtual
        returns (uint256 blockNumber, Reponse[] memory responses)
    {
        blockNumber = block.number;
        uint256 gelatoMaxGas = IGelatoSysAdmin(gelatoCore).gelatoMaxGas();
        responses = new Reponse[](_taskReceipts.length);
        for (uint256 i = 0; i < _taskReceipts.length; i++) {
            uint256 taskGasLimit = getGasLimit(_taskReceipts[i], gelatoMaxGas);
            try
                IGelatoCore(gelatoCore).canExec(
                    _taskReceipts[i],
                    taskGasLimit,
                    _gelatoGasPrice
                )
            returns (string memory response) {
                responses[i] = Reponse({
                    taskReceiptId: _taskReceipts[i].id,
                    taskGasLimit: taskGasLimit,
                    response: response
                });
            } catch {
                responses[i] = Reponse({
                    taskReceiptId: _taskReceipts[i].id,
                    taskGasLimit: taskGasLimit,
                    response: "PermissionedExecutors.multiCanExec: failed"
                });
            }
        }
    }

    /// @notice Only listed Executors can call this.
    /// @dev Caution: there is no built-in coordination mechanism between the
    /// Executors. Only one Executor should be live at all times, lest they
    /// will incur tx collision costs.
    function exec(TaskReceipt calldata _taskReceipt)
        external
        virtual
        onlyExecutors
    {
        _exec(_taskReceipt);
    }

    function _exec(TaskReceipt calldata _taskReceipt) internal virtual {
        // solhint-disable-next-line no-empty-blocks
        try IGelatoCore(gelatoCore).exec(_taskReceipt) {} catch Error(
            string memory error
        ) {
            error.revertWithInfo("PermissionedExecutors.exec:");
        } catch {
            revert("PermissionedExecutors.exec:unknown error");
        }

        if (_taskReceipt.provider.addr == gelatoProvider) {
            (bool refunded, string memory error) =
                _providerRefund(gelatoProvider, type(uint256).max);

            if (!refunded)
                emit LogProviderRefundFailed(tx.origin, gelatoProvider, error);
        }
    }

    function addTestFunds() public payable virtual {
        _testFunds[msg.sender] = _testFunds[msg.sender].add(msg.value);
    }

    function removeTestFunds(uint256 _amount) public virtual {
        _testFunds[msg.sender] = _testFunds[msg.sender].sub(_amount);
        msg.sender.sendValue(_amount);
    }

    function executors() public view returns (address[] memory __executors) {
        __executors = new address[](_executors.length());
        for (uint256 i; i < _executors.length(); i++)
            __executors[i] = _executors.at(i);
    }

    function isExecutor(address _executor) public view returns (bool) {
        return _executors.contains(_executor);
    }

    function executorAt(uint256 _index) public view returns (address) {
        return _executors.at(_index);
    }

    function getGasLimit(TaskReceipt memory _taskReceipt, uint256 _gelatoMaxGas)
        public
        pure
        virtual
        returns (uint256)
    {
        return
            _taskReceipt.selfProvider()
                ? _taskReceipt.task().selfProviderGasLimit
                : _gelatoMaxGas;
    }
}
