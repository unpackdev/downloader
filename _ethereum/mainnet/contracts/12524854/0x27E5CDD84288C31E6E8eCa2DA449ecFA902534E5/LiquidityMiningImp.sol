pragma solidity 0.7.0;

import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract LiquidityMiningImp is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken; // OCC token address
    IERC20 public stakingToken; // Uniswap liquidity token address
    uint256[] public checkPoints; 
    uint256[] public rewardPerSecond; 
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored; // per 1 LT, i.e. per 10**18 units

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public totalStake;
    mapping(address => uint256) public stakes;

    bool public initialized = false;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner) Ownable(_owner) {}

    function initialize(
        address _rewardsToken,
        address _stakingToken,
        uint emissionStart,
        uint firstCheckPoint,
        uint _rewardPerSecond,
        address admin
    ) public {
        require(initialized == false, "OCCStakingImp: contract has already been initialized.");
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        if (checkPoints.length == 0) {
            checkPoints.push(emissionStart);
            checkPoints.push(firstCheckPoint);
            rewardPerSecond.push(_rewardPerSecond);
        }
        owner = admin;
        initialized = true;
    }

    function updateSchedule(uint checkPoint, uint _rewardPerSecond) public onlyOwner {
        require(checkPoint > Math.max(checkPoints[checkPoints.length.sub(1)], block.timestamp), "LM: new checkpoint has to be in the future");
        if (block.timestamp > checkPoints[checkPoints.length.sub(1)]) {
            checkPoints.push(block.timestamp);
            rewardPerSecond.push(0);
        }
        checkPoints.push(checkPoint);
        rewardPerSecond.push(_rewardPerSecond);
    }

    function getCheckPoints() public view returns (uint256[] memory) {
        return checkPoints;
    }

    function getRewardPerSecond() public view returns (uint256[] memory) {
        return rewardPerSecond;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, checkPoints[checkPoints.length.sub(1)]);
    }

    function getTotalEmittedTokens(uint256 _from, uint256 _to) public view returns (uint256) {
        require(_to >= _from, "LM: _to has to be greater than _from.");
        uint256 totalEmittedTokens = 0;
        uint256 workingTime = Math.max(_from, checkPoints[0]);
        if (_to <= workingTime) {
            return 0;
        }
        uint256 checkPointLength = checkPoints.length;
        for (uint256 i = 1; i < checkPointLength; ++i) {
            uint256 emissionTime = checkPoints[i];
            uint256 emissionRate = rewardPerSecond[i-1];
            if (_to < emissionTime) {
                totalEmittedTokens = totalEmittedTokens.add(_to.sub(workingTime).mul(emissionRate));
                return totalEmittedTokens;
            } else if (workingTime < emissionTime) {
                totalEmittedTokens = totalEmittedTokens.add(emissionTime.sub(workingTime).mul(emissionRate));
                workingTime = emissionTime;
            }
        }
        return totalEmittedTokens;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "LM: Cannot stake 0");
        totalStake = totalStake.add(amount);
        stakes[msg.sender] = stakes[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "LM: Cannot withdraw 0");
        require(amount <= stakes[msg.sender], "LM: withdraw more than staked");
        totalStake = totalStake.sub(amount);
        stakes[msg.sender] = stakes[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(stakes[msg.sender]);
        getReward();
    }

    function showPendingReward(address account) public view returns (uint256) {
        uint rewardPerTokenStoredActual;
        if (totalStake != 0) {
            uint256 totalEmittedTokensSinceLastUpdate = getTotalEmittedTokens(lastUpdateTime, block.timestamp);
            rewardPerTokenStoredActual = rewardPerTokenStored.add(totalEmittedTokensSinceLastUpdate.mul(1e18).div(totalStake));
        } else {
            rewardPerTokenStoredActual = rewardPerTokenStored;
        }
        return rewards[account].add((rewardPerTokenStoredActual.sub(userRewardPerTokenPaid[account])).mul(stakes[account]).div(1e18));
    }

    function _updateReward(address account) internal {
        if (totalStake != 0) {
            uint256 totalEmittedTokensSinceLastUpdate = getTotalEmittedTokens(lastUpdateTime, block.timestamp);
            rewardPerTokenStored = rewardPerTokenStored.add(totalEmittedTokensSinceLastUpdate.mul(1e18).div(totalStake));
        }
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            uint256 _rewardPerTokenStored = rewardPerTokenStored;
            rewards[account] = rewards[account].add((_rewardPerTokenStored.sub(userRewardPerTokenPaid[account])).mul(stakes[account]).div(1e18));
            userRewardPerTokenPaid[account] = _rewardPerTokenStored;
        }
    }
    modifier updateReward(address account) {
        _updateReward(account);
        _;
    }

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}
