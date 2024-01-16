pragma solidity ^0.8.15;

import "./Executable.sol";
import "./UseStore.sol";
import "./OperationStorage.sol";
import "./IVariableDebtToken.sol";
import "./IWETHGateway.sol";
import "./Aave.sol";
import "./Aave.sol";

contract AaveBorrow is Executable, UseStore {
  using Write for OperationStorage;

  IVariableDebtToken public constant dWETH =
    IVariableDebtToken(0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf);

  constructor(address _registry) UseStore(_registry) {}

  function execute(bytes calldata data, uint8[] memory) external payable override {
    BorrowData memory borrow = parseInputs(data);

    address wethGatewayAddress = registry.getRegisteredService(AAVE_WETH_GATEWAY);
    dWETH.approveDelegation(wethGatewayAddress, borrow.amount);
    
    IWETHGateway(wethGatewayAddress).borrowETH(
      registry.getRegisteredService(AAVE_LENDING_POOL),
      borrow.amount,
      2,
      0
    );
    address payable to = payable(borrow.to);
    to.transfer(borrow.amount);

    store().write(bytes32(borrow.amount));
    emit Action(BORROW_ACTION, bytes32(borrow.amount));
  }

  function parseInputs(bytes memory _callData) public pure returns (BorrowData memory params) {
    return abi.decode(_callData, (BorrowData));
  }
}
