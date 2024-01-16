pragma solidity ^0.8.15;

import "./Executable.sol";
import "./SafeERC20.sol";
import "./Common.sol";
import "./UseStore.sol";
import "./OperationStorage.sol";
import "./Common.sol";

contract SetApproval is Executable, UseStore {
  using SafeERC20 for IERC20;
  using Read for OperationStorage;

  constructor(address _registry) UseStore(_registry) {}

  function execute(bytes calldata data, uint8[] memory paramsMap) external payable override {
    SetApprovalData memory approval = parseInputs(data);

    approval.amount = store().readUint(bytes32(approval.amount), paramsMap[2], address(this));
    IERC20(approval.asset).safeApprove(approval.delegate, approval.amount);

    emit Action(SET_APPROVAL_ACTION, bytes32(approval.amount));
  }

  function parseInputs(bytes memory _callData) public pure returns (SetApprovalData memory params) {
    return abi.decode(_callData, (SetApprovalData));
  }
}
