// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";

import "./IBeefyVault.sol";
import "./UniswapV3Utils.sol";

contract Migrator {
  using SafeERC20 for IERC20;

  function migrate(
    address _vaultA,
    address _vaultB,
    uint256 _shares,
    address _router,
    address[] memory _route,
    uint24[] memory _fee
  ) external {
    uint256 amount = IBeefyVault(_vaultA).migrationWithdraw(_shares, msg.sender);

    if(IBeefyVault(_vaultA).want() != IBeefyVault(_vaultB).want()) {
      IERC20(IBeefyVault(_vaultA).want()).approve(_router, amount);
      amount = UniswapV3Utils.swap(_router, _route, _fee, amount);
    }

    IERC20(IBeefyVault(_vaultB).want()).approve(_vaultB, amount);

    IBeefyVault(_vaultB).migrationDeposit(amount, msg.sender);
  }
}