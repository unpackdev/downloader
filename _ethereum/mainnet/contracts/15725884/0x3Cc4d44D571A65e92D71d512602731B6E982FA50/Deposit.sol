pragma solidity ^0.8.15;

import "./Executable.sol";
import "./UseStore.sol";
import "./OperationStorage.sol";
import "./ILendingPool.sol";
import "./Aave.sol";
import "./SafeERC20.sol";
import "./Aave.sol";

contract AaveDeposit is Executable, UseStore {
  using Write for OperationStorage;
  using Read for OperationStorage;

  constructor(address _registry) UseStore(_registry) {}

  function execute(bytes calldata data, uint8[] memory paramsMap) external payable override {
    DepositData memory deposit = parseInputs(data);

    deposit.amount = store().readUint(bytes32(deposit.amount), paramsMap[1], address(this));

    ILendingPool(registry.getRegisteredService(AAVE_LENDING_POOL)).deposit(
      deposit.asset,
      deposit.amount,
      address(this),
      0
    );

    store().write(bytes32(deposit.amount));
    emit Action(DEPOSIT_ACTION, bytes32(deposit.amount));
  }

  function parseInputs(bytes memory _callData) public pure returns (DepositData memory params) {
    return abi.decode(_callData, (DepositData));
  }
}
