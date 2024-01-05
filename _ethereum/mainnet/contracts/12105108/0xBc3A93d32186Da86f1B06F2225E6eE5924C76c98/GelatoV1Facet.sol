// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./BFacetOwner.sol";
import "./Address.sol";
import "./LibConcurrentCanExec.sol";
import "./GelatoString.sol";
import "./GelatoTaskReceipt.sol";
import "./IGelatoCore.sol";
import "./IGelatoV1.sol";

contract GelatoV1Facet is BFacetOwner {
    using Address for address payable;
    using GelatoString for string;
    using GelatoTaskReceipt for TaskReceipt;

    struct Response {
        uint256 taskReceiptId;
        uint256 taskGasLimit;
        string response;
    }

    function stakeExecutor(IGelatoV1 _gelatoCore) external payable onlyOwner {
        _gelatoCore.stakeExecutor{value: msg.value}();
    }

    function unstakeExecutor(IGelatoV1 _gelatoCore, address payable _to)
        external
        onlyOwner
    {
        uint256 stake = _gelatoCore.executorStake(address(this));
        _gelatoCore.unstakeExecutor();
        _to.sendValue(stake);
    }

    function multiReassignProviders(
        IGelatoV1 _gelatoCore,
        address[] calldata _providers,
        address _newExecutor
    ) public onlyOwner {
        _gelatoCore.multiReassignProviders(_providers, _newExecutor);
    }

    function providerRefund(
        IGelatoV1 _gelatoCore,
        address _provider,
        uint256 _amount
    ) external onlyOwner {
        _amount = withdrawExcessExecutorStake(
            _gelatoCore,
            _amount,
            payable(address(0))
        );
        _gelatoCore.provideFunds{value: _amount}(_provider);
    }

    function withdrawExcessExecutorStake(
        IGelatoV1 _gelatoCore,
        uint256 _withdrawAmount,
        address payable _to
    ) public onlyOwner returns (uint256 amount) {
        amount = _gelatoCore.withdrawExcessExecutorStake(_withdrawAmount);
        if (_to != address(0)) _to.sendValue(amount);
    }

    function v1ConcurrentMultiCanExec(
        address _gelatoCore,
        TaskReceipt[] calldata _taskReceipts,
        uint256 _gelatoGasPrice,
        uint256 _buffer
    )
        external
        view
        returns (
            bool canExecRes,
            uint256 blockNumber,
            Response[] memory responses
        )
    {
        canExecRes = LibConcurrentCanExec.concurrentCanExec(_buffer);
        (blockNumber, responses) = v1MultiCanExec(
            _gelatoCore,
            _taskReceipts,
            _gelatoGasPrice
        );
    }

    function v1MultiCanExec(
        address _gelatoCore,
        TaskReceipt[] calldata _taskReceipts,
        uint256 _gelatoGasPrice
    ) public view returns (uint256 blockNumber, Response[] memory responses) {
        blockNumber = block.number;
        uint256 gelatoMaxGas = IGelatoV1(_gelatoCore).gelatoMaxGas();
        responses = new Response[](_taskReceipts.length);
        for (uint256 i = 0; i < _taskReceipts.length; i++) {
            uint256 taskGasLimit = getGasLimit(_taskReceipts[i], gelatoMaxGas);
            try
                IGelatoV1(_gelatoCore).canExec( // IGelatoV1 bug
                    _taskReceipts[i],
                    taskGasLimit,
                    _gelatoGasPrice
                )
            returns (string memory response) {
                responses[i] = Response({
                    taskReceiptId: _taskReceipts[i].id,
                    taskGasLimit: taskGasLimit,
                    response: response
                });
            } catch {
                responses[i] = Response({
                    taskReceiptId: _taskReceipts[i].id,
                    taskGasLimit: taskGasLimit,
                    response: "GelatoV1Facet.multiCanExec: failed"
                });
            }
        }
    }

    function getGasLimit(
        TaskReceipt calldata _taskReceipt,
        uint256 _gelatoMaxGas
    ) public pure returns (uint256) {
        return
            _taskReceipt.selfProvider()
                ? _taskReceipt.task().selfProviderGasLimit
                : _gelatoMaxGas;
    }
}
