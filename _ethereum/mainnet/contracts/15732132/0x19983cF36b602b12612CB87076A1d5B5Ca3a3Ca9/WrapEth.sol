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

contract WrapEth is Executable, UseStore {
  using SafeERC20 for IERC20;
  using Read for OperationStorage;

  constructor(address _registry) UseStore(_registry) {}

  function execute(bytes calldata data, uint8[] memory paramsMap) external payable override {
    WrapEthData memory wrapData = parseInputs(data);
    wrapData.amount = store().readUint(bytes32(wrapData.amount), paramsMap[0], address(this));

    if (wrapData.amount == type(uint256).max) {
      wrapData.amount = address(this).balance;
    }
    IWETH(registry.getRegisteredService(WETH)).deposit{ value: wrapData.amount }();

    emit Action(WRAP_ETH, bytes32(wrapData.amount));
  }

  function parseInputs(bytes memory _callData) public pure returns (WrapEthData memory params) {
    return abi.decode(_callData, (WrapEthData));
  }
}
