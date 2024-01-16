// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./EnumerableSet.sol";
import "./VoviLibrary.sol";
import "./LibVoviStorage.sol";
import "./LibReentrancyGuard.sol";
import "./LibPausable.sol";
import "./LibDiamond.sol";
import "./LibERC20.sol";

contract VoviTokenV1 is IERC721Receiver {
  using EnumerableSet for EnumerableSet.UintSet;

  modifier onlyOwner() {
    LibDiamond.enforceIsContractOwner();
    _;
  }

  function initialise (        
    address _voxelVilleContract,
    address _voxelVilleAvatarsContract,
    address _voviWalletsContract,
    address _adminSigner
  ) external onlyOwner {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    vs.rewardsEnd = 33043333;
    vs.voxelVilleContract = IERC721(_voxelVilleContract);
    vs.voxelVilleAvatarsContract = IERC721(_voxelVilleAvatarsContract);
    vs.voviWalletsContract = IVoviWallets(_voviWalletsContract);
    vs.adminSigner = _adminSigner;

    LibPausable.pause();
  }

  modifier nonReentrant() {
    LibReentrancyGuard.nonReentrant();
    _;
    LibReentrancyGuard.completeNonReentrant();
  }

  modifier whenNotPaused() {
    LibPausable.enforceNotPaused();
    _;
  }

  /// @dev check that the coupon sent was signed by the admin signer
  function _isVerifiedCoupon(bytes32 digest, LibVoviStorage.Coupon memory coupon, address _adminSigner)
    internal
    pure
    returns (bool)
  {
    address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
    require(signer != address(0), 'ECDSA: invalid signature');
    return signer == _adminSigner;
  }

  function onERC721Received(address operator, address, uint256, bytes memory) public view override returns (bytes4) {
    require(operator == address(this), "Operator not staking contract");

    return this.onERC721Received.selector;
  }



  function calculateStakingRewards(uint256 tokenID, LibVoviStorage.Reward memory reward) public view returns (uint256) {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(vs.lastClaimedBlockForToken[tokenID] != 0, "token not staked");

    uint256 toBlock = vs.rewardsEnd < block.number ? vs.rewardsEnd : block.number;
    require(toBlock >= vs.lastClaimedBlockForToken[tokenID], "beyond rewards end");
    return reward.tokens * (toBlock - vs.lastClaimedBlockForToken[tokenID]);    
  }

    function unstakePlots(
    IVoviWallets.Link[] memory links,
    LibVoviStorage.ClaimRequest[] memory requests
  )
    external
    whenNotPaused
    nonReentrant
    includedWallet(links)
  {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(requests.length <= 40 && requests.length > 0, "Unstake: amount prohibited");
    uint256 rewards;
    uint256[] memory avatars = new uint256[](requests.length);
    
    for (uint256 i; i < requests.length; i++) {
      bool rewardVoid = false;
      require(VoviLibrary.isValidReward(requests[i].multReward, vs.adminSigner), 'Invalid reward coupon received');
      require(requests[i].multReward.tokenId == requests[i].tokenId, 'Rewards not in correct order');
      require(vs.voviWalletsContract.isOwnerOf(links, address(vs.voxelVilleContract), requests[i].tokenId), "Unstake: sender not owner");
      address realOwner = vs.voxelVilleContract.ownerOf(requests[i].tokenId);
      require(
        vs.stakedTokens[realOwner].contains(requests[i].tokenId), 
        "Unstake: token not staked"
      );
      bytes32 digest = keccak256(
        abi.encode(requests[i].tokenId, requests[i].listed, requests[i].lastTxDate)
      );
      require(_isVerifiedCoupon(digest, requests[i].coupon, vs.adminSigner), 'Last TX date for token could not be confirmed');
      if (vs.lastTxDates[requests[i].tokenId] != requests[i].lastTxDate || requests[i].listed != 0) {
        // tx dates don't match
        vs.lastTxDates[requests[i].tokenId] = requests[i].lastTxDate;
        vs.lastClaimedBlockForToken[requests[i].tokenId] = block.number;
        rewardVoid = true;
      }
      
      uint256 stakedAvatar = vs.stakedAvatars[requests[i].tokenId];
      if (stakedAvatar != 0) {
        digest = keccak256(
          abi.encode(
            stakedAvatar, requests[i].listedAvatar, requests[i].avatarTxDate
          )
        );
        require(_isVerifiedCoupon(digest, requests[i].avatarCoupon, vs.adminSigner), 'Could not verify avatar TX Dates');
        if (vs.lastAvatarTxDates[stakedAvatar] != requests[i].avatarTxDate || requests[i].listedAvatar != 0) {
          vs.lastAvatarTxDates[stakedAvatar] = requests[i].avatarTxDate;
          vs.lastClaimedBlockForToken[requests[i].tokenId] = block.number;
          rewardVoid = true;
        }
        delete vs.stakedAvatars[requests[i].tokenId];
        delete vs.stakedAvatarsReverse[stakedAvatar];
        avatars[i] = stakedAvatar;
      } else {
        avatars[i] = 0;
      }

      rewards += calculateStakingRewards(requests[i].tokenId, requests[i].multReward);
      if (!rewardVoid && !vs.bulkRewardClaimed[requests[i].tokenId]) {
        rewards += requests[i].multReward.tokens * vs.dailyBlockAverage * vs.bulkRewardDays;
        vs.bulkRewardClaimed[requests[i].tokenId] = true;
      }
      vs.stakedTokens[realOwner].remove(requests[i].tokenId);
      delete vs.lastClaimedBlockForToken[requests[i].tokenId];
    
    }

    LibERC20.mint(msg.sender, rewards);

    emit VoviLibrary.Unstaked(msg.sender, requests, avatars);
    emit VoviLibrary.RewardsClaimed(msg.sender, rewards);
  }

  function claimStakingRewards(
    IVoviWallets.Link[] memory links,
    LibVoviStorage.ClaimRequest[] memory requests
  )
    external
    whenNotPaused
    nonReentrant
    includedWallet(links)
  {
    require(requests.length > 0, "no plot id given");
    
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    
    uint256 rewards;

    uint256[] memory avatars = new uint256[](requests.length);
    for (uint256 i; i < requests.length; i++) {
      bool rewardVoid = false;
      require(VoviLibrary.isValidReward(requests[i].multReward, vs.adminSigner), 'Invalid reward coupon received');
      require(requests[i].multReward.tokenId == requests[i].tokenId, 'Rewards not in correct order');
      require(vs.voviWalletsContract.isOwnerOf(links, address(vs.voxelVilleContract), requests[i].tokenId), "Stake: sender not owner");
      address realOwner = vs.voxelVilleContract.ownerOf(requests[i].tokenId);
      require(
        vs.stakedTokens[realOwner].contains(requests[i].tokenId), 
        "Unstake: token not staked"
      );
      bytes32 digest = keccak256(
        abi.encode(requests[i].tokenId, requests[i].listed, requests[i].lastTxDate)
      );
      require(_isVerifiedCoupon(digest, requests[i].coupon, vs.adminSigner), 'Last TX date for token could not be confirmed');
      if (vs.lastTxDates[requests[i].tokenId] != requests[i].lastTxDate || requests[i].listed != 0) {
        // tx dates don't match
        vs.lastTxDates[requests[i].tokenId] = requests[i].lastTxDate;
        vs.lastClaimedBlockForToken[requests[i].tokenId] = block.number;
        rewardVoid = true;
      }

      uint256 stakedAvatar = vs.stakedAvatars[requests[i].tokenId];
      if (stakedAvatar != 0) {
        digest = keccak256(
          abi.encode(
            stakedAvatar, requests[i].listedAvatar, requests[i].avatarTxDate
          )
        );
        require(_isVerifiedCoupon(digest, requests[i].avatarCoupon, vs.adminSigner), 'Could not verify avatar TX Dates');
        if (vs.lastAvatarTxDates[stakedAvatar] != requests[i].avatarTxDate || requests[i].listedAvatar != 0) {
          vs.lastAvatarTxDates[stakedAvatar] = requests[i].avatarTxDate;
          vs.lastClaimedBlockForToken[requests[i].tokenId] = block.number;
          rewardVoid = true;
        }
        avatars[i] = stakedAvatar;
      } else {
        avatars[i] = 0;
      }  
      
            rewards += calculateStakingRewards(requests[i].tokenId, requests[i].multReward);
      if (!rewardVoid && !vs.bulkRewardClaimed[requests[i].tokenId]) {
        rewards += requests[i].multReward.tokens * vs.dailyBlockAverage * vs.bulkRewardDays;
        vs.bulkRewardClaimed[requests[i].tokenId] = true;
      }
      vs.lastClaimedBlockForToken[requests[i].tokenId] = block.number;
    }

    LibERC20.mint(msg.sender, rewards);
    emit VoviLibrary.RewardsClaimed(msg.sender, rewards);
  }

  function isBulkClaimed(uint256 tokenId) external view returns (bool claimed) {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    claimed = vs.bulkRewardClaimed[tokenId];
  }

  function resetBulkReward(uint256[] calldata tokenIds) external onlyOwner {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    for (uint i = 0; i < tokenIds.length; i++) {
      vs.bulkRewardClaimed[tokenIds[i]] = false;
    }
  }

  function setDailyBlocks(uint256 blocks) external onlyOwner {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    vs.dailyBlockAverage = blocks;
  }

  function setBulkDays(uint256 bulkDays) external onlyOwner {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    vs.bulkRewardDays = bulkDays;
  }

  modifier includedWallet(IVoviWallets.Link[] memory links) {
    bool found = false;
    for (uint256 i = 0; i < links.length; i++) {
      if (links[i].signer == msg.sender) {
        found = true;
        break;
      }
    }
    require(found, "Wallet links do not include sender");
    _;
  }
}