//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

import "./Farm.sol";
contract FarmingFactory is Ownable {

    function createFarm(
        address _rewardsToken,
        address _stakingToken,
        uint _rewardsDuration,
        address _newOwner,
        uint _stakingTokensDecimal
    ) public {
        Farm newFarm = new Farm(_rewardsToken, _stakingToken, _rewardsDuration, _stakingTokensDecimal);
        emit FarmCreated(address(newFarm));
        newFarm.transferOwnership(_newOwner);
    }


    /* ========== EVENTS ========== */
    event FarmCreated(address newFarm);
}
