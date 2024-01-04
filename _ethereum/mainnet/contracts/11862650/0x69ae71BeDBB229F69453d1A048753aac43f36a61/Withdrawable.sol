pragma solidity ^0.6.0;

import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./MultiRole.sol";

abstract contract Withdrawable is MultiRole {
  using SafeERC20 for IERC20;

  uint256 private roleId;

  function withdraw(uint256 amount) external onlyRoleHolder(roleId) {
    Address.sendValue(msg.sender, amount);
  }

  function withdrawErc20(address erc20Address, uint256 amount)
    external
    onlyRoleHolder(roleId)
  {
    IERC20 erc20 = IERC20(erc20Address);
    erc20.safeTransfer(msg.sender, amount);
  }

  function _createWithdrawRole(
    uint256 newRoleId,
    uint256 managingRoleId,
    address withdrawerAddress
  ) internal {
    roleId = newRoleId;
    _createExclusiveRole(newRoleId, managingRoleId, withdrawerAddress);
  }

  function _setWithdrawRole(uint256 setRoleId)
    internal
    onlyValidRole(setRoleId)
  {
    roleId = setRoleId;
  }
}
