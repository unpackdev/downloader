// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./IGenericProxy.sol";
import "./Governable.sol";

// solhint-disable avoid-low-level-calls
contract GenericProxy is IGenericProxy, Governable {
  function call(
    uint256 _targetBlock,
    uint256 _reward,
    address _target1,
    bytes calldata _data1
  ) external payable override onlyGovernor {
    if (block.number != _targetBlock) revert IllegalBlock();

    (bool success, ) = _target1.call(_data1);
    if (!success) revert CallError();

    block.coinbase.transfer(_reward);
  }

  function justCall(address _target, bytes calldata _data) external override onlyGovernor {
    (bool success, ) = _target.call(_data);
    if (!success) revert CallError();
  }

  function call(
    uint256 _targetBlock,
    uint256 _reward,
    address _target1,
    bytes calldata _data1,
    address _target2,
    bytes calldata _data2
  ) external payable override onlyGovernor {
    if (block.number != _targetBlock) revert IllegalBlock();

    (bool success, ) = _target1.call(_data1);
    if (!success) revert CallError();

    (success, ) = _target2.call(_data2);
    if (!success) revert CallError();

    block.coinbase.transfer(_reward);
  }

  function call(
    uint256 _targetBlock,
    uint256 _reward,
    address _target1,
    bytes calldata _data1,
    address _target2,
    bytes calldata _data2,
    address _target3,
    bytes calldata _data3
  ) external payable override onlyGovernor {
    if (block.number != _targetBlock) revert IllegalBlock();

    (bool success, ) = _target1.call(_data1);
    if (!success) revert CallError();

    (success, ) = _target2.call(_data2);
    if (!success) revert CallError();

    (success, ) = _target3.call(_data3);
    if (!success) revert CallError();

    block.coinbase.transfer(_reward);
  }

  function call(
    uint256 _targetBlock,
    uint256 _reward,
    address[] calldata _targets,
    bytes[] calldata _data
  ) external payable override onlyGovernor {
    if (block.number != _targetBlock) revert IllegalBlock();

    for (uint32 _index = 0; _index < _targets.length; _index++) {
      (bool success, ) = _targets[_index].call(_data[_index]);
      if (!success) revert CallError();
    }

    block.coinbase.transfer(_reward);
  }

  function callWithPriorityFee(
    uint256 _targetBlock,
    uint256 _priorityFee,
    address[] calldata _targets,
    bytes[] calldata _data
  ) external payable override onlyGovernor {
    uint256 _initialGas = gasleft();
    if (block.number != _targetBlock) revert IllegalBlock();

    for (uint32 _index = 0; _index < _targets.length; _index++) {
      (bool success, ) = _targets[_index].call(_data[_index]);
      if (!success) revert CallError();
    }

    uint256 _reward = _priorityFee * (_initialGas - gasleft());

    block.coinbase.transfer(_reward);
  }

  function depositETH() external payable override {}

  function withdrawETH(address payable _to, uint256 _amount) external override onlyGovernor {
    _to.transfer(_amount);
  }

  receive() external payable override {}
}
