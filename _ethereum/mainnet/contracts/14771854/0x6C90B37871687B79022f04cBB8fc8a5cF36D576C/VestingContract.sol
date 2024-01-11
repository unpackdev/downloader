// SPDX-License-Identifier: UNLICENSED

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./ReentrancyGuard.sol";
import "./console.sol";

pragma solidity ^0.8.4;

/**
 * @title HighstackVestingVault
 * @dev HighstackVestingVault is a vesting contract that vests tokens
 * over a period of time via predefined intervals and percentages per
 * interval.
 */
contract HighstackVestingVault is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // ERC20 token being held by this contract
    ERC20 public vestingToken;

    // Vesting configuration
    uint64 public vestStartTime; // seconds
    uint256 public vestIntervalCount;
    uint256 public vestIntervalDuration;

    bool public isFinished = false;

    // Data about users.
    struct UserInfo {
        uint256 periodsClaimed; // How many vesting periods the user has already claimed.
        uint256 totalClaimable; // How many tokens the user is entitled to.
    }
    mapping(address => UserInfo) public users;

    receive() external payable {}

    constructor(address _vestingToken) {
        vestingToken = ERC20(_vestingToken);
    }

    /**
     * @notice Used by owner to configure vesting periods.
     * NOTE: This contract linearlly vests. Meaning if there's 10 periods, then each period
     * releases 10% of the total amount of tokens to users.
     */
    function setVestingConfiguration(
        uint64 _vestStartTime, // when vesting starts
        uint256 _vestIntervalCount, // how many time periods
        uint256 _vestIntervalDuration // duration of each time period.
    ) public onlyOwner {
        vestStartTime = _vestStartTime;
        vestIntervalCount = _vestIntervalCount;
        vestIntervalDuration = _vestIntervalDuration;
    }

    function addUsersToVestList(
        address[] memory userAddresses,
        uint256 usersTokenCountToVest
    ) public onlyOwner {
        require(
            usersTokenCountToVest.mul(userAddresses.length) <=
                vestingToken.balanceOf(address(this)),
            "HS-VestingVault: The vault does not contain enough tokens to support these users"
        );
        for (uint256 _i = 0; _i < userAddresses.length; _i++) {
            UserInfo memory user = users[userAddresses[_i]];
            if (user.totalClaimable == 0) {
                users[userAddresses[_i]] = UserInfo({
                    totalClaimable: usersTokenCountToVest,
                    periodsClaimed: 0
                });
            }
        }
    }

    function blacklistUser(address blacklistedAddress) public onlyOwner {
        users[blacklistedAddress] = UserInfo({
            totalClaimable: 0,
            periodsClaimed: 0
        });
    }

    function calcVestedTokens(address userAddr)
        public
        view
        returns (uint256 _vestedTokens, uint256 _periodsNotClaimed)
    {
        if (isFinished) {
            return (0, 0);
        }
        require(
            block.timestamp > vestStartTime,
            "HS-VestingVault: Vesting hasn't started yet"
        );
        UserInfo memory user = users[userAddr];
        uint256 vestPeriodsPassed = (
            ((block.timestamp).sub(vestStartTime)).div(vestIntervalDuration)
        ).add(1);
        vestPeriodsPassed = Math.min(vestPeriodsPassed, vestIntervalCount);
        uint256 vestedTokens = user.totalClaimable.div(vestIntervalCount).mul(
            vestPeriodsPassed.sub(user.periodsClaimed)
        );
        return (vestedTokens, vestPeriodsPassed.sub(user.periodsClaimed));
    }

    function claimTokens() public nonReentrant {
        require(
            isFinished == false,
            "HS-VestingVault: This vesting vault is complete and nothing else can be claimed."
        );
        UserInfo memory user = users[msg.sender];
        (uint256 vestedTokens, uint256 periodsToClaim) = calcVestedTokens(
            msg.sender
        );
        require(
            vestedTokens > 0,
            "HS-VestingVault: User has no claimable tokens at the current time"
        );
        user.periodsClaimed = user.periodsClaimed + periodsToClaim;
        users[msg.sender] = user;
        vestingToken.transfer(msg.sender, vestedTokens);
    }

    function emergencyWithdraw() public onlyOwner {
        uint256 balance = vestingToken.balanceOf(address(this));
        vestingToken.transfer(msg.sender, balance);
        payable(msg.sender).transfer(address(this).balance);
        isFinished = true;
    }
}
