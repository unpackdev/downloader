// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Multicall.sol";
import "./GameFi.sol";
import "./UnsafeMath.sol";

/** Contract handles every single Hero data */
contract HeroManager is Ownable, Multicall {
  using UnsafeMath for uint256;

  IERC20 public token;
  IERC721 public nft;

  address public lobbyManagerAddress;

  uint256 public constant HERO_MAX_LEVEL = 30;
  uint256 public constant HERO_MAX_EXP = 100 * 10**18;

  uint256 public baseLevelUpFee = 50000 * 10**18; // 50,000 $HRI
  uint256 public bonusLevelUpFee = 10000 * 10**18; // 10,000 $HRI

  uint256 public primaryPowerMultiplier = 10;
  uint256 public secondaryMultiplier = 8;
  uint256 public thirdMultiplier = 6;

  uint256 public rarityPowerBooster = 110;

  uint256 public bonusExp = 30 * 10**18; // From Level 1, every battle win will give 30 exp to the hero. And as level goes up, this will be reduced. Level 1 -> 2: 30, Lv 2 -> 3: 29, ...., Lv 29 -> 30: 2
  uint256 public expDiff = 4;

  uint256 public maxHeroEnergy = 5;
  uint256 public energyRecoveryTime = 1 hours;

  mapping(uint256 => GameFi.Hero) public heroes;

  mapping(uint256 => uint256) public heroesEnergy;
  mapping(uint256 => uint256) public heroesEnergyUsedAt;

  constructor(address tokenAddress, address nftAddress) {
    token = IERC20(tokenAddress);
    nft = IERC721(nftAddress);
  }

  function addHero(uint256 heroId, GameFi.Hero calldata hero)
    external
    onlyOwner
  {
    require(heroes[heroId].level == 0, "HeroManager: hero already added");
    heroes[heroId] = hero;
  }

  function levelUp(uint256 heroId, uint256 levels) external {
    uint256 currentLevel = heroes[heroId].level;
    require(nft.ownerOf(heroId) == msg.sender, "HeroManager: not a NFT owner");
    require(currentLevel < HERO_MAX_LEVEL, "HeroManager: hero max level");
    require(
      currentLevel + levels <= HERO_MAX_LEVEL,
      "HeroManager: too many levels up"
    );

    uint256 totalLevelUpFee = levelUpFee(heroId, levels);
    require(
      token.transferFrom(msg.sender, address(this), totalLevelUpFee),
      "HeroManager: not enough fee"
    );

    GameFi.Hero memory hero = heroes[heroId];

    heroes[heroId].level = currentLevel.add(levels);
    heroes[heroId].strength = hero.strength.add(levels.mul(hero.strengthGain));
    heroes[heroId].agility = hero.agility.add(levels.mul(hero.agilityGain));
    heroes[heroId].intelligence = hero.intelligence.add(
      levels.mul(hero.intelligenceGain)
    );
    heroes[heroId].experience = 0;
  }

  function spendHeroEnergy(uint256 heroId) external {
    require(
      msg.sender == lobbyManagerAddress,
      "HeroManager: callable by lobby battle only"
    );
    require(heroEnergy(heroId) > 0, "HeroManager: hero zero energy");

    uint256 currentEnergy = heroesEnergy[heroId];

    if (currentEnergy == maxHeroEnergy) {
      currentEnergy = 1;
    } else {
      currentEnergy = currentEnergy.add(1);

      if (currentEnergy == maxHeroEnergy) {
        heroesEnergyUsedAt[heroId] = block.timestamp;
      }
    }

    heroesEnergy[heroId] = currentEnergy;
  }

  function expUp(uint256 heroId, bool won) public {
    address caller = msg.sender;
    require(
      caller == lobbyManagerAddress || caller == address(this),
      "HeroManager: callable by lobby battle only"
    );
    uint256 hrLevel = heroes[heroId].level;

    if (hrLevel < HERO_MAX_LEVEL) {
      uint256 exp = won
        ? heroBonusExp(heroId)
        : heroBonusExp(heroId).div(expDiff);
      uint256 heroExp = heroes[heroId].experience;
      heroExp = heroExp.add(exp);
      if (heroExp >= HERO_MAX_EXP) {
        heroExp = heroExp.sub(HERO_MAX_EXP);
        hrLevel = hrLevel.add(1);
      }
      heroes[heroId].level = hrLevel;
      heroes[heroId].experience = heroExp;
    }
  }

  function bulkExpUp(uint256[] calldata heroIds, bool won) external {
    require(
      msg.sender == lobbyManagerAddress,
      "HeroManager: callable by lobby battle only"
    );

    for (uint256 i = 0; i < heroIds.length; i = i.add(1)) {
      expUp(heroIds[i], won);
    }
  }

  function levelUpFee(uint256 heroId, uint256 levels)
    public
    view
    returns (uint256)
  {
    uint256 currentLevel = heroes[heroId].level;
    uint256 bonusLvUpFee = bonusLevelUpFee;

    uint256 nextLevelUpFee = baseLevelUpFee.add(
      bonusLvUpFee.mul(currentLevel.sub(1))
    );

    uint256 levelsFee = nextLevelUpFee.mul(levels);
    uint256 totalLevelUpFee = levelsFee.add(
      bonusLvUpFee.mul((levels.mul(levels.sub(1))).div(2))
    );

    return totalLevelUpFee;
  }

  function heroEnergy(uint256 heroId) public view returns (uint256) {
    uint256 maxHE = maxHeroEnergy;
    uint256 energy = heroesEnergy[heroId];

    if (energy < maxHE) {
      return maxHE - energy;
    }

    if (block.timestamp - heroesEnergyUsedAt[heroId] > 1 days) {
      return maxHE;
    }

    return 0;
  }

  function heroPower(uint256 heroId) external view returns (uint256) {
    GameFi.Hero memory hero = heroes[heroId];

    uint256 stat1;
    uint256 stat2;
    uint256 stat3;

    if (hero.primaryAttribute == 0) {
      stat1 = hero.strength;
      stat2 = hero.intelligence;
      stat3 = hero.agility;
    }
    if (hero.primaryAttribute == 1) {
      stat1 = hero.agility;
      stat2 = hero.strength;
      stat3 = hero.intelligence;
    }
    if (hero.primaryAttribute == 2) {
      stat1 = hero.intelligence;
      stat2 = hero.agility;
      stat3 = hero.strength;
    }

    uint256 power = stat1 *
      primaryPowerMultiplier +
      stat2 *
      secondaryMultiplier +
      stat3 *
      thirdMultiplier;

    if (hero.rarity > 0) {
      power = (power * (rarityPowerBooster**hero.rarity)) / (100**hero.rarity);
    }

    return power;
  }

  function heroPrimaryAttribute(uint256 heroId)
    external
    view
    returns (uint256)
  {
    return heroes[heroId].primaryAttribute;
  }

  function heroLevel(uint256 heroId) public view returns (uint256) {
    return heroes[heroId].level;
  }

  function heroBonusExp(uint256 heroId) internal view returns (uint256) {
    uint256 level = heroLevel(heroId);
    return levelExp(level);
  }

  function levelExp(uint256 level) public view returns (uint256) {
    return bonusExp.sub(level.sub(1).mul(10**18));
  }

  function validateHeroIds(uint256[] calldata heroIds, address owner)
    external
    view
    returns (bool)
  {
    for (uint256 i = 0; i < heroIds.length; i = i.add(1)) {
      require(nft.ownerOf(heroIds[i]) == owner, "HeroManager: not hero owner");
    }
    return true;
  }

  function validateHeroEnergies(uint256[] calldata heroIds)
    external
    view
    returns (bool)
  {
    for (uint256 i = 0; i < heroIds.length; i = i.add(1)) {
      require(heroEnergy(heroIds[i]) > 0, "HeroManager: not enough energy");
    }
    return true;
  }

  function setLobbyManager(address lbAddr) external onlyOwner {
    lobbyManagerAddress = lbAddr;
  }

  function setRarityPowerBooster(uint256 value) external onlyOwner {
    rarityPowerBooster = value;
  }

  function setPrimaryPowerMultiplier(uint256 value) external onlyOwner {
    primaryPowerMultiplier = value;
  }

  function setSecondaryMultiplier(uint256 value) external onlyOwner {
    secondaryMultiplier = value;
  }

  function setThirdMultiplier(uint256 value) external onlyOwner {
    thirdMultiplier = value;
  }

  function setBaseLevelUpFee(uint256 value) external onlyOwner {
    baseLevelUpFee = value;
  }

  function setBonusLevelUpFee(uint256 value) external onlyOwner {
    bonusLevelUpFee = value;
  }

  function setBonusExp(uint256 value) external onlyOwner {
    bonusExp = value;
  }

  function setExpDiff(uint256 value) external onlyOwner {
    expDiff = value;
  }

  function setMaxHeroEnergy(uint256 value) external onlyOwner {
    maxHeroEnergy = value;
  }

  function setEnergyRecoveryTime(uint256 value) external onlyOwner {
    energyRecoveryTime = value;
  }

  function withdrawReserves(uint256 amount) external onlyOwner {
    token.transfer(msg.sender, amount);
  }
}
