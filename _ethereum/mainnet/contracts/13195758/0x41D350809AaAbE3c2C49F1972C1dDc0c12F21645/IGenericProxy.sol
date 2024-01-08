// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./IGovernable.sol";

interface IGenericProxy is IGovernable {
  // errors
  error CallError();
  error IllegalBlock();

  // methods
  function call(
    uint256 _targetBlock,
    uint256 _reward,
    address _target1,
    bytes calldata _data1
  ) external payable;

  function justCall(address _target, bytes calldata _data) external;

  function call(
    uint256 _targetBlock,
    uint256 _reward,
    address _target1,
    bytes calldata _data1,
    address _target2,
    bytes calldata _data2
  ) external payable;

  function call(
    uint256 _targetBlock,
    uint256 _reward,
    address _target1,
    bytes calldata _data1,
    address _target2,
    bytes calldata _data2,
    address _target3,
    bytes calldata _data3
  ) external payable;

  function call(
    uint256 _targetBlock,
    uint256 _reward,
    address[] calldata _targets,
    bytes[] calldata _data
  ) external payable;

  function callWithPriorityFee(
    uint256 _targetBlock,
    uint256 _priorityFee,
    address[] calldata _targets,
    bytes[] calldata _data
  ) external payable;

  function depositETH() external payable;

  function withdrawETH(address payable _to, uint256 _amount) external;

  receive() external payable;
}
