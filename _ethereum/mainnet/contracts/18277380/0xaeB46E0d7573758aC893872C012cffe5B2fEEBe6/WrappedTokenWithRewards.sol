// https://onchainpolitics.com
// https://twitter.com/OnChainPolitics
// https://t.me/OnChainPolitics
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Rewards.sol";

contract WrappedTokenWithRewards is ERC20 {
  using SafeERC20 for IERC20;

  address public wrappedToken;
  Rewards public rewards;

  constructor(
    string memory _name,
    string memory _symbol,
    address _wrappedToken
  ) ERC20(_name, _symbol) {
    wrappedToken = _wrappedToken;
    rewards = new Rewards(address(this));
  }

  function deposit(uint256 _amount) external {
    _mint(_msgSender(), _amount);
    IERC20(wrappedToken).safeTransferFrom(_msgSender(), address(this), _amount);
  }

  function withdraw(uint256 _amount) external {
    _burn(_msgSender(), _amount);
    IERC20(wrappedToken).safeTransfer(_msgSender(), _amount);
  }

  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal override {
    try rewards.setShare(_from, _amount, true) {} catch {}
    try rewards.setShare(_to, _amount, false) {} catch {}
  }
}
