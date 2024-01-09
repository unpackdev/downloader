// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "IERC20.sol";
import "SafeOwnable.sol";
import "SafeERC20.sol";

contract TokenMigrator is SafeOwnable {

  using SafeERC20 for IERC20;

  IERC20 public immutable oldToken;
  IERC20 public immutable newToken;

  address public treasury;

  constructor(
    IERC20  _oldToken,
    IERC20  _newToken,
    address _treasury
  ) {
    oldToken = _oldToken;
    newToken = _newToken;
    treasury = _treasury;
  }

  function migrate(uint _amount) external {
    IERC20(oldToken).safeTransferFrom(msg.sender, address(this), _amount);
    IERC20(newToken).safeTransfer(msg.sender, _amount);
  }

  function recall(address _token, uint _amount) external onlyOwner {
    IERC20(_token).safeTransfer(treasury, _amount);
  }
}