// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * onlyOwner functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract RevenueDistribution is ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;

    // State variables
    mapping(address => uint256) public lastClaimTime;
    mapping(address => uint256) public claimedRewards;
    mapping(uint256 => uint256) public ethReceivedPerPeriod;
    mapping(address => uint256) public depositedTokenBalance;
    uint256 public totalDepositedTokens;
    uint256 public totalRewards;
    uint256 public distributionPeriod;
    uint256 public deployedAt;

    // ERC20 token address
    address public palmToken;

    // Events
    event RewardsAdded(address indexed sender, uint256 amount);
    event RewardsClaimed(address indexed recipient, uint256 amount);
    event TokensDeposited(address indexed user, uint256 amount);
    event TokensWithdrew(address indexed user, uint256 amount);
    event DepositUpdated(address indexed user, uint256 amount, bool staked);

    // Constructor
    constructor() {
        palmToken = 0xa0a2E18784633eB47DbAfe7c36C4594B3eDaAeF6;
        deployedAt = block.timestamp;
        distributionPeriod = 7 days;
    }

    // Pause and unpause functions
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner{
        _unpause();
    }

    function updateDistributionPeriod(uint256 _distributionPeriod) external onlyOwner {
        distributionPeriod = _distributionPeriod;
    }

    // Receive function to accept ETH
    receive() external payable {
        addRewards(msg.value);
        recordEthReceivedForCurrentPeriod(msg.value);
    }


    // Internal function to add rewards
    function addRewards(uint256 amount) internal whenNotPaused {
        totalRewards += amount;
        emit RewardsAdded(msg.sender, amount);
    }

    // Deposit tokens for revenue share
    function depositTokens(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        IERC20(address(palmToken)).safeTransferFrom(msg.sender, address(this), amount);
        
        uint256 currentDeposit = depositedTokenBalance[msg.sender];
        depositedTokenBalance[msg.sender] = currentDeposit + amount;
        totalDepositedTokens += amount;

        emit TokensDeposited(msg.sender, amount);
        emit DepositUpdated(msg.sender, currentDeposit + amount, true);
    }

    // Withdraw tokens from revenue share
    function withdrawTokens(uint256 amount) external whenNotPaused nonReentrant {
        uint256 currentDeposit = depositedTokenBalance[msg.sender];
        require(currentDeposit >= amount, "Insufficient staked balance");
        
        calculateAndTransferRewards(msg.sender);
        depositedTokenBalance[msg.sender] = currentDeposit - amount;
        totalDepositedTokens -= amount;

        IERC20(address(palmToken)).safeTransfer(msg.sender, amount);
        emit TokensWithdrew(msg.sender, amount);
        emit DepositUpdated(msg.sender, currentDeposit - amount, false);
    }

    // Recording ETH received for current distribution period
    function recordEthReceivedForCurrentPeriod(uint256 amount) internal {
        uint256 currentPeriod = (block.timestamp - deployedAt) / distributionPeriod;
        ethReceivedPerPeriod[currentPeriod] += amount;
    }

    // Distributing rewards for the current period
    function distributeRewards() internal {
        uint256 currentPeriod = (block.timestamp - deployedAt) / distributionPeriod;
        uint256 ethReceivedForPeriod = ethReceivedPerPeriod[currentPeriod];

        if (ethReceivedForPeriod > 0 && totalDepositedTokens > 0) {
            uint256 rewardsForCurrentPeriod = totalRewards > 0 ? (ethReceivedForPeriod * totalDepositedTokens) / totalRewards : 0;
            totalRewards += rewardsForCurrentPeriod;
        }
    }

    // Calculating and transferring rewards
    function calculateAndTransferRewards(address user) internal {
        if (totalDepositedTokens > 0) {
            uint256 userStake = depositedTokenBalance[user];
            if (userStake > 0) {
                uint256 totalReward = (userStake * totalRewards) / totalDepositedTokens;
                totalReward = totalReward > claimedRewards[user] ? totalReward - claimedRewards[user] : 0;
                claimedRewards[user] += totalReward;
                totalRewards -= totalReward;
                payable(user).transfer(totalReward);
                emit RewardsClaimed(user, totalReward);
            }
        }
    }

    // Claiming rewards
    function claim() external nonReentrant {
        require(depositedTokenBalance[msg.sender] > 0, "No staked tokens");
        distributeRewards();
        calculateAndTransferRewards(msg.sender);
        lastClaimTime[msg.sender] = block.timestamp;
    }
}
