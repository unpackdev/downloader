// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.11;

import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Math.sol";
import "./LEGENDZ.sol";
import "./NullHeroes.sol";
import "./HeroStakes.sol";

contract Dungeons is HeroStakes {

    uint8 public force;
    uint8 public intelligence;
    uint8 public agility;
    uint256 public dailyReward;

    constructor(address _legendz, address _nullHeroes, uint256 _dailyReward, uint8 _force, uint8 _intelligence, uint8 _agility) HeroStakes(_legendz, _nullHeroes, 10) {
        dailyReward = _dailyReward;
        force = _force;
        intelligence = _intelligence;
        agility = _agility;
        minDaysToClaim = 1 days;
    }

    function _resolveReward(uint256 _tokenId) internal override returns (uint256) {
        NullHeroes.Hero memory hero = nullHeroes.getHero(_tokenId);

        uint256 seed = _random(_tokenId);
        bool hasWon = _fight(seed, hero);

        return _calculateTotalReward(hero, stakes[_tokenId].lastClaim, hasWon);
    }

    function estimateReward(uint256 _tokenId) public view override returns (uint256) {
        return _calculateBaseReward(stakes[_tokenId].lastClaim, dailyReward);
    }

    function estimateDailyReward() public view override returns (uint256) {
        return dailyReward;
    }

    function estimateDailyReward(uint256 _tokenId) public view override returns (uint256) {
        return dailyReward;
    }

    /**
     * rolls a dice
     * @param seed a pseudorandom number
     * @param size the dice size
     * @return a pseudorandom value
     */
    function _roll(uint256 seed, uint256 size) internal pure returns (uint256) {
        require(size > 0, "die size < 1");
        if (seed < size)
            return seed + 1;
        return (seed % size) + 1;
    }

    /**
     * determines if a hero wins against a mob
     * @param seed a pseudorandom number
     * @param hero the hero
     * @return bool hero's victory
     */
    function _fight(uint256 seed, NullHeroes.Hero memory hero) internal view returns (bool) {
        uint8 _force = force;
        uint8 _intelligence = intelligence;
        uint8 _agility = agility;

        // adds class skill
        uint256 randomAttribute;
        if (hero.class == 0) {// warrior's berserk
            randomAttribute = _roll(uint16(seed), 30);
            if (randomAttribute < 11) { // force
                hero.force *= 2;
            } else if (randomAttribute < 21) { // intelligence
                hero.intelligence *= 2;
            } else if (randomAttribute < 31) { // agility
                hero.agility *= 2;
            }
        } else if (hero.class == 2) { // wizard's curse
            randomAttribute = _roll(uint16(seed), 30);
            if (randomAttribute < 11) { // force
                _force = 1;
            } else if (randomAttribute < 21) { // intelligence
                _intelligence = 1;
            } else if (randomAttribute < 31) { // agility
                _agility = 1;
            }
        } else if (hero.class == 5) { // ranger's headshot
            if(_roll(uint16(seed), 100) < 16) {
                return true;
            }
        }

        // shifts seed
        seed >>= 16;

        // processes fight
        if (hero.class == 3) { // cultist persuasion
            if (_roll(uint16(seed >> 16), 100) < 76)
                randomAttribute = 20;
        } else {
            randomAttribute = _roll(uint16(seed), 40);
        }
        if (randomAttribute < 11) { // force
            return hero.force > _force;
        } else if (randomAttribute < 21) { // intelligence
            return hero.intelligence > _intelligence;
        } else if (randomAttribute < 31) { // agility
            return hero.agility > _agility;
        } else { // attribute sum
            return (hero.force + hero.intelligence + hero.agility) > (_force + _intelligence + _agility);
        }
    }

    /**
     * calculates a total reward including skill bonus of a staked hero
     * @param hero the corresponding hero
     * @param hasWon hero victory flag
     * @return the total reward
     */
    function _calculateTotalReward(NullHeroes.Hero memory hero, uint256 lastClaim, bool hasWon) internal view returns (uint256) {
        uint256 reward;

        // adds class skill
        if (hasWon) {
            reward = _calculateBaseReward(lastClaim, dailyReward);
            if (hero.class == 4) // mercenary's bounty
                reward += reward / 4;
        } else {
            if (hero.class == 1) // rogue's trickery
                reward = _calculateBaseReward(lastClaim, dailyReward) / 4;
        }
        return reward;
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function _random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
                tx.origin,
                blockhash(block.number - 1),
                block.timestamp,
                seed
            )));
    }

    /**
     * updates the dungeon parameters
     * @param _dailyReward the legendz rate per day
     * @param _force mob's force
     * @param _intelligence mob's intelligence
     * @param _agility mob's agility
     */
    function updateDungeon(uint256 _dailyReward, uint8 _force, uint8 _intelligence, uint8 _agility) external onlyOwner {
        dailyReward = _dailyReward;
        force = _force;
        intelligence = _intelligence;
        agility = _agility;
    }

}
