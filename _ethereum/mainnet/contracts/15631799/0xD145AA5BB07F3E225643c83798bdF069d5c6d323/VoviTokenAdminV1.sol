// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./VoviLibrary.sol";
import "./LibVoviStorage.sol";
import "./LibDiamond.sol";
import "./LibPausable.sol";

contract VoviTokenAdminV1 {
  using VoviLibrary for *;
  using LibVoviStorage for *;
  using LibDiamond for *;
  using LibPausable for *;

  modifier onlyOwner() {
    LibDiamond.enforceIsContractOwner();
    _;
  }

  function addStakingRange(uint256 from, uint256 to, uint256 baseReward) external onlyOwner {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(vs.ranges.length == 0 || vs.ranges[vs.ranges.length - 1].to < from, 'Must add ranges in order');
    for (uint256 i = 0; i < vs.ranges.length; i++) {
      if (VoviLibrary.inRange(from, vs.ranges[i].from, vs.ranges[i].to) || VoviLibrary.inRange(to, vs.ranges[i].from, vs.ranges[i].to)) {
        revert('Ranges cannot intersect');
      }
    }
    vs.ranges.push(LibVoviStorage.StakingRange(from, to, baseReward));
  }

  function getBaseReward(uint256 tokenId) public view returns (uint256) {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    for(uint256 i; i < vs.ranges.length; i++) {
      if (VoviLibrary.inRange(tokenId, vs.ranges[i].from, vs.ranges[i].to)) {
        return vs.ranges[i].baseReward;
      }
    }
    return 0;
  }

  
  function modifyBaseReward(uint256 index, uint256 baseReward) public onlyOwner {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(index < vs.ranges.length, 'Index not in range');
    vs.ranges[index].baseReward = baseReward;
  }

  function finalizeRewardsEnd() external onlyOwner {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(!vs.finalizedRewardsEnd, "already finalized");

    vs.finalizedRewardsEnd = true;
  }

  function setEndingBlock(uint256 _rewardsEnd) external onlyOwner {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(!vs.finalizedRewardsEnd, "already finalized");

    vs.rewardsEnd = _rewardsEnd;
  }

  function pause() external onlyOwner {
    LibPausable.pause();
  }

  function unpause() external onlyOwner {
    LibPausable.unpause();
  }

  function paused() external view returns (bool isPaused) {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    isPaused = vs.paused;
  }
}