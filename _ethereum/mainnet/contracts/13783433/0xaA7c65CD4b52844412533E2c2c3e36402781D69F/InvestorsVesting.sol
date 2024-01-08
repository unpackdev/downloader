// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract InvestorsVesting is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // constant for percent calculation
    uint8 public constant PERCENT_PRECISION = 100;

    // 10% will be allocated upfront on TGE
    uint8 public constant TGE_AVAILIBLE_PERCENT = 10;

    // do I need to say something here? :)
    uint32 public constant MONTHS_COUNT = 12;

    // seconds in 1 month
    uint32 public constant MONTH = 2628000;

    // Tokens that will be delivered
    IERC20 public immutable token;

    struct UserInfo {
        uint256 accumulated;
        uint256 paidOut;
    }

    // user info storage
    mapping(address => UserInfo) public users;

    // users list for enumerating
    address[] public usersList;

    // from this timestamp 10% of tokens are available and rest of 90% are
    // gradually getting available
    uint256 public vestingStartTime;

    // sum of all tokens to be paid
    uint256 public totalTokensToPay;

    // sum of all tokens has been paid
    uint256 public totalTokensPaid;

    // from this timestamp 100% of tokens are available
    uint256 public vestingEndTime;

    uint40 public immutable vestingPeriod;

    // is vesting countdown live
    bool public isStarted;

    event UsersBatchAdded(address[] users, uint256[] amounts);

    event CountdownStarted(uint256 vestingStartTime, uint256 vestingEndTime);

    event TokensClaimed(address indexed user, uint256 amount);

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);

        vestingPeriod = MONTH * MONTHS_COUNT;
    }

    /**
     * @dev add private users and assign amount to claim. Before calling,
     * ensure that contract balance is more or equal than total token payout
     * @param _user  An array of users' addresses.
     * @param _amount An array of amount values to be assigned to users respectively.
     */
    function addPrivateUser(address[] memory _user, uint256[] memory _amount)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _user.length; i++) {
            require(_amount[i] != 0, "Vesting: some amount is zero");

            if (users[_user[i]].accumulated == 0) {
                usersList.push(_user[i]);
            } else {
                totalTokensToPay -= users[_user[i]].accumulated;
            }

            users[_user[i]].accumulated = _amount[i];
            totalTokensToPay += _amount[i];
        }

        // solhint-disable-next-line reason-string
        require(
            totalTokensToPay - totalTokensPaid <=
                token.balanceOf(address(this)),
            "Vesting: total tokens to pay exceed balance"
        );

        emit UsersBatchAdded(_user, _amount);
    }

    /**
     * @dev Start vesting countdown. Can only be called by contract owner.
     */
    function startCountdown() external onlyOwner {
        // solhint-disable-next-line reason-string
        require(!isStarted, "Vesting: countdown is already started");

        // solhint-disable-next-line not-rely-on-time
        vestingStartTime = block.timestamp;

        // solhint-disable-next-line not-rely-on-time
        vestingEndTime = block.timestamp + vestingPeriod;
        isStarted = true;

        for (uint256 index = 0; index < usersList.length; index++) {
            UserInfo storage userInfo = users[usersList[index]];

            uint256 amount = (userInfo.accumulated * TGE_AVAILIBLE_PERCENT) /
                PERCENT_PRECISION;

            userInfo.paidOut += amount;
            totalTokensPaid += amount;

            token.safeTransfer(usersList[index], amount);
        }

        emit CountdownStarted(vestingStartTime, vestingEndTime);
    }

    /**
     * @dev Claims available tokens from the contract.
     */
    function claimToken() external nonReentrant {
        UserInfo storage userInfo = users[msg.sender];

        // solhint-disable-next-line reason-string
        require(
            (userInfo.accumulated - userInfo.paidOut) > 0,
            "Vesting: not enough tokens to claim"
        );

        uint256 availableAmount = calcAvailableToken(userInfo.accumulated);
        availableAmount -= userInfo.paidOut;

        userInfo.paidOut += availableAmount;

        totalTokensPaid += availableAmount;

        token.safeTransfer(msg.sender, availableAmount);

        emit TokensClaimed(msg.sender, availableAmount);
    }

    function getUserInfo(address user)
        public
        view
        returns (
            uint256 availableAmount,
            uint256 paidOut,
            uint256 totalAmountToPay
        )
    {
        UserInfo storage userInfo = users[user];
        return (
            calcAvailableToken(userInfo.accumulated) - userInfo.paidOut,
            userInfo.paidOut,
            userInfo.accumulated
        );
    }

    /**
     * @dev calcAvailableToken - calculate available tokens
     * @param _amount  An input amount used to calculate vesting's output value.
     * @return availableAmount_ An amount available to claim.
     */
    function calcAvailableToken(uint256 _amount)
        private
        view
        returns (uint256 availableAmount_)
    {
        if (!isStarted) {
            return 0;
        } else {
            availableAmount_ =
                (_amount * TGE_AVAILIBLE_PERCENT) /
                PERCENT_PRECISION;
        }

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > vestingEndTime) {
            return _amount;
        }

        uint256 producedAmount = ((_amount - availableAmount_) *
            // solhint-disable-next-line not-rely-on-time
            (block.timestamp - vestingStartTime)) / vestingPeriod;

        availableAmount_ += producedAmount;

        return availableAmount_;
    }
}
