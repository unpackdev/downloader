// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // NASH-WETH-LP token address
    IERC20 public LPToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        LPToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        LPToken.safeTransfer(msg.sender, amount);
    }
}

contract LPRewardNASHPool is LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public developer;
    bool isInit = false;
    bool isStart = false;

    // NASH token address
    IERC20 public NASHToken;

    uint256 public constant DURATION = 7 days;

    uint256 public totalReward = 10000000000 * 1e18;
    uint256 public starttime = 0;
    uint256 public endtime = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier onlyDeveloper() {
        require(msg.sender == developer);
        _;
    }

    constructor(address _NASHToken, address _LPToken) {
        developer = msg.sender;

        NASHToken = IERC20(_NASHToken);
        LPToken = IERC20(_LPToken);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, endtime);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function stake(uint256 amount)
        public override
        updateReward(msg.sender)
        checkStart
        checkEnd
    {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public override
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            NASHToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function setDeveloper(address _developer) public onlyDeveloper {
        require(_developer != address(0), "developer can't be address(0)");
        developer = _developer;
    }

    function initialization(uint256 _starttime) external onlyDeveloper {
        require(_starttime > block.timestamp, "starttime needs to be greater than the current time");
        require(!isInit, "Already initialization");

        starttime = _starttime;
        endtime = starttime.add(DURATION);

        rewardRate = totalReward.div(DURATION);
        lastUpdateTime = block.timestamp;

        isInit = true;
    }

	function fetchRemainingRewards() external onlyDeveloper {
        require(block.timestamp > endtime, "Not end");
        require(super.totalSupply() == 0, "Not exit all");
        NASHToken.safeTransfer(msg.sender, NASHToken.balanceOf(address(this)));
	}
    
    modifier checkStart() {
        require(isInit, "Not initialization");
        require(block.timestamp > starttime, "Not start");

        if(isStart == false){
            starttime = block.timestamp;
            endtime = starttime.add(DURATION);
            isStart = true;
        }
        _;
    }

    modifier checkEnd() {
        require(block.timestamp <= endtime, "Time end");
        _;
    }
}