// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

/******************************************************************************\
* Author: Evert Kors <dev@sherlock.xyz> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import "./LibDiamond.sol";

import "./IPoolStake.sol";

import "./LibPool.sol";

contract PoolOpen is IPoolStake {
  using SafeERC20 for IERC20;

  function stake(
    uint256 _amount,
    address _receiver,
    IERC20 _token
  ) external virtual override returns (uint256) {
    return _stake(_amount, _receiver, _token);
  }

  function _stake(
    uint256 _amount,
    address _receiver,
    IERC20 _token
  ) internal returns (uint256 lock) {
    require(_amount != 0, 'AMOUNT');
    require(_receiver != address(0), 'RECEIVER');
    PoolStorage.Base storage ps = baseData(_token);
    require(ps.stakes, 'NO_STAKES');
    _token.safeTransferFrom(msg.sender, address(this), _amount);

    lock = LibPool.stake(ps, _amount, _receiver);
  }

  function baseData(IERC20 _token) internal view returns (PoolStorage.Base storage ps) {
    ps = PoolStorage.ps(_token);
    require(ps.govPool != address(0), 'INVALID_TOKEN');
  }
}
