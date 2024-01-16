pragma solidity ^0.8.15;

import "./Executable.sol";
import "./ServiceRegistry.sol";
import "./IERC3156FlashBorrower.sol";
import "./IERC3156FlashLender.sol";
import "./Common.sol";
import "./Common.sol";
import "./Maker.sol";
import "./ProxyPermission.sol";

contract TakeFlashloan is Executable, ProxyPermission {
  ServiceRegistry internal immutable registry;
  address internal immutable dai;

  constructor(ServiceRegistry _registry, address _dai) {
    registry = _registry;
    dai = _dai;
  }

  function execute(bytes calldata data, uint8[] memory) external payable override {
    FlashloanData memory flData = parseInputs(data);

    address operationExecutorAddress = registry.getRegisteredService(OPERATION_EXECUTOR);

    if (flData.dsProxyFlashloan) {
      givePermission(operationExecutorAddress);
    }
    IERC3156FlashLender(registry.getRegisteredService(FLASH_MINT_MODULE)).flashLoan(
      IERC3156FlashBorrower(operationExecutorAddress),
      dai,
      flData.amount,
      data
    );

    if (flData.dsProxyFlashloan) {
      removePermission(operationExecutorAddress);
    }
    emit Action(TAKE_FLASH_LOAN_ACTION, bytes32(flData.amount));
  }

  function parseInputs(bytes memory _callData) public pure returns (FlashloanData memory params) {
    return abi.decode(_callData, (FlashloanData));
  }
}
