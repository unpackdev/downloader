// SPDX-License-Identifier: MIT

pragma abicoder v2;
pragma solidity ^0.8.23;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract ZKBConverter is Ownable {
  using SafeERC20 for IERC20;

  IERC20 public ZKS_TOKEN;
  IERC20 public ZKB_TOKEN;
  address public BLACK_HOLE = 0x0090000000000000000000000000000000000009;

  event Converted(address indexed user, uint256 amount);

  constructor() Ownable(msg.sender) {}

  function setAddress(address _ZKSToken, address _ZKBToken, address _blackHole) public onlyOwner {
    ZKS_TOKEN = IERC20(_ZKSToken);
    ZKB_TOKEN = IERC20(_ZKBToken);
    BLACK_HOLE = _blackHole;
  }

  // convert ZKS to ZKB
  function convert(uint256 amount) public {
    // transfer ZKS to black hole
    ZKS_TOKEN.safeTransferFrom(msg.sender, BLACK_HOLE, amount);
    // transfer ZKB to user
    ZKB_TOKEN.safeTransfer(msg.sender, amount);
    // emit event
    emit Converted(msg.sender, amount);
  }

  // allow owner to withdraw tokens
  function withdraw(address token, uint256 amount) public onlyOwner {
    if (token == address(0)) {
      (bool result,) = payable(msg.sender).call{value: amount}("");
      require(result, "ZKBConverter: withdraw failed");
    } else {
      IERC20(token).safeTransfer(msg.sender, amount);
    }
  }
}
