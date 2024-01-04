pragma solidity ^0.6.0;

contract VaultMock {
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 ZZZRewardDebt; // Reward debt. See explanation below.
        uint256 NAPRewardDebt; // Reward debt. See explanation below.
        uint256 timelockEnd;
        uint256 timelockBoost;
        // Epoch -> User boost
        mapping(uint256 => uint256) boost;
        // Whenever a user deposits or withdraws  tokens to a vault. Here's what happens:
        //   1. The vault's `accNAPPerShare` gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    bool timelocking = true;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => bool) public timelocked;

    function deposit(uint256 _pid, uint256 _amt) external {
        UserInfo storage user = userInfo[_pid][msg.sender];

        user.amount = _amt;
        user.timelockEnd = timelocking ? now + 1 weeks : 0;
        timelocking = !timelocking;
    }

    function isTimelocked(uint256 _pid, address _user) public view returns (bool) {
        return userInfo[_pid][_user].timelockEnd >= now;
    }

    function getUserAmount(address _user, uint256 _vid) external view returns (uint256) {
        return userInfo[_vid][_user].amount;
    }
}
