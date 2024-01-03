pragma solidity ^0.6.0;
import "./Rewards.sol";
import "./ReferralRewardsType2.sol";

contract RewardsType2 is Rewards {
    event WithdrawRequested(
        address indexed user,
        uint256 id,
        uint256 amount,
        uint256 timelock
    );

    struct Request {
        uint256 timelock; // Wnen the unstake can be executed
        uint256 amount; // Amount to be withdrawn
        Status status; // Request status
    }
    enum Status {NONE, PENDING, EXECUTED} // Unstake request status
    mapping(address => Request[]) public unstakeRequests; // Requests list per each user
    mapping(address => uint256) public requestHead; // The first pending unstake request in the user's requests list

    /// @dev Constructor that initializes the most important configurations.
    /// @param _token Token to be staked and harvested.
    /// @param _referralTree Contract with referral's tree.
    constructor(dANT _token, ReferralTree _referralTree)
        public
        Rewards(_token, 0, 57870370370)
    {
        referralRewards = new ReferralRewardsType2(
            _token,
            _referralTree,
            Rewards(address(this)),
            [uint256(5000 * 1e18), 2000 * 1e18, 100 * 1e18],
            [[uint256(0), 0, 0], [uint256(0), 0, 0], [uint256(0), 0, 0]],
            [
                [uint256(6 * 1e16), 2 * 1e16, 1 * 1e16],
                [uint256(5 * 1e16), 15 * 1e15, 75 * 1e14],
                [uint256(4 * 1e16), 1 * 1e16, 5 * 1e15]
            ]
        );
        referralRewards.transferOwnership(_msgSender());
    }

    /// @dev Allows to unstake deposit amount.
    /// @param _amount Amount to be unstaked.
    function unstake(uint256 _amount) public {
        updateStakingReward(msg.sender);
        referralRewards.claimAllDividends(msg.sender);
        UserInfo storage user = userInfo[msg.sender];
        if (_amount == 0) {
            _amount = user.amount;
        }
        user.amount = user.amount.sub(_amount);
        user.unfrozen = user.unfrozen.add(_amount);
        totalStake = totalStake.sub(_amount);
        uint256 id = unstakeRequests[msg.sender].length;
        unstakeRequests[msg.sender].push(
            Request({
                timelock: now + 3 days,
                amount: _amount,
                status: Status.PENDING
            })
        );
        referralRewards.removeDepositReward(msg.sender, _amount);
        emit WithdrawRequested(msg.sender, id, _amount, now + 3 days);
    }

    /// @dev Accumulate new reward and remove old deposits.
    /// @param _user Address of the user.
    /// @return _reward Earned reward.
    function accumulateStakingReward(address _user)
        internal
        override
        returns (uint256)
    {
        UserInfo memory user = userInfo[_user];
        return now.sub(user.lastUpdate).mul(user.amount).mul(rewardPerSec);
    }

    /// @dev Assess new reward.
    /// @param _user Address of the user.
    function updateStakingReward(address _user) internal override {
        super.updateStakingReward(_user);
        executeUnstakes(_user);
    }

    /// @dev Executes unstake requests if timelock passed.
    /// @param _user Address of the user.
    function executeUnstakes(address _user) internal {
        for (
            uint256 requestId = requestHead[_user];
            requestId < unstakeRequests[_user].length;
            requestId++
        ) {
            Request storage request = unstakeRequests[_user][requestId];
            if (request.timelock < now && request.status == Status.PENDING) {
                request.status = Status.EXECUTED;
                UserInfo storage user = userInfo[_user];
                user.unfrozen = user.unfrozen.sub(request.amount);
                safeTokenTransfer(_user, request.amount);
                emit Withdraw(_user, requestId, request.amount, now);
                requestHead[_user] = requestHead[_user].add(1);
            }
        }
    }

    /// @dev Returns user's unclaimed reward.
    /// @param _includeDeposit Should the finnished deposits be included into calculations.
    /// @return _reward User's reward.
    function getPendingReward(address _user, bool _includeDeposit)
        public
        override
        view
        returns (uint256 _reward)
    {
        UserInfo storage user = userInfo[_user];
        _reward = now
            .sub(user.lastUpdate)
            .mul(user.amount)
            .mul(rewardPerSec)
            .div(1e18);
        if (_includeDeposit) {
            for (
                uint256 requestId = requestHead[_user];
                requestId < unstakeRequests[_user].length;
                requestId++
            ) {
                Request storage request = unstakeRequests[_user][requestId];
                if (
                    request.timelock < now && request.status == Status.PENDING
                ) {
                    _reward = _reward.add(request.amount);
                }
            }
        }
    }

    /// @dev Returns claimed and unclaimed user's reward.
    /// @param _user Address of the user.
    /// @return _reward User's reward.
    function getReward(address _user)
        public
        override
        view
        returns (uint256 _reward)
    {
        UserInfo storage user = userInfo[_user];
        _reward = user.reward.add(
            now.sub(user.lastUpdate).mul(user.amount).mul(rewardPerSec).div(
                1e18
            )
        );
    }

    // /// @dev Returns user's unstake requests length.
    // /// @param _user Address of the user.
    // /// @return Number of unstake requests.
    function getRequestsLength(address _user) public view returns (uint256) {
        return unstakeRequests[_user].length;
    }

    /// @dev Returns unclaimed rewards.
    /// @return All unclaimed rewards.
    function getTotalPendingRewards() public view returns (uint256) {
        return now.sub(lastUpdate).mul(totalStake).mul(rewardPerSec).div(1e18);
    }

    /// @dev Returns assessed rewards.
    /// @return All assessed rewards.
    function getTotalRewards() public view returns (uint256) {
        return
            totalClaimed.add(getTotalPendingRewards()).sub(totalClaimed).div(
                1e18
            );
    }

    /// @dev Procces deposit and by returning deposit.
    function handleDepositEnd(address, uint256) internal override {}
}
