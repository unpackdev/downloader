// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

/**
 * @dev Interface of the VoteShare.
 */
interface IVote {
    struct TierStruct {
        uint256 tokenAmount;
        uint256 revenueShare;
    }

    struct SnapshotStruct {
        uint256[] usersByTier;
        uint256 balance;
        uint256 timestamp;
    }

    struct VoteStruct {
        bool active;
        uint8 choices;
        uint256 balance;
        uint256 timestamp;
    }

    struct GameStruct {
        bool active;
        uint256 balanceBefore;
        uint256 withdrawTimestamp;
        uint256 balanceAfter;
        uint256 depositTimestamp;
    }

    event TiersSet(TierStruct[] _tiers);
    event VotingPeriodSet(uint256 _period);
    event ProtocolAddressSet(address _address);
    event UpdateAddressSet(address _address);
    event RedeemFeeSet(uint256 fee);
    event VoteStarted(uint8 _choices);
    event VoteEnded(address _sender, uint256[] _winners, uint256 _gameBalance);
    event VoteCasted(address _sender, uint8 _choice);
    event ShareClaimed(address _sender, uint256 _amount, uint256 _fee);
    event RewardClaimed(address _sender, uint256 _amount);
    event ForfeitShare(address _sender, uint256 _amount);
    event ForfeitSharePartial(address _sender, uint256 _amount, uint256 _toProtocol);
    event GameStarted(uint256 _balance);
    event GameEnded(uint256 _balance);

    /// @dev The new address cannot be the zero address.
    error ZeroAddress();

    /// @dev You are trying to complete an action that can be done only when no vote is in progress.
    error VoteActive();

    /// @dev as this contract relies on externally set variables we don't let the owner forfeit access
    error NoRenounce();

    /// @dev Fee exceeds the maximum of 100%.
    error FeeOverflow();

    /// @dev You are trying to complete an action that can be done only when vote is in progress.
    error VoteNotActive();

    /// @dev Action does not respect time limits dependent on currentVote.timestamp and votingPeriod
    error OutOfBounds();

    /// @dev The sum of the tokenAmount(s) of the tiers exceeds the maxSupply
    error TokenTierOverflow();

    /// @dev The sum of the revenueShare(s) of the tiers exceeds 100%
    error ShareTierOverflow();

    /// @dev The updateState input should be equal to number of tiers +1 (the downgrade array as index 0)
    /// @param tiers orrect number of arrays
    error TierArrayLength(uint256 tiers);

    /// @dev Choice should be a number between min and max
    /// @param max index of last choice, is currentVote.choices-1
    error NotAChoice(uint8 max);

    /// @dev Choice should be a number between min and max
    /// @param timestamp user lastAction timestamp
    error LastAction(uint256 timestamp);

    /// @dev User hasn't been assigned any reward tier in snapshot
    error NoTier();

    /// @dev you are trying to set an empty array of tiers;
    error NoTiers();

    /// @dev this function can be accessed only by Update address
    error OnlyUpdate();

    /// @dev user has no pending rewards
    error NoReward();

    /// @dev there aren't enough choices to start a vote
    error NoChoices();

    /// @dev No two consecutive snapshots before a vote
    error NoConsecutiveSnapshot();

    /// @dev You are trying to complete an action that can be done only when no game session is in progress.
    error GameActive();

    /// @dev You are trying to complete an action that can be done only when a game session is in progress.
    error GameNotActive();

    /// @dev Only owner or update address can call this function
    error NotOwnerOrUpdate();
}
