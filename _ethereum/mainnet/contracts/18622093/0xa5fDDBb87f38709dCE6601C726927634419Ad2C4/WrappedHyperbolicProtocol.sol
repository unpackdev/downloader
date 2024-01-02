// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./SafeERC20.sol";

contract WrappedHyperbolicProtocol is ERC20 {
  using SafeERC20 for IERC20;

  IERC20 constant HYPE = IERC20(0x85225Ed797fd4128Ac45A992C46eA4681a7A15dA);

  constructor() ERC20('Wrapped Hyperbolic Protocol', 'wHYPE') {}

  function deposit(uint256 _amount) external {
    _mint(_msgSender(), _amount);
    HYPE.safeTransferFrom(_msgSender(), address(this), _amount);
  }

  function withdraw(uint256 _amount) external {
    _burn(_msgSender(), _amount);
    HYPE.safeTransfer(_msgSender(), _amount);
  }
}
