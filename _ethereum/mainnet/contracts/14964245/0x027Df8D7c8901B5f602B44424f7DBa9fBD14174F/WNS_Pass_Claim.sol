// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";

import "./INFTW_Whitelist.sol";
import "./INFTW_Escrow.sol";

contract WNS_Pass_Claim is Ownable, ReentrancyGuard {
  INFTW_Whitelist immutable whitelist;
  INFTWEscrow immutable nftwEscrow;
  IERC721 immutable nftw;
  IERC721 immutable avatars;
  IERC721 immutable grayboys;

  uint256 private constant PREREGISTRATION_PASS_TYPE_ID = 2;

  mapping(uint256 => bool) public worldsClaimed;
  mapping(uint256 => bool) public avatarsClaimed;
  mapping(uint256 => bool) public graysboysClaimed;

  bool public secondClaimEnabled = false;

  constructor(address _whitelist, address _nftw, address _nftwEscrow, address _avatars, address _grayboys) {
    whitelist = INFTW_Whitelist(_whitelist);
    nftw = IERC721(_nftw);
    nftwEscrow = INFTWEscrow(_nftwEscrow);
    avatars = IERC721(_avatars);
    grayboys = IERC721(_grayboys);
  }

  function claim(uint256[] calldata _worldIds, uint256[] calldata _avatarIds, uint256[] calldata _grayboyIds) external nonReentrant {
    uint256 claimTotal = 0;

    for (uint256 i = 0; i < _worldIds.length; i++) {
      uint256 worldId = _worldIds[i];

      INFTWEscrow.WorldInfo memory worldInfo = nftwEscrow.getWorldInfo(worldId);

      require(nftw.ownerOf(worldId) == msg.sender || worldInfo.owner == msg.sender, "Claimer is not owner");
      require(!worldsClaimed[worldId], "Pass already claimed for world");

      worldsClaimed[worldId] = true;
      claimTotal++;
    }

    if (_avatarIds.length > 0 || _grayboyIds.length > 0) {
      require(secondClaimEnabled, "Second claim for avatars and gray boys is not yet enabled.");

      for (uint256 i = 0; i < _avatarIds.length; i++) {
        uint256 avatarId = _avatarIds[i];

        require(avatars.ownerOf(avatarId) == msg.sender, "Claimer is not owner");
        require(!avatarsClaimed[avatarId], "Pass already claimed for avatar");

        avatarsClaimed[avatarId] = true;
        claimTotal++;
      }

      for (uint256 i = 0; i < _grayboyIds.length; i++) {
        uint256 grayboyId = _grayboyIds[i];

        require(grayboys.ownerOf(grayboyId) == msg.sender, "Claimer is not owner");
        require(!graysboysClaimed[grayboyId], "Pass already claimed for gray boy");

        graysboysClaimed[grayboyId] = true;
        claimTotal++;
      }
    }

    if (claimTotal > 0) {
      whitelist.mintTypeToAddress(PREREGISTRATION_PASS_TYPE_ID, claimTotal, msg.sender);
    }
  }

  function toggleSecondClaim(bool _enabled) external onlyOwner {
    secondClaimEnabled = _enabled;
  }
}
