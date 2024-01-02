// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Ops Ltd. All rights reserved.
pragma solidity 0.8.17;

import "./IERC20.sol";

import "./Errors.sol";
import "./AuraRewards.sol";
import "./ISystemRegistry.sol";
import "./IAuraStashToken.sol";
import "./IBaseRewardPool.sol";
import "./IncentiveCalculatorBase.sol";

contract AuraCalculator is IncentiveCalculatorBase {
    address public immutable booster;

    constructor(ISystemRegistry _systemRegistry, address _booster) IncentiveCalculatorBase(_systemRegistry) {
        Errors.verifyNotZero(_booster, "_booster");

        booster = _booster;
    }

    function getPlatformTokenMintAmount(
        address _platformToken,
        uint256 _annualizedReward
    ) public view override returns (uint256) {
        return AuraRewards.getAURAMintAmount(_platformToken, booster, address(rewarder), _annualizedReward);
    }

    /// @dev For the Aura implementation every `rewardToken()` is a stash token
    function resolveRewardToken(address extraRewarder) public view override returns (address rewardToken) {
        IERC20 rewardTokenErc = IBaseRewardPool(extraRewarder).rewardToken();
        IAuraStashToken stashToken = IAuraStashToken(address(rewardTokenErc));
        if (stashToken.isValid()) {
            rewardToken = stashToken.baseToken();
        }
    }
}
