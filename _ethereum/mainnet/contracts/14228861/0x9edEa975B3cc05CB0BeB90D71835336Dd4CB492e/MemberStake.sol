// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract MemberStake is ReentrancyGuard {
    uint256 public constant THREE_MONTHS = 90 days;
    uint256 public constant STAKE_AMOUNT = 500_000 ether;

    IERC20 public immutable devt;

    struct UserInfo {
        uint256 depositAmount;
        uint256 lockedUntil;
    }

    /// @notice user => UserInfo
    mapping(address => UserInfo) public userInfo;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address _devt) {
        require(_devt != address(0), "set address is zero");
        devt = IERC20(_devt);
    }

    /// @notice staking DEVT
    /// @param _samount is staking devt nums

    function stake(uint256 _samount) external nonReentrant {
        require(userInfo[msg.sender].depositAmount == 0, "already desposit");
        require(_samount >= STAKE_AMOUNT, "not enough amount");
        devt.transferFrom(msg.sender, address(this), _samount);
        userInfo[msg.sender] = UserInfo(
            _samount,
            block.timestamp + THREE_MONTHS
        );

        emit Staked(msg.sender, _samount);
    }

    /// @notice withdraw DEVT
    function withdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.depositAmount > 0, "user does not exists");
        require(block.timestamp >= user.lockedUntil, "user is still locked");

        devt.transfer(msg.sender, user.depositAmount);
        emit Withdrawn(msg.sender, user.depositAmount);
        delete userInfo[msg.sender];
    }
}
