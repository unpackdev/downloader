// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract DepositRewardsSols is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMath for uint256;
    address public operation;
    uint256 public supply;
    IERC20 public token;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public currentRewards;
    uint256 public historicalRewards;
    uint256 public periodFinish;
    uint256 public duration;
    uint256 public minDepositAmount;
    uint256 public minDepositTime;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public unlocked;
    uint256 public claimFee;

    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Claim(
        address indexed user,
        uint256 indexed amount,
        uint256 indexed claimTimestamp,
        uint256 fee,
        string receiveAddr
    );
    event RewardAdded(uint256 reward);
    event Withdraw(address indexed user, uint256 amount, uint256 timestamp);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        address _token
    ) public initializer {
        __Pausable_init();
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        operation = msg.sender;
        // deposit token
        token = IERC20(_token);
        // rewards rate  (sols reward rate per xxxToken staked per second)
        rewardRate = 0;
        duration = 210 days;
        minDepositTime = 30 days;
        minDepositAmount = 1000 * 1e18;
        claimFee = 5 * 1e14;
    }

    modifier onlyOperation() {
        require(msg.sender == operation, "only operation");
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ ///
    ///       Owner Functions       ///
    /// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ ///
    function setOperation(address _operation) external onlyOwner {
        operation = _operation;
    }

    function setMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
        minDepositAmount = _minDepositAmount;
    }

    function setMinDepositTime(uint256 _minDepositTime) external onlyOwner {
        minDepositTime = _minDepositTime;
    }

    function setClaimFee(uint256 _claimFee) external onlyOwner {
        claimFee = _claimFee;
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ ///
    ///       Reward Functions       ///
    /// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ ///
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function setDuration(uint256 _duration) external onlyOwner {
        duration = _duration;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (supply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(supply)
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function deposit(
        uint256 _amount
    ) external nonReentrant updateReward(msg.sender) whenNotPaused {
        require(_amount >= minDepositAmount, "quantity too small");
        token.transferFrom(msg.sender, address(this), _amount);
        supply += _amount;
        balanceOf[msg.sender] += _amount;
        unlocked[msg.sender] = block.timestamp + minDepositTime;
        emit Deposit(msg.sender, _amount, block.timestamp);
    }

    function withdraw() external nonReentrant updateReward(msg.sender) {
        require(
            block.timestamp >= unlocked[msg.sender],
            "Unlock time has not come yet"
        );
        uint256 _amount = balanceOf[msg.sender];
        supply -= _amount;
        balanceOf[msg.sender] = 0;
        unlocked[msg.sender] = 0;
        token.transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount, block.timestamp);
    }

    function _claimFrom(
        address _account,
        uint256 _fee,
        string memory receiveAddr
    ) internal updateReward(_account) {
        require(_fee >= claimFee, "Insufficient fee");
        uint256 reward = earned(_account);
        if (reward > 0) {
            rewards[_account] = 0;
            emit Claim(_account, reward, block.timestamp, _fee, receiveAddr);
        }
    }

    function claim(string memory receiveAddr) nonReentrant external payable {
        _claimFrom(msg.sender, msg.value, receiveAddr);
    }

    function newRewards(uint256 _rewards) external onlyOperation {
        _notifyRewardAmount(_rewards, duration);
    }

    function _notifyRewardAmount(
        uint256 _reward,
        uint256 _duration
    ) internal updateReward(address(0)) {
        historicalRewards = historicalRewards.add(_reward);
        if (block.timestamp >= periodFinish) {
            rewardRate = _reward.div(_duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            _reward = _reward.add(leftover);
            rewardRate = _reward.div(_duration);
        }
        currentRewards = _reward;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(_duration);
        emit RewardAdded(_reward);
    }

    function withdrawFee(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Cannot go to address 0");
        payable(to).transfer(amount);
    }
}
