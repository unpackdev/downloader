pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IFeePool.sol";
import "./IRewardEscrow.sol";
import "./ISynthetix.sol";
import "./IStakingRewards.sol";

interface ISNX is ISynthetix {
    function balanceOf(address account) external view returns(uint);
}

contract StakingGetter {

    struct StakedTokenResult {
        address rewardContract;
        uint stakedBalance;
        uint earnedAmount;
    }
    struct RewardResult {
        uint susdFeesAvailable;
        uint snxRewardsAvailable;
        uint snxBalance;
        uint escrowBalance;
        uint collateral;
        uint transferableSynthetix;
        uint collateralizationRatio;
        StakedTokenResult[] stakedTokenResults;
    }

    IFeePool private constant FEE_POOL = IFeePool(0x013D16CB1Bd493bBB89D45b43254842FadC169C8);
    ISNX private constant SYNTHETIX = ISNX(0xf87A0587Fe48Ca05dd68a514Ce387C0d4d3AE31C);
    IRewardEscrow private constant REWARD_ESCROW = IRewardEscrow(0xb671F2210B1F6621A2607EA63E6B2DC3e2464d1F);

    constructor () public {}

    function getAllStakingRewards(address[] memory wallets, address[] memory rewards) public view returns (RewardResult[] memory results) {
        results = new RewardResult[](wallets.length);
        for (uint i = 0; i < wallets.length; i++) {
            results[i] = getRewardResult(wallets[i], rewards);
        }
        return results;
    }

    function getRewardResult(address wallet, address[] memory rewards) public view returns (RewardResult memory result) {
        (uint susdFeesAvailable, uint snxRewardsAvailable) = FEE_POOL.feesAvailable(wallet);
        uint snxBalance = SYNTHETIX.balanceOf(wallet);
        uint escrowBalance = REWARD_ESCROW.totalEscrowedAccountBalance(wallet);
        uint collateral = SYNTHETIX.collateral(wallet);
        uint transferableSynthetix = SYNTHETIX.transferableSynthetix(wallet);
        uint collateralizationRatio = SYNTHETIX.collateralisationRatio(wallet);
        StakedTokenResult[] memory stakedTokenResults = getStakedTokenResults(wallet, rewards);
        return RewardResult(
            susdFeesAvailable,
            snxRewardsAvailable,
            snxBalance,
            escrowBalance,
            collateral,
            transferableSynthetix,
            collateralizationRatio,
            stakedTokenResults
        );
    }

    function getStakedTokenResults(address wallet, address[] memory rewards) public view returns (StakedTokenResult[] memory stakedTokenResults) {
        stakedTokenResults = new StakedTokenResult[](rewards.length);
        for (uint i = 0; i < rewards.length; i++) {
            IStakingRewards rewardContract = IStakingRewards(rewards[i]);
            uint stakedBalance = rewardContract.balanceOf(wallet);
            uint earnedAmount = rewardContract.earned(wallet);
            stakedTokenResults[i] = StakedTokenResult(address(rewardContract), stakedBalance, earnedAmount);
        }
        return stakedTokenResults;
    }
}