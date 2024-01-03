//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./Types.sol";
import "./LibStorage.sol";
import "./LibConfig.sol";
import "./BaseAccess.sol";

abstract contract BaseConfig is BaseAccess {
    using LibConfig for Types.Config;
   
    function initConfig(Types.Config memory config) internal {
        LibStorage.getConfigStorage().store(config);
        BaseAccess.initAccess();
    }

    function getConfig() external view returns (Types.Config memory) {
        return LibStorage.getConfigStorage().copy();
    }

    function setConfig(Types.Config memory config) public onlyAdmin {
        LibStorage.getConfigStorage().store(config);
    }
    

    /*
    //============== VIEWS ================/
    
    function getStakingToken() external view returns (IERC20) {
        return LibStorage.getConfigStorage().stakingToken;
    }

    function getMinTraderStake() external view returns (uint128) {    
        return LibStorage.getConfigStorage().minTraderStake;
    }

    function getRewardToken() external view returns (IERC20) {
        return LibStorage.getConfigStorage().rewardToken;
    }

    function getMinMinerStake() external view returns (uint128) {
        return LibStorage.getConfigStorage().minMinerStake;
    }

    function getDevTeam() external view returns (address) {
        return LibStorage.getConfigStorage().devTeam;
    }

    function getRewardDistroPeriod() external view returns (uint64) {
        return LibStorage.getConfigStorage().rewardDistroPeriod;
    }

    function getLockoutBlocks() external view returns (uint8) {
        return LibStorage.getConfigStorage().lockoutBlocks;
    }

    function getMinerReward() external view returns (uint128) {
        return LibStorage.getConfigStorage().minerReward;
    }

    function getDevShare() external view returns (uint128) {
        return LibStorage.getConfigStorage().devShare;
    }

    function getMinBounty() external view returns (uint112) {
        return LibStorage.getConfigStorage().minBounty;
    }

    function getMaxGasUsed() external view returns (uint112) {
        return LibStorage.getConfigStorage().maxGasUsed;
    }


    //=============== MUTATIONS ============/


     //the token used for staking (120b)
    function setStakingToken(IERC20 token) external onlyAdmin {
        LibStorage.getConfigStorage().setStakingToken(token);
    }

    function setMinTraderStake(uint128 stake) external onlyAdmin {    
        LibStorage.getConfigStorage().setMinTraderStake(stake);
    }

    function setRewardToken(IERC20 token) external onlyAdmin {
        LibStorage.getConfigStorage().setRewardToken(token);
    }

    function setMinMinerStake(uint128 stake) external onlyAdmin {
        LibStorage.getConfigStorage().setMinMinerStake(stake);
    }

    function setDevTeam(address team) external onlyAdmin {
        LibStorage.getConfigStorage().setDevTeam(team);
    }

    function setRewardDistroPeriod(uint64 period) external onlyAdmin {
        LibStorage.getConfigStorage().setRewardDistroPeriod(period);
    }

    function setLockoutBlocks(uint8 blocks) external onlyAdmin {
        LibStorage.getConfigStorage().setLockoutBlocks(blocks);
    }

    function setMinerReward(uint128 reward) external onlyAdmin {
        LibStorage.getConfigStorage().setMinerReward(reward);
    }

    function setDevShare(uint128 share) external onlyAdmin {
        LibStorage.getConfigStorage().setDevShare(share);
    }

    function setMinBounty(uint112 bounty) external onlyAdmin {
        LibStorage.getConfigStorage().setMinBounty(bounty);
    }

    function setMaxGasUsed(uint112 used) external onlyAdmin {
        LibStorage.getConfigStorage().setMaxGasUsed(used);
    }
    */
}