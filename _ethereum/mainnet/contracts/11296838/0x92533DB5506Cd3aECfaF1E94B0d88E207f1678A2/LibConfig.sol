//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;
import "./Types.sol";

library LibConfig {


    function store(Types.Config storage cs, Types.Config memory config) public {
        cs.devTeam = config.devTeam;
        cs.minFee = config.minFee;
        cs.penaltyFee = config.penaltyFee;
        cs.lockoutBlocks = config.lockoutBlocks;
        require(cs.devTeam != address(0), "Invalid dev team address");
    }

    function copy(Types.Config storage config) public view returns(Types.Config memory) {
        Types.Config memory cs;
        cs.devTeam = config.devTeam;
        cs.minFee = config.minFee;
        cs.penaltyFee = config.penaltyFee;
        cs.lockoutBlocks = config.lockoutBlocks;
        require(cs.devTeam != address(0), "Invalid dev team address");
        return cs;
    }
    
    /*

    //============== VIEWS ================/
    function getStakingToken(Types.Config storage _config) external view returns (IERC20) {
        return _config.stakingToken;
    }

    function getMinTraderStake(Types.Config storage _config) external view returns (uint128) {    
        return _config.minTraderStake;
    }

    function getRewardToken(Types.Config storage _config) external view returns (IERC20) {
        return _config.rewardToken;
    }

    function getMinMinerStake(Types.Config storage _config) external view returns (uint128) {
        return _config.minMinerStake;
    }

    function getDevTeam(Types.Config storage _config) external view returns (address) {
        return _config.devTeam;
    }

    function getRewardDistroPeriod(Types.Config storage _config) external view returns (uint64) {
        return _config.rewardDistroPeriod;
    }

    function getLockoutBlocks(Types.Config storage _config) external view returns (uint8) {
        return _config.lockoutBlocks;
    }

    function getMinerReward(Types.Config storage _config) external view returns (uint128) {
        return _config.minerReward;
    }

    function getDevShare(Types.Config storage _config) external view returns (uint128) {
        return _config.devShare;
    }

    function getMinBounty(Types.Config storage _config) external view returns (uint112) {
        return _config.minBounty;
    }

    function getMaxGasUsed(Types.Config storage _config) external view returns (uint112) {
        return _config.maxGasUsed;
    }


    //=============== MUTATIONS ============/


     //the token used for staking (120b)
    function setStakingToken(Types.Config storage _config, IERC20 token) external {
        _config.stakingToken = token;
    }

    function setMinTraderStake(Types.Config storage _config, uint128 stake) external{    
        _config.minTraderStake = stake;
    }

    function setRewardToken(Types.Config storage _config, IERC20 token) external{
        _config.rewardToken = token;
    }

    function setMinMinerStake(Types.Config storage _config, uint128 stake) external{
        _config.minMinerStake = stake;
    }

    function setDevTeam(Types.Config storage _config, address team) external{
        _config.devTeam = team;
    }

    function setRewardDistroPeriod(Types.Config storage _config, uint64 period) external{
        _config.rewardDistroPeriod = period;
    }

    function setLockoutBlocks(Types.Config storage _config, uint8 blocks) external{
        _config.lockoutBlocks = blocks;
    }

    function setMinerReward(Types.Config storage _config, uint128 reward) external{
        _config.minerReward = reward;
    }

    function setDevShare(Types.Config storage _config, uint128 share) external{
        _config.devShare = share;
    }

    function setMinBounty(Types.Config storage _config, uint112 bounty) external{
        _config.minBounty = bounty;
    }

    function setMaxGasUsed(Types.Config storage _config, uint112 used) external{
        _config.maxGasUsed = used;
    }
    */
}