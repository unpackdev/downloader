// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Structs.sol";
import "./InterfacesMigrated.sol";
import "./console.sol";

contract SacrificialPit is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable{


  /*///////////////////////////////////////////////////////////////
                    GLOBAL STATE
    //////////////////////////////////////////////////////////////*/

  // reference to the FnG NFT contract
  IFnGMig public fngNFT;
  // reference to the $FBX contract for minting $FBX earnings
  IFBX public fbx;
  // freaks burned 
  uint256 public burnedFreaks;
  // freaks required to burn to receive soul forging
  uint256 public reqFreaks;
  // number of soul forges claimed
  uint256 public soulForges;
  // cost in $FBX to fuse same species freaks
  uint256 public fusionPrice;
  // cost in $FBX to fuse different species freaks;
  uint256 public xSpeciesFusionPrice;
  // same species fusion enabled
  bool public fusionEnabled;
  // cross species fustion enabled
  bool public xSpeciesFusionEnabled;
  // sacrifice enabled
  bool public sacrificeEnabled;



  /*///////////////////////////////////////////////////////////////
                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  function initialize(address _fng, address _fbx) public initializer {
    __UUPSUpgradeable_init();
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();
    fngNFT = IFnGMig(_fng);
    fbx = IFBX(_fbx);
    _pause();
    reqFreaks = 3;
    sacrificeEnabled = true;
    fusionEnabled = true;
    xSpeciesFusionEnabled = true;
    fusionPrice = 2000 ether;
    xSpeciesFusionPrice = 4000 ether;
  }

  function _authorizeUpgrade(address) internal onlyOwner override {}

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  /*///////////////////////////////////////////////////////////////
                    VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  function getReqFreaks(uint256 celestials) external view returns(uint256) {
    uint256 freaksRequired = reqFreaks;
    uint256 freaksRequiredReturned = 0;
    uint256 soulsForged = soulForges;
    for (uint256 i = 0; i < celestials; i++) {
      if (soulsForged == 0) {
      freaksRequiredReturned += freaksRequired; 
      } else {
      if (soulsForged % 500 == 0) {
        freaksRequired += 1;
      }
      freaksRequiredReturned += freaksRequired; 
      }    
      soulsForged += 1;
    }
    return freaksRequiredReturned;
  }


  /*///////////////////////////////////////////////////////////////
                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  function sacrifice(uint256[] memory freakIds, uint256[] memory celestialIds) external whenNotPaused nonReentrant {
      require(sacrificeEnabled == true, "sacrificial pit is out of order");
      require(freakIds.length != 0, "cant sacrifice no freaks");
      require(celestialIds.length !=0, "cant give soul forging to no celestials");
      uint256 celestialIndex = 0;
      for (uint256 i = 0; i < freakIds.length; i++) {
          require(fngNFT.ownerOf(freakIds[i]) == msg.sender, "you don't own this token ser");
          require(celestialIndex < celestialIds.length, "not enough celestials");
          require(fngNFT.isFreak(freakIds[i]), "token is not a freak");
          fngNFT.burn(freakIds[i]);
          burnedFreaks += 1;
          if((i + 1) % reqFreaks == 0){
            CelestialV2 memory currAttributes = fngNFT.getCelestialAttributes(celestialIds[celestialIndex]);
            currAttributes.forging = 11;
            fngNFT.updateCelestialAttributes(celestialIds[celestialIndex], currAttributes);
            soulForges += 1;
            celestialIndex++;
            if (soulForges % 500 == 0) {
              reqFreaks += 1;
            }
          }
      }
      require(celestialIndex == celestialIds.length, "not enough freaks");
  }

  function freakyFuse(uint256[] memory freakIds) external whenNotPaused nonReentrant {
    require(fusionEnabled == true, "freaky fusion not enabled");
    require(freakIds.length % 2 == 0, "can only fuse groups of 2 freaks");
    uint256 price = 0 ether;
    for (uint256 i = 0; i < freakIds.length; i += 2) {
      require(fngNFT.getSpecies(freakIds[i]) == fngNFT.getSpecies(freakIds[i + 1]), "cant fuse freaks of different species");
      require(fngNFT.ownerOf(freakIds[i]) == msg.sender && fngNFT.ownerOf(freakIds[i + 1]) == msg.sender, "you don't own this token ser");
      Freak memory freakA = fngNFT.getFreakAttributes(freakIds[i]);
      Freak memory freakB = fngNFT.getFreakAttributes(freakIds[i + 1]);
      if (freakB.power > freakA.power) {
        freakA.power = freakB.power;
      } 
      if (freakB.health > freakA.health) {
        freakA.health = freakB.health;
      }
      if (freakB.criticalStrikeMod > freakA.criticalStrikeMod) {
        freakA.criticalStrikeMod = freakB.criticalStrikeMod;
      }
      fngNFT.updateFreakAttributes(freakIds[i], freakA);
      fngNFT.burn(freakIds[i + 1]);
      price += fusionPrice;
    }
    fbx.burn(msg.sender, price);
  }

  function freakyFuseXSpecies(uint256[] memory freakIds) external whenNotPaused nonReentrant {
    require(xSpeciesFusionEnabled == true, "cross species freaky fusion not enabled");
    require(freakIds.length % 2 == 0, "can only fuse groups of 2 freaks");
    uint256 price = 0 ether;
    for (uint256 i = 0; i < freakIds.length; i += 2) {
      require(fngNFT.ownerOf(freakIds[i]) == msg.sender && fngNFT.ownerOf(freakIds[i + 1]) == msg.sender);
      Freak memory freakA = fngNFT.getFreakAttributes(freakIds[i]);
      Freak memory freakB = fngNFT.getFreakAttributes(freakIds[i + 1]);
      if (freakB.power > freakA.power) {
        freakA.power = freakB.power;
      } 
      if (freakB.health > freakA.health) {
        freakA.health = freakB.health;
      }
      if (freakB.criticalStrikeMod > freakA.criticalStrikeMod) {
        freakA.criticalStrikeMod = freakB.criticalStrikeMod;
      }
      fngNFT.updateFreakAttributes(freakIds[i], freakA);
      fngNFT.burn(freakIds[i + 1]);
      price += xSpeciesFusionPrice;
    }
    fbx.burn(msg.sender, price);
  }


  /*///////////////////////////////////////////////////////////////
                   ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  function setContracts(address _fngNFT, address _fbx) external onlyOwner {
    fngNFT = IFnGMig(_fngNFT);
    fbx = IFBX(_fbx);
  }

  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  function setXSpeciesFusionEnabled(bool _enabled) external onlyOwner {
    xSpeciesFusionEnabled = _enabled;
  }

  function setFusionEnabled(bool _enabled) external onlyOwner {
    fusionEnabled = _enabled;
  }

  function setSacrificeEnabled(bool _enabled) external onlyOwner {
    sacrificeEnabled = _enabled;
  }

  function setFusionPrice(uint256 _price) external onlyOwner {
    fusionPrice = _price;
  }

  function setXSpeciesFusionPrice(uint256 _price) external onlyOwner {
    xSpeciesFusionPrice = _price;
  }
}
