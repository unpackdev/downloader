pragma solidity ^0.6.0;
import "./RewardsV2.sol";
import "./ReferralRewardsType5.sol";

contract RewardsType5 is RewardsV2 {
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
    /// @param _rewards Old main farming contract.
    /// @param _referralTree Contract with referral's tree.
    constructor(
        IMintableBurnableERC20 _token,
        IRewards _rewards,
        IReferralTree _referralTree
    ) public RewardsV2(_token, 0, 57870370370) {
        ReferralRewardsType5 newRreferralRewards =
            new ReferralRewardsType5(
                _token,
                _referralTree,
                _rewards,
                IRewardsV2(address(this)),
                [uint256(5000 * 1e18), 2000 * 1e18, 100 * 1e18],
                [[uint256(0), 0, 0], [uint256(0), 0, 0], [uint256(0), 0, 0]],
                [
                    [uint256(6 * 1e16), 2 * 1e16, 1 * 1e16],
                    [uint256(5 * 1e16), 15 * 1e15, 75 * 1e14],
                    [uint256(4 * 1e16), 1 * 1e16, 5 * 1e15]
                ]
            );
        newRreferralRewards.transferOwnership(_msgSender());
        referralRewards = IReferralRewardsV2(address(newRreferralRewards));
    }

    /// @dev Allows to unstake deposit amount.
    /// @param _amount Amount to be unstaked.
    function unstake(uint256 _amount) public {
        updateStakingReward(msg.sender);
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
        emit WithdrawRequested(msg.sender, id, _amount, now + 3 days);
        referralRewards.handleDepositEnd(msg.sender, _amount);
    }

    /// @dev Executes unstake requests if timelock passed.
    /// @param _user Address of the user.
    /// @param _count How many deposits to claim.
    function executeUnstakes(address _user, uint256 _count) internal override {
        _count = (_count == 0)
            ? unstakeRequests[_user].length
            : Math.min(
                unstakeRequests[_user].length,
                requestHead[_user].add(_count)
            );
        for (
            uint256 requestId = requestHead[_user];
            requestId < _count;
            requestId++
        ) {
            Request storage request = unstakeRequests[_user][requestId];
            if (request.timelock < now && request.status == Status.PENDING) {
                request.status = Status.EXECUTED;
                UserInfo storage user = userInfo[_user];
                user.unfrozen = user.unfrozen.sub(request.amount);
                safeTokenTransfer(_user, request.amount);
                emit Withdraw(_user, requestId, request.amount, 0, now);
                requestHead[_user] = requestHead[_user].add(1);
            }
        }
    }

    /// @dev Returns user's unclaimed reward.
    /// @param _includeDeposit Should the finnished deposits be included into calculations.
    /// @return _reward User's reward.
    function getPendingReward(address _user, bool _includeDeposit)
        public
        view
        override
        returns (uint256 _reward)
    {
        UserInfo storage user = userInfo[_user];
        _reward = user.claimable.add(
            now.sub(user.lastUpdate).mul(user.amount).mul(rewardPerSec).div(
                1e18
            )
        );
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

    // /// @dev Returns user's unstake requests length.
    // /// @param _user Address of the user.
    // /// @return Number of unstake requests.
    function getRequestsLength(address _user) public view returns (uint256) {
        return unstakeRequests[_user].length;
    }

    /// @dev Returns unclaimed rewardsV2.
    /// @return All unclaimed rewardsV2.
    function getTotalPendingRewards() public view returns (uint256) {
        return now.sub(lastUpdate).mul(totalStake).mul(rewardPerSec).div(1e18);
    }

    /// @dev Returns assessed rewardsV2.
    /// @return All assessed rewardsV2.
    function getTotalRewards() public view returns (uint256) {
        return
            totalClaimed.add(getTotalPendingRewards()).sub(totalClaimed).div(
                1e18
            );
    }

    /// @dev Returns user's ended deposits.
    /// @param _user Address of the user.
    /// @return _count Number of the deposit's that can be withdrawn.
    function getEndedDepositsCount(address _user)
        public
        view
        override
        returns (uint256 _count)
    {
        for (
            uint256 requestId = requestHead[_user];
            requestId < unstakeRequests[_user].length;
            requestId++
        ) {
            Request storage request = unstakeRequests[_user][requestId];
            if (request.timelock < now && request.status == Status.PENDING) {
                _count = _count.add(1);
            }
        }
    }
}
