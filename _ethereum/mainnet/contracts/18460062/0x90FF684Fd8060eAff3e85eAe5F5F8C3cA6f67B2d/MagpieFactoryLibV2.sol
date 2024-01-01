// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./MintableERC20.sol";
import "./BaseRewardPoolV4.sol";
import "./WombatPoolHelperV4.sol";

library MagpieFactoryLibV2 {

    function createRewarder(
        address _stakingToken,
        address _mainRewardToken,
        address _masterMagpie,
        address _rewardManager
    ) external returns (address) {
        BaseRewardPoolV4 _rewarder = new BaseRewardPoolV4(
            _stakingToken,
            _mainRewardToken,
            _masterMagpie,
            _rewardManager
        );
        return address(_rewarder);
    }

    function createWombatPoolHelper(
        uint256 _pid,
        address _depositToken,
        address _lpToken,
        address _wombatStaking,
        address _masterMagpie,
        address _rewarder,
        address _mWom,
        bool _isNative
    ) public returns (address) {
        WombatPoolHelperV4 pool = new WombatPoolHelperV4(
            _pid,
            _depositToken,
            _lpToken,
            _wombatStaking,
            _masterMagpie,
            _rewarder,
            _mWom,
            _isNative
        );
        return address(pool);
    }

}
