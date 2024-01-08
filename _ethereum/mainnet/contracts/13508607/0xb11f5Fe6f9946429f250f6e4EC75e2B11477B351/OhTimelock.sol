// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./ITimelock.sol";
import "./IToken.sol";
import "./OhSubscriber.sol";

/// @title Oh! Finance Token Timelock
/// @notice Contract to manage linear token vesting over a given time period
/// @notice Users accrue vested tokens as soon as the timelock starts, every second
contract OhTimelock is ReentrancyGuard, OhSubscriber, ITimelock {
    using SafeMath for uint256;

    /// @notice The total vested balance of tokens a user can claim
    mapping(address => uint256) public balances;

    /// @notice The total amount of tokens a user has already claimed
    mapping(address => uint256) public claimed;

    /// @notice The Oh! Finance Token address
    address public token;

    /// @notice The UNIX timestamp that the timelock starts at
    uint256 public timelockStart;

    /// @notice The length in seconds of the timelock
    uint256 public timelockLength;

    /// @notice Emitted when a user is added to the timelock
    event Add(address indexed user, uint256 amount);

    /// @notice Emitted every time a user claims tokens
    event Claim(address indexed user, uint256 amount);

    /// @notice Timelock constructor
    /// @param registry_ The address of the Registry
    /// @param _token The address of the Oh! Finance Token
    /// @param _timelockDelay Seconds to delay the timelock from starting
    /// @param _timelockLength The length of the timelock in seconds
    constructor(
        address registry_,
        address _token,
        uint256 _timelockDelay,
        uint256 _timelockLength
    ) OhSubscriber(registry_) {
        token = _token;
        timelockStart = block.timestamp + _timelockDelay;
        timelockLength = _timelockLength;
    }

    /// @notice Add a set of users to the vesting contract with a set amount
    /// @dev Only callable by Governance, delegates token votes to msg.sender until they are claimed
    /// @param users The array of users to be added to the vesting contract
    /// @param amounts The array of amounts of tokens to add to each users vesting schedule
    function add(address[] memory users, uint256[] memory amounts) external onlyGovernance {
        require(users.length == amounts.length, "Timelock: Arrity mismatch");

        // find total, add to user balances
        uint256 totalAmount = 0;
        uint256 length = users.length;
        for (uint256 i = 0; i < length; i++) {
            // get user and amount
            address user = users[i];
            uint256 amount = amounts[i];

            // update state and total, emit add
            balances[user] = amount;
            totalAmount = totalAmount.add(amount);
            emit Add(user, amount);
        }

        // transfer from msg.sender, delegate votes back to msg.sender
        IERC20(token).transferFrom(msg.sender, address(this), totalAmount);
    }

    /// @notice Claim all available tokens for the msg.sender, if any
    /// @dev Reentrancy guard to prevent double claims
    function claim() external nonReentrant {
        require(block.timestamp > timelockStart, "Timelock: Lock not started");

        // check for available claims
        address user = msg.sender;
        uint256 amount = claimable(user);
        require(amount > 0, "Timelock: No Tokens");

        // update user claimed variables
        claimed[user] = claimed[user].add(amount);

        // transfer to user
        TransferHelper.safeTokenTransfer(user, token, amount);
        emit Claim(user, amount);
    }

    /// @notice Available tokens available for a user to claim
    /// @dev Available = ((Balances[user] * Time_Passed) / Total_Time) - Claimed[user]
    /// @param user The user address to check
    /// @return amount The amount of tokens available to claim
    function claimable(address user) public view returns (uint256 amount) {
        // save state variable to memory
        uint256 userClaimed = claimed[user];

        // if timelock hasn't started yet
        if (block.timestamp < timelockStart) {
            // return entire balance
            amount = balances[user];
        }
        // else if timelock has expired
        else if (block.timestamp > timelockStart.add(timelockLength)) {
            // return total remaining balance
            amount = balances[user].sub(userClaimed);
        }
        // else we are currently in the vesting phase
        else {
            // find the time passed since timelock start
            uint256 delta = block.timestamp.sub(timelockStart);

            // find the total vested amount of tokens available
            uint256 totalVested = balances[user].mul(delta).div(timelockLength);

            // return vested - claimed
            amount = totalVested.sub(userClaimed);
        }
    }
}
