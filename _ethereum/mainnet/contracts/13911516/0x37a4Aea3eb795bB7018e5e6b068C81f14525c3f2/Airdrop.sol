
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Prey.sol";
// 0x7f36182dee28c45de6072a34d29855bae76dbe2f
// 0x2C88aA0956bC9813505d73575f653F69ADa60923
// 0xBDa2481db91fc0F942eD3F53De378Ba45ba9d17E
struct SheepWolf {
  bool isSheep;
  uint8 fur;
  uint8 head;
  uint8 ears;
  uint8 eyes;
  uint8 nose;
  uint8 mouth;
  uint8 neck;
  uint8 feet;
  uint8 alphaIndex;
}

interface IWOLF {
  function ownerOf(uint256 tokenId) external view returns(address);
  function balanceOf(address owner) external view returns(uint);
  function tokenOfOwnerByIndex(address owner, uint index) external view returns(uint);
  function getTokenTraits(uint256 tokenId) external view returns(SheepWolf memory);
}

struct AirdropToken {
  uint256 tokenId;
  bool claimed;
  bool isSheep;
}


contract Airdrop is Ownable, Pausable {

  uint constant WOLF_PER_TOKEN = 10000 ether;
  uint constant SHEEP_PER_TOKEN = 8000 ether;
  uint constant LAND_PER_TOKEN = 5000 ether;
  uint constant FARMER_PER_TOKEN = 5000 ether;

  uint constant MAX_AIRDROP_AMOUNT = 100000000 ether;
   
  IWOLF _wolf;
  IWOLF _land;
  IWOLF _farmer;

  IWOLF _wolfTraits;

  Prey _prey;

  mapping(address => mapping(uint256 => bool)) claimedTokens;

  uint256 public claimedAmount;

  constructor(address wolf_, address land_, address farmer_, address wolfTraits_, address prey_) {
    _wolf = IWOLF(wolf_);
    _land = IWOLF(land_);
    _farmer = IWOLF(farmer_);
    _wolfTraits = IWOLF(wolfTraits_);
    _prey = Prey(prey_);
  }

  function getTokens(address owner, IWOLF wolf) internal view returns(AirdropToken[] memory tokens, uint claimablePrey, uint totalPrey) {
    uint totalCount = wolf.balanceOf(owner);
      if (totalCount > 0) {
        tokens = new AirdropToken[](totalCount);
        
        for (uint256 i = 0; i < totalCount; i++) {
          uint256 tokenId = wolf.tokenOfOwnerByIndex(owner, i);
          bool claimed = claimedTokens[address(wolf)][tokenId];
          
          tokens[i] = AirdropToken({
            tokenId: tokenId,
            claimed: claimed,
            isSheep: false
          });
          uint preyPerToken;
          if (wolf == _land) {
            preyPerToken = LAND_PER_TOKEN;
          } else if (wolf == _farmer) {
            preyPerToken = FARMER_PER_TOKEN;
          }
          
          if (claimed == false) {
            claimablePrey += preyPerToken;
          }
          totalPrey += preyPerToken;
        }
      }
  }

  function tokensByOwner(address owner, bool checkLand, bool checkFarmer, uint256[] calldata wolfTokenIds) public view 
    returns(AirdropToken[] memory wolfs, AirdropToken[] memory lands, AirdropToken[] memory farmers, uint claimablePrey, uint totalPrey) {
    uint claimable;
    uint total;
    if (checkLand) {
      (lands, claimable, total) = getTokens(owner, _land);
      claimablePrey += claimable;
      totalPrey += total;
    }

    if (checkFarmer) {
      (farmers, claimable, total) = getTokens(owner, _farmer);
      claimablePrey += claimable;
      totalPrey += total;
    }
    
    if (wolfTokenIds.length > 0) {
      wolfs = new AirdropToken[](wolfTokenIds.length);
      for (uint256 i = 0; i < wolfTokenIds.length; i++) {
        uint256 tokenId = wolfTokenIds[i];
        address tokenOwner = _wolf.ownerOf(tokenId);
        if (owner == tokenOwner) {
          bool claimed = claimedTokens[address(_wolf)][tokenId];
          bool isSheep = _wolfTraits.getTokenTraits(tokenId).isSheep;

          wolfs[i] = AirdropToken({
            tokenId: tokenId,
            claimed: claimed,
            isSheep: isSheep
          });

          uint preyPerToken;
          if (isSheep) {
            preyPerToken = SHEEP_PER_TOKEN;
          } else {
            preyPerToken = WOLF_PER_TOKEN;
          }
          if (claimed == false) {
            claimablePrey += preyPerToken;
          }
          totalPrey += preyPerToken;
        }
      }
    }
  }

  function claim(bool checkLand, bool checkFarmer, uint256[] calldata wolfTokenIds) external whenNotPaused {
    require(tx.origin == msg.sender, "No Access");
    require(claimedAmount < MAX_AIRDROP_AMOUNT, "No more prey");

    uint256 claimablePrey;
    AirdropToken[] memory wolfs;
    AirdropToken[] memory lands;
    AirdropToken[] memory farmers;
    (wolfs, lands, farmers, claimablePrey,) = tokensByOwner(msg.sender, checkLand, checkFarmer, wolfTokenIds);
    require(claimablePrey > 0, "No token can be claim");

    if (wolfs.length > 0) {
      markTokenClaimed(wolfs, _wolf);
    }
    if (lands.length > 0) {
      markTokenClaimed(lands, _land);
    }
    if (farmers.length > 0) {
      markTokenClaimed(farmers, _farmer);
    }
    
    if (claimedAmount + claimablePrey > MAX_AIRDROP_AMOUNT) {
      claimablePrey = MAX_AIRDROP_AMOUNT - claimedAmount;
    }
    claimedAmount += claimablePrey;
    _prey.mintByCommunity(msg.sender, claimablePrey);
  }

  function markTokenClaimed(AirdropToken[] memory wolfs, IWOLF wolf) internal {
    for (uint256 i = 0; i < wolfs.length; i++) {
      if (wolfs[i].tokenId > 0 && wolfs[i].claimed == false) {
        claimedTokens[address(wolf)][wolfs[i].tokenId] = true;
      }
    }
  }

  function setWolfAddress(address address_) external onlyOwner {
    _wolf = IWOLF(address_);
  }

  function setLandAddress(address address_) external onlyOwner {
    _land = IWOLF(address_);
  }

  function setFarmerAddress(address address_) external onlyOwner {
    _farmer = IWOLF(address_);
  }

  function setPreyAddress(address address_) external onlyOwner {
    _prey = Prey(address_);
  }

  function setWolfTraits(address address_) external onlyOwner {
    _wolfTraits = IWOLF(address_);
  }

}