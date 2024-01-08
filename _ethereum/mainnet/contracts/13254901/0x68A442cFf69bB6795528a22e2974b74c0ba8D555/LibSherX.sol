// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <dev@sherlock.xyz> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import "./PoolStorage.sol";
import "./GovStorage.sol";

import "./LibSherXERC20.sol";
import "./LibPool.sol";

library LibSherX {
  using SafeMath for uint256;

  function viewAccrueUSDPool() public view returns (uint256 totalUsdPool) {
    SherXStorage.Base storage sx = SherXStorage.sx();
    totalUsdPool = sx.totalUsdPool.add(
      block.number.sub(sx.totalUsdLastSettled).mul(sx.totalUsdPerBlock)
    );
  }

  function accrueUSDPool() external returns (uint256 totalUsdPool) {
    SherXStorage.Base storage sx = SherXStorage.sx();
    totalUsdPool = viewAccrueUSDPool();
    sx.totalUsdPool = totalUsdPool;
    sx.totalUsdLastSettled = block.number;
  }

  function settleInternalSupply(uint256 _deduct) external {
    SherXStorage.Base storage sx = SherXStorage.sx();
    sx.internalTotalSupply = getTotalSherX().sub(_deduct);
    sx.internalTotalSupplySettled = block.number;
  }

  function getTotalSherX() public view returns (uint256) {
    // calc by taking base supply, block at, and calc it by taking base + now - block_at * sherxperblock
    // update baseSupply on every premium update
    SherXStorage.Base storage sx = SherXStorage.sx();
    return
      sx.internalTotalSupply.add(
        block.number.sub(sx.internalTotalSupplySettled).mul(sx.sherXPerBlock)
      );
  }

  function calcUnderlying(uint256 _amount)
    external
    view
    returns (IERC20[] memory tokens, uint256[] memory amounts)
  {
    GovStorage.Base storage gs = GovStorage.gs();

    uint256 length = gs.tokensSherX.length;

    tokens = gs.tokensSherX;
    amounts = new uint256[](length);

    uint256 total = getTotalSherX();

    for (uint256 i; i < length; i++) {
      IERC20 token = gs.tokensSherX[i];

      if (total != 0) {
        PoolStorage.Base storage ps = PoolStorage.ps(token);
        amounts[i] = ps.sherXUnderlying.add(LibPool.getTotalAccruedDebt(token)).mul(_amount).div(
          total
        );
      }
    }
  }

  function accrueSherX(IERC20 _token) external {
    SherXStorage.Base storage sx = SherXStorage.sx();
    uint256 sherX = _accrueSherX(_token, sx.sherXPerBlock);
    if (sherX != 0) {
      LibSherXERC20.mint(address(this), sherX);
    }
  }

  function accrueSherXWatsons() external {
    SherXStorage.Base storage sx = SherXStorage.sx();
    _accrueSherXWatsons(sx.sherXPerBlock);
  }

  function accrueSherX() external {
    // loop over pools, increase the pool + pool_weight based on the distribution weights
    SherXStorage.Base storage sx = SherXStorage.sx();
    GovStorage.Base storage gs = GovStorage.gs();
    uint256 sherXPerBlock = sx.sherXPerBlock;
    uint256 sherX;
    uint256 length = gs.tokensStaker.length;
    for (uint256 i; i < length; i++) {
      sherX = sherX.add(_accrueSherX(gs.tokensStaker[i], sherXPerBlock));
    }
    if (sherX != 0) {
      LibSherXERC20.mint(address(this), sherX);
    }

    _accrueSherXWatsons(sherXPerBlock);
  }

  function _accrueSherXWatsons(uint256 sherXPerBlock) private {
    GovStorage.Base storage gs = GovStorage.gs();

    uint256 sherX =
      block
        .number
        .sub(gs.watsonsSherxLastAccrued)
        .mul(sherXPerBlock)
        .mul(gs.watsonsSherxWeight)
        .div(type(uint16).max);
    // need to settle before return, as updating the sherxperlblock/weight
    // after it was 0 will result in a too big amount (accured will be < block.number)
    gs.watsonsSherxLastAccrued = uint40(block.number);
    if (sherX == 0) {
      return;
    }
    LibSherXERC20.mint(gs.watsonsAddress, sherX);
  }

  function _accrueSherX(IERC20 _token, uint256 sherXPerBlock) private returns (uint256 sherX) {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    uint256 lastAccrued = ps.sherXLastAccrued;
    if (lastAccrued == block.number) {
      return 0;
    }
    sherX = block.number.sub(lastAccrued).mul(sherXPerBlock).mul(ps.sherXWeight).div(
      type(uint16).max
    );
    // need to settle before return, as updating the sherxperlblock/weight
    // after it was 0 will result in a too big amount (accured will be < block.number)
    ps.sherXLastAccrued = uint40(block.number);
    if (address(_token) == address(this)) {
      ps.stakeBalance = ps.stakeBalance.add(sherX);
    } else {
      ps.unallocatedSherX = ps.unallocatedSherX.add(sherX);
      ps.sWeight = ps.sWeight.add(sherX);
    }
  }
}
