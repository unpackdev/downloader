// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;
import "./TokenSale.sol";
import "./CrowdSaleBonus.sol";

contract CrowdSale is TokenSale {

    uint256 public startTime = 0;
    uint256 public endTime = 0;

    CrowdSaleBonus[] private bonuses;

    constructor(
        address _saleAddress,
        address payable _beneficiary,
        uint256 _tokensForSale,
        uint256 _tokensPerETH,
        uint256 _decimals,
        uint256 _startTime, // 1646179604 | March 2nd, 2022 06:44 GMT
        uint256 _endTime // 1648318680 | March 26th 2022, 18:18 GMT
    ) TokenSale(
        _saleAddress,
        address(0),
        _beneficiary,
        _tokensForSale,
        _tokensPerETH,
        _decimals
    ) lessThan(_startTime, _endTime) {
        startTime = _startTime;
        endTime = _endTime;
        // Add a fallback 1x bonus
        bonuses.push(new CrowdSaleBonus(1, 0, _startTime, _endTime));
    }

    /**
        Adds a bonus multiplier for the period of time specified
    */
    function addBonusMultiplier(
        uint256 _multiplier,
        uint256 _decimals,
        uint256 _startTime,
        uint256 _endTime
    ) saleNotActive ownerRestricted public {
        bonuses.push(new CrowdSaleBonus(_multiplier, _decimals, _startTime, _endTime));
    }

    /**
        Checks if pre-start conditions are met for the sale
    */
    function isStartable() public view virtual override returns (bool) {
        return super.isStartable() && endTime <= token.CROWDSALE_END_TIME();
    }

    /**
        Checks if the sale is active
    */
    function isActive() public view virtual override returns (bool) {
        if (block.timestamp < startTime || block.timestamp > endTime) {
            return false;
        }
        return super.isActive();
    }

    /**
        Returns the equivalent value of tokens for the ETH provided with the bonus multiplier
    */
    function getTotalTokensForETH(uint256 _eth) public view virtual override returns (uint256) {
        uint256 totalTokens = super.getTotalTokensForETH(_eth);
        return getTotalTokensWithBonus(totalTokens);
    }

    /**
        Checks for the highest active bonus multiplier, if there is none active it returns 1
    */
    function getTotalTokensWithBonus(uint256 _totalTokens) internal view returns (uint256) {
        CrowdSaleBonus bonus = findActiveBonus();
        return bonus.calculateAmountWithBonus(_totalTokens);
    }

    /**
        Checks for an active bonus with the highest multiplier
    */
    function findActiveBonus() internal view returns (CrowdSaleBonus activeBonus) {
        uint256 assigned = 0;
        for (uint256 index = 0; index < bonuses.length; index++) {
            CrowdSaleBonus bonus = bonuses[index];
            if (bonus.isActive() == false) {
                continue;
            }

            if (assigned != 0 && bonus.multiplier() < activeBonus.multiplier()) {
                continue;
            }

            assigned = 1;
            activeBonus = bonus;
        }
        return activeBonus;
    }
}