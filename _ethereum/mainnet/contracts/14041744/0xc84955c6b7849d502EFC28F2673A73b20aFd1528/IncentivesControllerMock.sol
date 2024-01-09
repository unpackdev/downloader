// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";

contract IncentivesControllerMock is OwnableUpgradeable {

    /**
     * @dev initialize contract
     */
    function initialize () public initializer() {
        OwnableUpgradeable.__Ownable_init();
    }

        /* USER CLAIM REWARDS */
    /**
     * @dev claim all rewards from all markets for a single user
     */
    function claimRewardsAllMarkets(address _account) external pure returns (bool) {
        claimRewardSingleMarketTrA(0, _account);
        claimRewardSingleMarketTrB(0, _account);
        return true;
    }

    /**
     * @dev claim all rewards from a market tranche A for a single user
     * @param _idxMarket market index
     */
    function claimRewardSingleMarketTrA(uint256 _idxMarket, address _account) public pure {
        require (_idxMarket < 9999);
        require (_account != address(0));
    }

    /**
     * @dev claim all rewards from a market tranche B for a single user
     * @param _idxMarket market index
     */
    function claimRewardSingleMarketTrB(uint256 _idxMarket, address _account) public pure {
        require (_idxMarket < 9999);
        require (_account != address(0));
    }

    function trancheANewEnter(address account, address trancheA) external pure {
        require (account != address(0));
        require (trancheA != address(0));
    }
    function trancheBNewEnter(address account, address trancheB) external pure {
        require (account != address(0));
        require (trancheB != address(0));

    }

}