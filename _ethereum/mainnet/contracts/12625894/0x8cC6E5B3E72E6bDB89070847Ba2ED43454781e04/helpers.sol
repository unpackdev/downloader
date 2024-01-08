pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


import "./math.sol";
import "./basic.sol";
import "./interfaces.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {

  IStakingRewardsFactory constant internal stakingRewardsFactory = 
    IStakingRewardsFactory(0xf39eC5a471edF20Ecc7db1c2c34B4C73ab4B2C19);

  TokenInterface constant internal rewardToken = TokenInterface(0x46cd5AaD71e5a51A0939Eb1284061DBDE3a9bf98);

  function getStakingContract(address stakingToken) internal view returns (address) {
    IStakingRewardsFactory.StakingRewardsInfo memory stakingRewardsInfo =
      stakingRewardsFactory.stakingRewardsInfoByStakingToken(stakingToken);

    return stakingRewardsInfo.stakingRewards;
  }

}