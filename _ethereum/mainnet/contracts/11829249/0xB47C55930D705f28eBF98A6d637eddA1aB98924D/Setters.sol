// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

import "./Getters.sol";
import "./IBurnableERC20.sol";

/**
 * NOTE: Contract MahaswapV1Pair should be the owner of this controller.
 */
contract Setters is Getters {
    /**
     * Setters.
     */
    function setArthToMahaRate(uint256 val) external onlyOwner {
        arthToMahaRate = val;
    }

    function setIncentiveToken(address newToken) public onlyOwner {
        require(newToken != address(0), 'Pair: invalid token');
        incentiveToken = IBurnableERC20(newToken);
    }

    function setPenaltyPrice(uint256 val) public onlyOwner {
        penaltyPrice = val;
    }

    function setRewardPrice(uint256 val) public onlyOwner {
        rewardPrice = val;
    }

    function setTokenAProtocolToken(bool val) public onlyOwner {
        isTokenAProtocolToken = val;
    }

    function setExpectedVolumePerEpoch(uint256 val) public onlyOwner {
        expectedVolumePerEpoch = val;
    }

    function setAvailableRewardThisEpoch(uint256 val) public onlyOwner {
        availableRewardThisEpoch = val;
    }

    function setMahaPerEpoch(uint256 val) public onlyOwner {
        rewardPerEpoch = val;
    }

    function setUseOracle(bool val) public onlyOwner {
        useOracle = val;
    }
}
