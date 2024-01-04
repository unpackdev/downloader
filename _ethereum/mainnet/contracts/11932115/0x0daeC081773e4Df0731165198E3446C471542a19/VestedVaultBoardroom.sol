// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Vault.sol";
import "./VaultBoardroom.sol";
import "./IBoardroom.sol";

import "./console.sol";

contract VestedVaultBoardroom is VaultBoardroom {
    uint256 public vestFor;
    using SafeMath for uint256;

    IBoardroom public oldBoardroom;
    bool public everyoneNewDirector = true;

    /**
     * Event.
     */
    event VestingPeriodChanged(uint256 oldPeriod, uint256 period);

    /**
     * Constructor.
     */
    constructor(
        IERC20 token_,
        Vault vault_,
        uint256 vestFor_
    ) VaultBoardroom(token_, vault_) {
        vestFor = vestFor_;
    }

    /**
     * Views/Getters.
     */

    // given an amount and an epoch timestamp; returns what the vested amount would look like
    function getVestedAmount(uint256 amount, uint256 epochTimestamp)
        public
        view
        returns (uint256)
    {
        uint256 vestingEnd = epochTimestamp.add(vestFor);

        // console.log('getVestedAmount: b.time %s', block.timestamp);
        // console.log('getVestedAmount: epochTimestamp %s', epochTimestamp);
        // console.log('getVestedAmount: vestingEnd %s', vestingEnd);

        // see where we are in the current epoch and return vested amount
        // return the full amount
        if (block.timestamp > vestingEnd) return amount;

        // return a partial amount
        if (block.timestamp > epochTimestamp) {
            return
                amount
                    .mul(1e18)
                    .mul(block.timestamp.sub(epochTimestamp))
                    .div(vestFor)
                    .div(1e18);
        }

        return 0;
    }

    // returns the balance as per the last epoch; if the user deposits/withdraws
    // in the current epoch, this value will not change unless another epoch passes
    function getLastEpochBalance(address who) public view returns (uint256) {
        console.log('getLastEpochBalance who %s', who);
        console.log('getLastEpochBalance currentEpoch %s', currentEpoch);

        uint256 validEpoch =
            directorBalanceLastEpoch[who] < currentEpoch.sub(1)
                ? directorBalanceLastEpoch[who]
                : currentEpoch.sub(1);

        console.log('getLastEpochBalance validEpoch %s', validEpoch);

        if (getBondingHistory(who, validEpoch).valid == 1)
            return getBondingHistory(who, validEpoch).balance;

        return 0;
    }

    function getRewardsEarnedThisEpoch(address who)
        public
        view
        returns (uint256)
    {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS =
            boardHistory[latestSnapshotIndex().sub(1)].rewardPerShare;

        console.log('getRewardsEarnedThisEpoch latestRPS %s', latestRPS);
        console.log('getRewardsEarnedThisEpoch storedRPS %s', storedRPS);
        console.log('getLastEpochBalance val %s', getLastEpochBalance(who));

        return getLastEpochBalance(who).mul(latestRPS.sub(storedRPS)).div(1e18);
    }

    function getStartingRPSof(address who) public view returns (uint256) {
        return directors[who].firstRPS;
    }

    function getRewardsEarnedPrevEpoch(address who)
        public
        view
        returns (uint256)
    {
        if (latestSnapshotIndex() < 1) return 0;
        uint256 latestRPS =
            boardHistory[latestSnapshotIndex().sub(1)].rewardPerShare;
        uint256 startingRPS = getStartingRPSof(who);
        return
            getLastEpochBalance(who).mul(latestRPS.sub(startingRPS)).div(1e18);
    }

    function getClaimableRewards(address who) public view returns (uint256) {
        Boardseat memory seat = directors[who];
        uint256 latestFundingTime = boardHistory[boardHistory.length - 1].time;

        uint256 amtEarned = getRewardsEarnedThisEpoch(who);
        uint256 amtVested = getVestedAmount(amtEarned, latestFundingTime);
        uint256 amtPending = getRewardsEarnedPrevEpoch(who);

        console.log(
            'getClaimableRewards: latestFundingTime %s',
            latestFundingTime
        );
        console.log('getClaimableRewards: amtEarned %s', amtEarned);
        console.log('getClaimableRewards: amtVested %s', amtVested);
        console.log('getClaimableRewards: amtPending %s', amtPending);
        console.log('getClaimableRewards: claimed %s', seat.rewardClaimed);

        console.log(
            'getClaimableRewards: token.balanceOf %s',
            token.balanceOf(address(this))
        );

        return amtPending.add(amtVested).sub(seat.rewardClaimed);
    }

    function setVestFor(uint256 period) public onlyOwner {
        emit VestingPeriodChanged(vestFor, period);
        vestFor = period;
    }

    function claimReward() public override directorExists returns (uint256) {
        console.log('claimReward called at: %s', block.timestamp);

        Boardseat storage seat = directors[msg.sender];

        uint256 reward = getClaimableRewards(msg.sender);
        if (reward == 0) return 0;

        seat.lastClaimedOn = block.timestamp;
        seat.rewardClaimed = seat.rewardClaimed.add(reward);
        token.transfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);

        return reward;
    }

    function claimAndReinvestReward() external virtual {
        uint256 reward = claimReward();
        // NOTE: amount has to be approved from the frontend.
        vault.bondFor(msg.sender, reward);
    }

    // this fn is called by the vault
    function updateReward(address director) public onlyVault {
        Boardseat storage seat = directors[director];

        // first time bonding; set firstRPS properly
        uint256 lastBondedEpoch = directorBalanceLastEpoch[director];
        if (lastBondedEpoch == 0) {
            if (everyoneNewDirector || isOldDirector(director)) {
                seat.firstRPS = 0;
            } else {
                uint256 latestRPS = getLatestSnapshot().rewardPerShare;
                seat.firstRPS = latestRPS;
            }
        }

        // just update the user balance at this epoch
        BondingSnapshot memory snap =
            BondingSnapshot({
                epoch: currentEpoch,
                when: block.timestamp,
                valid: 1,
                balance: vault.balanceWithoutBonded(director)
            });

        console.log(
            'vault updated balance %s',
            vault.balanceWithoutBonded(director)
        );
        console.log('vault updated epoch %s', currentEpoch);

        bondingHistory[director][currentEpoch] = snap;
        directorBalanceLastEpoch[director] = currentEpoch;

        // claim rewards?

        // uint256 latestFundingTime = boardHistory[boardHistory.length - 1].time;
        seat.lastSnapshotIndex = latestSnapshotIndex();
    }

    function isOldDirector(address who) public view returns (bool) {
        if (address(oldBoardroom) == address(0)) return false;
        return oldBoardroom.getLastSnapshotIndexOf(who) >= 0;
    }

    function setOldBoardroom(address room) public onlyOwner {
        oldBoardroom = IBoardroom(room);
    }

    function setEveryoneNewDirector(bool val) public onlyOwner {
        everyoneNewDirector = val;
    }

    function resinstateDirectorTo(
        address who,
        uint256 epoch,
        uint256 lastSnapshotIndex,
        uint256 rps
    ) public onlyOwner {
        directorBalanceLastEpoch[who] = epoch;
        directors[who].lastSnapshotIndex = lastSnapshotIndex;
        directors[who].lastRPS = rps;
    }

    function resinstateDirectorsTo(
        address[] memory who,
        uint256 epoch,
        uint256 lastSnapshotIndex,
        uint256 rps
    ) public onlyOwner {
        for (uint256 i = 0; i < who.length; i++) {
            resinstateDirectorTo(who[i], epoch, lastSnapshotIndex, rps);
        }
    }
}
