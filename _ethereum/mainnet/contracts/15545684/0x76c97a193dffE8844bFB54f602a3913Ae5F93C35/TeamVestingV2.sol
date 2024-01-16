// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./TeamVesting.sol";

contract TeamVestingV2 is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // cliff period when tokens are frozen
    uint32 public constant CLIFF_MONTHS = 6;

    // period of time when tokens are getting available
    uint32 public constant VESTING_MONTHS_COUNT = 24;

    // seconds in 1 month
    uint32 public constant MONTH = 2628000;

    // tokens that will be delivered
    IERC20 public immutable token;

    struct UserInfo {
        uint256 accumulated;
        uint256 paidOut;
        uint256 vestingStartTime;
        uint256 vestingEndTime;
        bool isStarted;
        bool isImported;
    }

    // user info storage
    mapping(address => UserInfo) public users;

    // vesting duration
    uint40 public immutable vestingPeriod;

    event UsersBatchAdded(address[] users, uint256[] amounts);

    event CountdownStarted(
        uint256 vestingStartTime,
        uint256 vestingEndTime,
        address[] users
    );

    event TokensClaimed(address indexed user, uint256 amount);

    constructor(address tokenAddress, address gnosis) {
        _transferOwnership(gnosis);
        token = IERC20(tokenAddress);

        vestingPeriod = MONTH * (VESTING_MONTHS_COUNT + CLIFF_MONTHS);
    }

    function importUser(address importAddress, TeamVesting oldVesting)
        external
        onlyOwner
    {
        require(
            token.balanceOf(address(oldVesting)) == 0,
            "Vesting: tokens not burned"
        );

        (
            uint256 accumulated,
            uint256 paidOut,
            uint256 vestingStartTime,
            uint256 vestingEndTime,
            bool isStarted
        ) = oldVesting.users(importAddress);

        require(
            !users[importAddress].isImported,
            "Vesting: user already imported"
        );
        require(isStarted, "Vesting: start vesting before");

        users[importAddress] = UserInfo(
            accumulated,
            paidOut,
            // pull vesting start time 6mo back
            vestingStartTime - (MONTH * CLIFF_MONTHS),
            // leave vesting end timestamp unchanged
            vestingEndTime,
            isStarted,
            true
        );
    }

    /**
     * @dev Claims available tokens from the contract.
     */
    function claimToken() external nonReentrant {
        UserInfo memory userInfo = users[msg.sender];

        require(
            (userInfo.accumulated - userInfo.paidOut) > 0,
            "Vesting: nothing to claim"
        );
        require(
            block.timestamp >
                userInfo.vestingStartTime + (MONTH * CLIFF_MONTHS),
            "Vesting: cliff period"
        );

        uint256 availableAmount = calcAvailableToken(
            userInfo.accumulated,
            userInfo.vestingStartTime,
            userInfo.vestingEndTime,
            userInfo.isStarted
        );
        availableAmount -= userInfo.paidOut;

        users[msg.sender].paidOut += availableAmount;

        token.safeTransfer(msg.sender, availableAmount);

        emit TokensClaimed(msg.sender, availableAmount);
    }

    function getUserInfo(address user)
        public
        view
        returns (
            uint256 availableAmount,
            uint256 paidOut,
            uint256 totalAmountToPay,
            uint256 vestingStartTime,
            uint256 vestingEndTime,
            bool isStarted
        )
    {
        UserInfo memory userInfo = users[user];
        return (
            calcAvailableToken(
                userInfo.accumulated,
                userInfo.vestingStartTime,
                userInfo.vestingEndTime,
                userInfo.isStarted
            ) - userInfo.paidOut,
            userInfo.paidOut,
            userInfo.accumulated,
            userInfo.vestingStartTime,
            userInfo.vestingEndTime,
            userInfo.isStarted
        );
    }

    /**
     * @dev calcAvailableToken - calculate available tokens
     * @param _amount  An input amount used to calculate vesting's output value.
     * @return availableAmount_ An amount available to claim.
     */
    function calcAvailableToken(
        uint256 _amount,
        uint256 vestingStartTime,
        uint256 vestingEndTime,
        bool isStarted
    ) private view returns (uint256 availableAmount_) {
        // solhint-disable-next-line not-rely-on-time
        if (!isStarted || block.timestamp <= vestingStartTime) {
            return 0;
        }

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > vestingEndTime) {
            return _amount;
        }

        return
            (_amount *
                // solhint-disable-next-line not-rely-on-time
                (block.timestamp - vestingStartTime)) / vestingPeriod;
    }
}
