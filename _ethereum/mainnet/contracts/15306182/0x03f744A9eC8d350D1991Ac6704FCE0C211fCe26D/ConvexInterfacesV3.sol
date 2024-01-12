// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./ConvexInterfacesV2.sol";
import "./IConvexBoosterV2.sol";

interface IConvexRewardPoolV3 {
    function getReward(address _for) external;
    function getReward(address _rewardToken, address _for) external;
    function earned(address _rewardToken, address _for) external view returns (uint256);
    function addRewardPool(address _rewardToken) external;
    function stake(address _for) external;
    function withdraw(address _for) external;
    function notifyRewardAmount(address _rewardToken, uint256 _rewards) external;
}

interface IConvexRewardFactoryV3 {
    // function rewardPools(uint256 _pid) external;
    function createReward(address _virtualBalance, address _depositer, address _owner) external returns (address);
}
