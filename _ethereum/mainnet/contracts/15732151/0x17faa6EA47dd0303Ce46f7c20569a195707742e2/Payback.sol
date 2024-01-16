pragma solidity ^0.8.15;

import "./Executable.sol";
import "./UseStore.sol";
import "./OperationStorage.sol";
import "./IVariableDebtToken.sol";
import "./IWETHGateway.sol";
import "./Aave.sol";
import "./ILendingPool.sol";

import "./Aave.sol";

contract AavePayback is Executable, UseStore {
  using Write for OperationStorage;
  using Read for OperationStorage;

  IVariableDebtToken public constant dWETH =
    IVariableDebtToken(0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf);
  constructor(address _registry) UseStore(_registry) {}

  function execute(bytes calldata data, uint8[] memory paramsMap) external payable override {
    PaybackData memory payback = abi.decode(data, (PaybackData));

    uint256 variableNormalizedDebt = ILendingPool(registry.getRegisteredService(AAVE_LENDING_POOL)).getReserveNormalizedVariableDebt(payback.asset);

    payback.amount = store().readUint(bytes32(payback.amount), paramsMap[1], address(this));

    ILendingPool(registry.getRegisteredService(AAVE_LENDING_POOL)).repay(
      payback.asset,
      payback.paybackAll ? type(uint256).max : payback.amount,
      2,
      address(this)
    );

    store().write(bytes32(payback.amount));
    emit Action(PAYBACK_ACTION, bytes32(payback.amount));

}
}


