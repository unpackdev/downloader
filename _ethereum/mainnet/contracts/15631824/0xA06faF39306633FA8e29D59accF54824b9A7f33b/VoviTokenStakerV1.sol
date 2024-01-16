// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./EnumerableSet.sol";
import "./VoviLibrary.sol";
import "./LibVoviStorage.sol";
import "./LibReentrancyGuard.sol";
import "./LibPausable.sol";

contract VoviTokenStakerV1 {
  using EnumerableSet for EnumerableSet.UintSet;
  using VoviLibrary for *;
  using LibVoviStorage for *;
  using LibReentrancyGuard for *;
  using LibPausable for *;

  modifier whenNotPaused() {
    LibPausable.enforceNotPaused();
    _;
  }

  modifier nonReentrant() {
    LibReentrancyGuard.nonReentrant();
    _;
    LibReentrancyGuard.completeNonReentrant();
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

  function stakeAvatar(IVoviWallets.Link[] memory links, uint256 property, uint256 avatar, uint256 lastTxDate, uint256 listed, LibVoviStorage.Coupon memory coupon)
    internal whenNotPaused includedWallet(links) {
      LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
      bool isOwner = vs.voviWalletsContract.isOwnerOf(links, address(vs.voxelVilleAvatarsContract), avatar);
      require(isOwner, 'Incorrect owner for avatar');
      require(vs.stakedAvatars[property] == 0, 'Property already has an avatar in it!');
      require(vs.stakedAvatarsReverse[avatar] == 0, 'Avatar is already staked');
      bytes32 digest = keccak256(
        abi.encode(avatar, listed, lastTxDate)
      );
      require(_isVerifiedCoupon(digest, coupon, vs.adminSigner), 'Cannot confirm last Tx Date for avatar');
      vs.lastAvatarTxDates[avatar] = lastTxDate;
      vs.stakedAvatars[property] = avatar;
      vs.stakedAvatarsReverse[avatar] = property;
  }

  //@dev force unstaking an avatar without claiming rewards will lose the multiplier for the entire time
  function unstakeAvatar(IVoviWallets.Link[] memory links, uint256 avatar)
    public whenNotPaused nonReentrant includedWallet(links) {
      LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
      require(vs.stakedAvatarsReverse[avatar] != 0, 'Avatar is not staked');
      bool avatarOwner = vs.voviWalletsContract.isOwnerOf(links, address(vs.voxelVilleAvatarsContract), avatar);
      uint256 property = vs.stakedAvatarsReverse[avatar];
      bool propertyOwner = vs.voviWalletsContract.isOwnerOf(links, address(vs.voxelVilleContract), property);
      
      require(avatarOwner || propertyOwner, 'Caller is not an owner of either the property or the avatar');
      delete vs.stakedAvatars[property];
      delete vs.stakedAvatars[avatar];
  }



  function stakePlots(
    IVoviWallets.Link[] memory links,
    LibVoviStorage.StakeRequest[] calldata requests
  ) external whenNotPaused nonReentrant includedWallet(links) {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(requests.length <= 40 && requests.length > 0, "Stake: amount prohibited");

    for (uint256 i; i < requests.length; i++) {
      require(requests[i].tokenId <= vs.ranges[vs.ranges.length - 1].to, 'This property cannot be staked yet');
      require(vs.voviWalletsContract.isOwnerOf(links, address(vs.voxelVilleContract), requests[i].tokenId), "Stake: sender not owner");
      require(requests[i].listed == 0, 'Stake: Cannot stake listed property');
      bytes32 digest = keccak256(
        abi.encode(requests[i].tokenId, requests[i].listed, requests[i].lastTxDate)
      );
      require(_isVerifiedCoupon(digest, requests[i].coupon, vs.adminSigner), 'Last TX date for token could not be confirmed');
      vs.lastTxDates[requests[i].tokenId] = requests[i].lastTxDate;
      address realOwner = vs.voxelVilleContract.ownerOf(requests[i].tokenId);
      vs.lastClaimedBlockForToken[requests[i].tokenId] = uint128(block.number);
      vs.stakedTokens[realOwner].add(requests[i].tokenId);
      if(requests[i].avatar != 0) {
        require(vs.voviWalletsContract.isOwnerOf(links, address(vs.voxelVilleAvatarsContract), requests[i].avatar), "Stake: sender doesn't own avatar");
        require(requests[i].listedAvatar == 0, 'Stake: Cannot stake listed avatar');
        require(vs.stakedAvatarsReverse[requests[i].avatar] == 0, 'Avatar is already staked');
        require(vs.stakedAvatars[requests[i].tokenId] == 0, 'Property already has an avatar staked');
        digest = keccak256(
          abi.encode(requests[i].avatar, requests[i].listedAvatar, requests[i].avatarTxDate)
        );
        require(_isVerifiedCoupon(digest, requests[i].avatarCoupon, vs.adminSigner), 'Cannot verify last Avatar TX date');
        vs.stakedAvatars[requests[i].tokenId] = requests[i].avatar;
        vs.stakedAvatarsReverse[requests[i].avatar] = requests[i].tokenId;
        vs.lastAvatarTxDates[requests[i].avatar] = requests[i].avatarTxDate;
      }
    }

    emit VoviLibrary.Staked(msg.sender, requests);
  }



  function getStakedAvatarFor(uint256 tokenId) external view returns (uint256) {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    return vs.stakedAvatars[tokenId];
  } 

  function stakedPlotsOf(IVoviWallets.Link[] memory links) external view returns (uint256[] memory) {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    uint256 stakedCount;
    for(uint i; i < links.length; i++) {
      stakedCount += vs.stakedTokens[links[i].signer].length();
    }
    uint256[] memory tokenIds = new uint256[](stakedCount);
    uint256 index;
    for (uint256 i; i < links.length; i++) {
      for (uint256 j; j < vs.stakedTokens[links[i].signer].length(); j++) {
        tokenIds[index++] = vs.stakedTokens[links[i].signer].at(j);
      }
    }

    return tokenIds;
  }    


}