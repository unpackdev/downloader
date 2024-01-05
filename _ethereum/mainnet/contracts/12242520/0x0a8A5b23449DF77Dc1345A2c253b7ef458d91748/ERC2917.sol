pragma solidity 0.7.6;

import "./IERC2917.sol";
import "./SafeMath.sol";
import "./Initializable.sol";

contract ERC2917 is IERC2917, Initializable {
    using SafeMath for uint256;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    address public implementor;
    modifier onlyImplementor() {
        require(msg.sender == implementor, 'Only implementor');
        _;
    }

    uint256 public totalInterestPaid;
    uint256 public interestPerBlock;
    uint256 public lastRewardBlock;
    uint256 public totalProductivity;
    uint256 public accAmountPerShare;

    struct UserStakeInfo {
        uint amount;     // LP tokens the user has provided.
        uint rewardDebt; // Reward debt. 
    }

    mapping(address => UserStakeInfo) public users;

    function initialize() external override initializer {
        implementor = msg.sender;
    }

    function setImplementor(address newImplementor) external override onlyImplementor {
        require(newImplementor != implementor, "no change");
        require(newImplementor != address(0), "invalid address");
        implementor = newImplementor;
    }

    // External function call
    // This function adjust how many tokens are produced by each block, eg:
    // changeAmountPerBlock(100)
    // will set the produce rate to 100/block.
    function changeInterestRatePerBlock(uint value) external override onlyImplementor returns (bool) {
        uint old = interestPerBlock;
        require(value != old, 'AMOUNT_PER_BLOCK_NO_CHANGE');

        interestPerBlock = value;

        emit InterestRatePerBlockChanged(old, value);
        return true;
    }

    // Update reward variables of the given pool to be up-to-date.
    function _update() private {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalProductivity == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number.sub(lastRewardBlock);
        uint256 reward = multiplier.mul(interestPerBlock);

        accAmountPerShare = accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
        lastRewardBlock = block.number;
    }

    // External function call
    // This function increase user's productivity and updates the global productivity.
    // the users' actual share percentage is calculated by user_productivity / global_productivity
    function increaseProductivity(address user, uint value) external override onlyImplementor returns (bool, uint, uint) {
        require(value > 0, 'PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO');

        UserStakeInfo storage userStakeInfo = users[user];
        _update();
        uint pending;
        if (userStakeInfo.amount > 0) {
            pending = userStakeInfo.amount.mul(accAmountPerShare).div(1e12).sub(userStakeInfo.rewardDebt);
            totalInterestPaid = totalInterestPaid.add(pending);
        }

        totalProductivity = totalProductivity.add(value);

        userStakeInfo.amount = userStakeInfo.amount.add(value);
        userStakeInfo.rewardDebt = userStakeInfo.amount.mul(accAmountPerShare).div(1e12);
        emit ProductivityIncreased(user, value);
        return (true, pending, totalProductivity);
    }

    // External function call 
    // This function will decreases user's productivity by value, and updates the global productivity
    // it will record which block this is happenning and accumulates the area of (productivity * time)
    function decreaseProductivity(address user, uint value) external override onlyImplementor returns (bool, uint, uint) {
        require(value > 0, 'INSUFFICIENT_PRODUCTIVITY');
        
        UserStakeInfo storage userStakeInfo = users[user];
        require(userStakeInfo.amount >= value, "not enough stake");
        _update();
        uint pending = userStakeInfo.amount.mul(accAmountPerShare).div(1e12).sub(userStakeInfo.rewardDebt);
        totalInterestPaid = totalInterestPaid.add(pending);
        userStakeInfo.amount = userStakeInfo.amount.sub(value);
        userStakeInfo.rewardDebt = userStakeInfo.amount.mul(accAmountPerShare).div(1e12);
        totalProductivity = totalProductivity.sub(value);

        emit ProductivityDecreased(user, value);
        return (true, pending, totalProductivity);
    }

    function takeWithAddress(address user) public view returns (uint) {
        UserStakeInfo storage userStakeInfo = users[user];
        uint _accAmountPerShare = accAmountPerShare;
        if (block.number > lastRewardBlock && totalProductivity != 0) {
            uint multiplier = block.number.sub(lastRewardBlock);
            uint reward = multiplier.mul(interestPerBlock);
            _accAmountPerShare = _accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
        }
        return userStakeInfo.amount.mul(_accAmountPerShare).div(1e12).sub(userStakeInfo.rewardDebt);
    }

    function take() public override view returns (uint) {
        return takeWithAddress(msg.sender);
    }

    // Returns how much a user could earn plus the giving block number.
    function takeWithBlock() public override view returns (uint, uint) {
        return (take(), block.number);
    }

    // External function call
    // When user calls this function, it will calculate how many token will mint to user from his productivity * time and sends them to the user
    // Also it calculates global token supply from last time the user mint to this time.
    function mint() external override lock returns (uint) {
        // currently not implemented
        return 0;
    }

    // Returns how much productivity a user has and global has.
    function getProductivity(address user) external override view returns (uint, uint) {
        return (users[user].amount, totalProductivity);
    }

    // Returns the current gross product rate.
    function interestsPerBlock() external override view returns (uint) {
        return accAmountPerShare;
    }
}