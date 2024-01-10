// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.11;

import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Math.sol";
import "./LEGENDZ.sol";
import "./NullHeroes.sol";
import "./HeroStakes.sol";

contract Lands is HeroStakes {

    constructor(address _legendz, address _nullHeroes) HeroStakes(_legendz, _nullHeroes, 10) {
        minDaysToClaim = 10 days;
    }

    function _resolveReward(uint256 _tokenId) internal override returns (uint256) {
        return _calculateBaseReward(stakes[_tokenId].lastClaim, _getDailyReward(_tokenId));
    }

    function estimateReward(uint256 _tokenId) public view override returns (uint256) {
        return _calculateBaseReward(stakes[_tokenId].lastClaim, _getDailyReward(_tokenId));
    }

    function estimateDailyReward() public pure override returns (uint256) {
        // estimated daily rate on an average of 22 attribute points
        return 110;
    }

    function estimateDailyReward(uint256 _tokenId) public view override returns (uint256) {
        return _getDailyReward(_tokenId);
    }

    /**
     * calculates the daily reward of a hero
     * @param _tokenId the tokenId of the hero
     * return the daily reward of the corresponding hero
     */
    function _getDailyReward(uint256 _tokenId) internal view virtual returns (uint256) {
        NullHeroes.Hero memory hero = nullHeroes.getHero(_tokenId);
        return 5 * (hero.force + hero.intelligence + hero.agility);
    }

}
