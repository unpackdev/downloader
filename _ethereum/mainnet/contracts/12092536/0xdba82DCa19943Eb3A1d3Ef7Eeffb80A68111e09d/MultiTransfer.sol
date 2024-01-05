// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract MultiTransfer is Ownable {
  using SafeERC20 for IERC20;

  function transfer(IERC20 _token, uint256 _total, address[] calldata _addresses, uint256[] calldata _amounts) external {
    require(_addresses.length == _amounts.length, "RulerMT: len dont match");
    _token.safeTransferFrom(msg.sender, address(this), _total);
    for (uint256 i = 0; i < _addresses.length; i++) {
      _token.safeTransfer(_addresses[i], _amounts[i]);
    }
  }

  function collect(IERC20[] calldata _tokens) external onlyOwner {
    address _owner = owner();
    for (uint256 i = 0; i < _tokens.length; i++) {
      _tokens[i].safeTransfer(_owner, _tokens[i].balanceOf(address(this)));
    }
  }
}