pragma solidity ^0.8.1;

import "./Executable.sol";
import "./ServiceRegistry.sol";
import "./SafeERC20.sol";
import "./IWETH.sol";
import "./Common.sol";
import "./UseStore.sol";
import "./Swap.sol";
import "./Common.sol";
import "./OperationStorage.sol";
import "./Common.sol";

contract UnwrapEth is Executable, UseStore {
  using SafeERC20 for IERC20;
  using Read for OperationStorage;

  constructor(address _registry) UseStore(_registry) {}

  function execute(bytes calldata data, uint8[] memory paramsMap) external payable override {
    IWETH weth = IWETH(registry.getRegisteredService(WETH));

    UnwrapEthData memory unwrapData = parseInputs(data);

    unwrapData.amount = store().readUint(bytes32(unwrapData.amount), paramsMap[0], address(this));

    if (unwrapData.amount == type(uint256).max) {
      unwrapData.amount = weth.balanceOf(address(this));
    }
    
    weth.withdraw(unwrapData.amount);

    emit Action(UNWRAP_ETH, bytes32(unwrapData.amount));
  }

  function parseInputs(bytes memory _callData) public pure returns (UnwrapEthData memory params) {
    return abi.decode(_callData, (UnwrapEthData));
  }
}
