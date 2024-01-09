// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";
import "./CollaborativeOwnable.sol";
import "./ERC20Pausable.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract OwlToken is ERC20Pausable, CollaborativeOwnable {
  using SafeMath for uint256;
  using Address for address;
  using Strings for uint256;

  address public nightOwlsAddress = address(0);
  mapping(address => bool) public redeemSources;

  uint256 public startTimestamp;

  uint256 public constant interval = 86400;
  uint256 public rate = 5000000000000000000;

  mapping(address => uint256) public rewards;
  mapping(address => uint256) public lastUpdate;

  constructor() ERC20("Owl Token", "HOOT") {
    startTimestamp = block.timestamp;
    _pause();
  }

  //
  // Public / External
  //

  function redeemTokens(address addr, uint256 tokenAmount) external {
    require(redeemSources[_msgSender()], "forbidden");

    _claimRewardsForAddress(addr);

    require(balanceOf(addr) >= tokenAmount, "insufficent");

    _burn(addr, tokenAmount);
  }

  // Called by the NightOwls contract when a token is transferred
  function onNightOwlTransfer(address from, address to) external {
    require(_msgSender() == nightOwlsAddress, "forbidden");

    if (!paused()) {
      if (from != address(0)) {
        rewards[from] += getPendingReward(from);
        lastUpdate[from] = block.timestamp;
      }
      if (to != address(0)) {
        rewards[to] += getPendingReward(to);
        lastUpdate[to] = block.timestamp;
      }
    }
  }

  function claimRewards() public whenNotPaused {
    _claimRewardsForAddress(_msgSender());
  }

  function getAvailableRewards(address addr) external view returns(uint256) {
    return rewards[addr] + getPendingReward(addr);
  }

  function getlastUpdate(address user) external view returns(uint256) {
    return lastUpdate[user];
  }

  //
  // Private / internal
  //

  function getPendingReward(address addr) internal view returns(uint256) {
    require(nightOwlsAddress != address(0), "night owls address");
    return IERC721(nightOwlsAddress).balanceOf(addr) *
      rate *
      (block.timestamp - (lastUpdate[addr] >= startTimestamp ? lastUpdate[addr] : startTimestamp)) / 
      interval;
  }

  function _claimRewardsForAddress(address addr) internal {
    _mint(addr, rewards[addr] + getPendingReward(addr));
    rewards[addr] = 0;
    lastUpdate[addr] = block.timestamp;
  }

  //
  // Collaborator Access
  //

  function pause() public onlyCollaborator { 
    _pause(); 
  }

  function unpause() public onlyCollaborator { 
    _unpause(); 
  }

  function burn(address addr, uint256 amount) external onlyCollaborator {
    require(addr != address(0), "zero");
    _burn(addr, amount);
  }

  function airDrop(address addr, uint256 amount) external onlyCollaborator {
    require(addr != address(0), "zero");
    _mint(addr, amount);
  }

  function setStartTimestamp(uint256 timestamp) external onlyCollaborator {
    if (timestamp == 0) {
      startTimestamp = block.timestamp;
    } else {
      startTimestamp = timestamp;
    }
  }

  function setRewardRate(uint256 newRate) external onlyCollaborator {
    rate = newRate;
  }

  function setNightOwlsAddress(address newContractAddress) external onlyCollaborator {
    nightOwlsAddress = newContractAddress;
  }

  function addRedeemSource(address addr) external onlyCollaborator {
    redeemSources[addr] = true;
  }

  function removeRedeemSource(address addr) external onlyCollaborator {
    redeemSources[addr] = false;
  }
}