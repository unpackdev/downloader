// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./IOrionVoting.sol";
import "./IOrionGovernance.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract OrionVoting is IOrionVoting, ReentrancyGuardUpgradeable, OwnableUpgradeable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    //  State flags
    uint8 constant kVoteAvailable = 1;
    uint8 constant kCeaseAvailable = 2;
    uint8 constant kRewardsAvailable = 4;

    //  We constantly
    //  New accumulator variables

    //  Calculated-per-pool state.
    struct OrionPoolState
    {
        uint8 state;

        //  Overall pool supply (in ORN)
        uint56  votes;

        //  And "paid" (already used) value of acc_reward_per_voting_token_ at this time
        uint256 last_acc_reward_per_voting_token;

        //  And pool own accumulator
        //      It stores pool-rewards-per-second (ORN * 10**18 / sec)
        uint256 acc_reward;
    }

    //  User-voted-per-stakingrewards state. Now holds only amount, but can grow
    struct UserVotingState
    {
        uint56 voted_amount;
    }

    ///////////////////////////////////////////////////
    //  Data fields
    //  NB: Only add new fields BELOW any fields in this section

    IOrionGovernance private governance_;
    IERC20 public rewards_token_;

    //  Pool vote states
    mapping(address => OrionPoolState) public pool_states_;

    //  Payment for 1 voted ORN in 1 second (10**18 / sec)
    uint256  acc_reward_per_voting_token_;

    uint64   last_update_time_;

    //  Max total supply is the max ORN count - i.e. 10**8 * 10**8 = 10**16 < uint56
    uint56 public total_supply_;

    //  1 / sec
    uint64 public reward_rate_;

    mapping(address => mapping(address => UserVotingState)) public user_votes_;

    //  Add new data fields there....
    //      ...

    //  End of data fields
    /////////////////////////////////////////////////////

    //  Constructor
    function initialize(
        address rewards_token,
        address governance_contract_address
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        rewards_token_ = IERC20(rewards_token);
        governance_ = IOrionGovernance(governance_contract_address);
    }

    //  Sets the pool state (if state not set - users can't do anything with pool)
    function setPoolState(address pool_address, uint8 new_state) external onlyOwner
    {
        pool_states_[pool_address].state = new_state;
    }

    //  Set the overall reward
    function setRewards(uint64 rewards, uint64 duration) external onlyOwner updateVotes(address(0))
    {
        require(duration > 0, "ID1");
        //  We can set rewards to 0
        //  require(rewards > 0, "invalid rewards");

        //  ORN / sec
        reward_rate_ = rewards / duration;
    }

    function vote(address poolAddress, uint56 amount) public nonReentrant updateVotes(poolAddress)
    {
        require(pool_states_[poolAddress].state & kVoteAvailable != 0, "VNA");  //  Vptes not available

        //  Sanity check
        require(amount > 0, "IVS");
        governance_.acceptLock(msg.sender, amount);
        //  At least, user has these money

        //////////////////////////////////////////////////////////////////////
        total_supply_ = total_supply_ + amount;
        pool_states_[poolAddress].votes = pool_states_[poolAddress].votes + amount;
        user_votes_[poolAddress][msg.sender].voted_amount += amount;
    }

    function cease(address poolAddress, uint56 amount) public nonReentrant updateVotes(poolAddress)
    {
        require(pool_states_[poolAddress].state & kCeaseAvailable != 0, "CNA");

        require(amount > 0, "ICS"); //  Invalid cease size
        governance_.acceptUnlock(msg.sender, amount);

        uint56 user_voted_amount = user_votes_[poolAddress][msg.sender].voted_amount;
        require(user_voted_amount >= amount, "AOF");
        user_votes_[poolAddress][msg.sender].voted_amount = user_voted_amount - amount;

        //////////////////////////////////////////////////////////////////////
        total_supply_ = total_supply_ - amount;
        pool_states_[poolAddress].votes = pool_states_[poolAddress].votes - amount;
    }


    //  Views
    function totalSupply() external view returns (uint56) {
        return total_supply_;
    }

    function votes(address pool_address) external view returns(uint56)
    {
        return pool_states_[pool_address].votes;
    }

    //  It will be ORN / ORN, i.e just number
    function getRewardPerVotingToken() public view returns (uint256) {
        if (total_supply_ == 0) {
            return acc_reward_per_voting_token_;
        } else {
            return
                acc_reward_per_voting_token_.add(
                    block.timestamp.sub(last_update_time_).mul(uint256(reward_rate_)).mul(1e18).div(total_supply_)
                );
        }
    }

    function getPoolRewards(address pool_address) override public view returns (uint256) {
        return uint256(pool_states_[pool_address].votes)
            .mul(getRewardPerVotingToken().sub(pool_states_[pool_address].last_acc_reward_per_voting_token))
            .add(pool_states_[pool_address].acc_reward);
    }

    function claimRewards(uint56 amount, address to) override external {
        //  It MUST be non-reentrant at level of calling contract
        require(pool_states_[msg.sender].state & kRewardsAvailable != 0, "RNA");
        rewards_token_.safeTransfer(to, amount);
    }

    /* ========== MODIFIERS ========== */

    modifier updateVotes(address poolAddress) {
        acc_reward_per_voting_token_ = getRewardPerVotingToken();
        last_update_time_ = uint64(block.timestamp);

        if (poolAddress != address(0)) {
            pool_states_[poolAddress].acc_reward = getPoolRewards(poolAddress);
            pool_states_[poolAddress].last_acc_reward_per_voting_token = acc_reward_per_voting_token_;
        }
        _;
    }
}
