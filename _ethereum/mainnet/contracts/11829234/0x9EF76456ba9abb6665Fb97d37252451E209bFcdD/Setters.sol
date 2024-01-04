// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

import "./Getters.sol";
import "./IBurnableERC20.sol";

/**
 * NOTE: Contract ArthswapV1Pair should be the owner of this controller.
 */
contract Setters is Getters {
    /**
     * Setters.
     */
    function setIncentiveToken(address newToken) public onlyOwner {
        require(newToken != address(0), 'Pair: invalid token');
        incentiveToken = IBurnableERC20(newToken);
    }

    function setPenaltyPrice(uint256 newPenaltyPrice) public onlyOwner {
        penaltyPrice = newPenaltyPrice;
    }

    function setRewardPrice(uint256 newRewardPrice) public onlyOwner {
        rewardPrice = newRewardPrice;
    }

    function setTokenAProtocolToken(bool val) public onlyOwner {
        isTokenAProtocolToken = val;
    }

    function setMahaPerHour(uint256 _rewardPerHour) public onlyOwner {
        rewardPerHour = _rewardPerHour;
    }

    function setUseOracle(bool isSet) public onlyOwner {
        useOracle = isSet;
    }
}
