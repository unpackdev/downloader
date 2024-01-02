// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Ownable.sol";
import "./INonfungiblePositionManager.sol";

contract V3Locker is Ownable {
  uint256 public immutable CREATED;
  INonfungiblePositionManager immutable V3_POS_MGR;

  uint256 public lockedTime;

  constructor() {
    CREATED = block.timestamp;
    V3_POS_MGR = INonfungiblePositionManager(
      0xC36442b4a4522E871399CD717aBDD847Ab11FE88
    );
  }

  function getUnlockTime() external view returns (uint256) {
    return CREATED + lockedTime;
  }

  function collect(uint256 _lpId) external {
    V3_POS_MGR.collect(
      INonfungiblePositionManager.CollectParams({
        tokenId: _lpId,
        recipient: owner(),
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      })
    );
  }

  function unlock(uint256 _lpId) external onlyOwner {
    require(block.timestamp > CREATED + lockedTime);
    V3_POS_MGR.transferFrom(address(this), owner(), _lpId);
  }

  function addTime(uint256 _secs) external onlyOwner {
    lockedTime += _secs;
  }
}
