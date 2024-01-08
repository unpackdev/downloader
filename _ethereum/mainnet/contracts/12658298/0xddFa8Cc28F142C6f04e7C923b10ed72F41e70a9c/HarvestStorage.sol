// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import "./IMintNoRewardPool.sol";
import "./IHarvestVault.sol";

contract HarvestStorage {
    /// @notice Info of each user.
    struct UserInfo {
        uint256 amountEth; //how much ETH the user entered with; should be 0 for HarvestSC
        uint256 amountToken; //how much Token was obtained by swapping user's ETH
        uint256 amountfToken; //how much fToken was obtained after deposit to vault
        uint256 underlyingRatio; //ratio between obtained fToken and token
        uint256 userTreasuryEth; //how much eth the user sent to treasury
        uint256 userCollectedFees; //how much eth the user sent to fee address
        uint256 timestamp; //first deposit timestamp; used for withdrawal lock time check
        uint256 earnedTokens;
        uint256 earnedRewards; //before fees
        //----
        uint256 rewards;
        uint256 userRewardPerTokenPaid;
    }

    uint256 public totalToken;
    address public farmToken;
    address public harvestfToken;
    uint256 public ethDust;
    uint256 public treasueryEthDust;
    IMintNoRewardPool public harvestRewardPool;
    IHarvestVault public harvestRewardVault;
    mapping(address => UserInfo) public userInfo;
}
