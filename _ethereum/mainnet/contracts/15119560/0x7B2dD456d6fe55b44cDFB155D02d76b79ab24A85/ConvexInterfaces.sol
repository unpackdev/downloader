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

import "./IConvexBooster.sol";

interface IOriginConvexBooster {
    function deposit( uint256 _pid, uint256 _amount, bool _stake ) external returns (bool);
    function withdraw(uint256 _pid, uint256 _amount) external returns(bool);
    function claimStashToken(address _token, address _rewardAddress, address _lfRewardAddress, uint256 _rewards) external;
    function poolInfo(uint256) external view returns(address,address,address,address,address, bool);
    function isShutdown() external view returns(bool);
    function minter() external view returns(address);
    function earmarkRewards(uint256) external returns(bool);
}

interface IOriginConvexRewardPool {
    function getReward() external returns(bool);
    function getReward(address _account, bool _claimExtras) external returns(bool);
    function withdrawAllAndUnwrap(bool claim) external;
    function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);
    function withdrawAll(bool claim) external;
    function withdraw(uint256 amount, bool claim) external returns(bool);
    function stakeFor(address _for, uint256 _amount) external returns(bool);
    function stakeAll() external returns(bool);
    function stake(uint256 _amount) external returns(bool);
    function earned(address account) external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function rewardToken() external returns(address);
    function extraRewards(uint256 _idx) external view returns (address);
    function extraRewardsLength() external view returns (uint256);
}

interface IOriginConvexVirtualBalanceRewardPool {
    function getReward(address _account) external;
    function getReward() external;
    function rewardToken() external returns(address);
}

interface IConvexRewardPool {
    function earned(address account) external view returns (uint256);
    function stake(address _for) external;
    function withdraw(address _for) external;
    function getReward(address _for) external;
    function notifyRewardAmount(uint256 reward) external;

    function extraRewards(uint256 _idx) external view returns (address);
    function extraRewardsLength() external view returns (uint256);
    function addExtraReward(address _reward) external returns(bool);
}

interface IConvexRewardFactory {
    function createReward(address _reward, address _virtualBalance, address _operator) external returns (address);
}

interface ICurveSwap {
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
    /* function remove_liquidity(uint256 _token_amount, uint256[] memory min_amounts) external; */
    function coins(uint256 _coinId) external view returns(address);
    function balances(uint256 _coinId) external view returns(uint256);
}

interface ICurveAddressProvider{
    function get_registry() external view returns(address);
    function get_address(uint256 _id) external view returns(address);
}

interface ICurveRegistry{
    function gauge_controller() external view returns(address);
    function get_lp_token(address) external view returns(address);
    function get_pool_from_lp_token(address) external view returns(address);
    function get_gauges(address) external view returns(address[10] memory,uint128[10] memory);
}