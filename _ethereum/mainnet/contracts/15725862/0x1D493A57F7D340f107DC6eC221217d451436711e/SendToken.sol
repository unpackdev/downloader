pragma solidity ^0.8.15;

import "./Executable.sol";
import "./SafeERC20.sol";
import "./Common.sol";
import "./Common.sol";

contract SendToken is Executable {
  using SafeERC20 for IERC20;

  function execute(bytes calldata data, uint8[] memory) external payable override {
    SendTokenData memory send = parseInputs(data);
    if (msg.value > 0) {
      payable(send.to).transfer(send.amount);
    } else {
      IERC20(send.asset).safeTransfer(send.to, send.amount);
    }

    emit Action(SEND_TOKEN_ACTION, bytes32(send.amount));
  }

  function parseInputs(bytes memory _callData) public pure returns (SendTokenData memory params) {
    return abi.decode(_callData, (SendTokenData));
  }
}
