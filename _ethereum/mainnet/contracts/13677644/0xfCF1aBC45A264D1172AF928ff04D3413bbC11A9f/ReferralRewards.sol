pragma solidity 0.5.12;

import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IRewardDistributionRecipient.sol";
import "./RewardEscrow.sol";

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // TODO setup pool for DeFi+S
    IERC20 public uni;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        uni.safeTransferFrom(msg.sender, address(this), amount);
    }

    function stakeFor(uint256 amount, address beneficiary) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[beneficiary] = _balances[beneficiary].add(amount);
        uni.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        uni.safeTransfer(msg.sender, amount);
    }
}

contract ReferralRewards is LPTokenWrapper, IRewardDistributionRecipient {
    IERC20 public dough;
    uint256 public constant DURATION = 7 days;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    RewardEscrow public rewardEscrow;
    uint256 public escrowPercentage;

    mapping(address => address) public referralOf;
    // 1%
    uint256 referralPercentage = 1 * 10 ** 16;

    uint8 public constant decimals = 18;
    string public name = "PieDAO staking contract DOUGH/ETH";
    string public symbol = "PieDAO DOUGH/ETH Staking";

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event ReferralSet(address indexed user, address indexed referral);
    event ReferralReward(address indexed user, address indexed referral, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function initialize(
        address _dough,
        address _uni,
        address _rewardEscrow,
        string memory _name, 
        string memory _symbol
    ) public initializer {
        Ownable.initialize(msg.sender);
        dough = IERC20(_dough);
        uni = IERC20 (_uni);
        rewardEscrow = RewardEscrow(_rewardEscrow);
        name = _name;
        symbol = _symbol;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
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

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Transfer(address(0), msg.sender, amount);
        emit Staked(msg.sender, amount);
    }

    function stakeFor(uint256 amount, address beneficiary) public updateReward(beneficiary) {
        require(amount > 0, "Cannot stake 0");
        super.stakeFor(amount, beneficiary);
        emit Transfer(address(0), msg.sender, amount);
        emit Staked(beneficiary, amount);
    }

    function stake(uint256 amount, address referral) public {
        stake(amount);
        
        // Only set if referral is not set yet
        if(referralOf[msg.sender] == address(0) && referral != msg.sender && referral != address(0)) {
            referralOf[msg.sender] = referral;
            emit ReferralSet(msg.sender, referral);
        }
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            uint256 escrowedReward = reward.mul(escrowPercentage).div(10**18);
            if(escrowedReward != 0) {
                dough.safeTransfer(address(rewardEscrow), escrowedReward);
                rewardEscrow.appendVestingEntry(msg.sender, escrowedReward);
            }

            uint256 nonEscrowedReward = reward.sub(escrowedReward);

            if(nonEscrowedReward != 0) {
                dough.safeTransfer(msg.sender, reward.sub(escrowedReward));
            }
            emit RewardPaid(msg.sender, reward);
        }

        if(referralOf[msg.sender] != address(0)) {
            address referral = referralOf[msg.sender];
            uint256 referralReward = reward.mul(referralPercentage).div(10**18);
            rewards[referral] = rewards[referral].add(referralReward);
            emit ReferralReward(msg.sender, referral, referralReward);
        }
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    function setEscrowPercentage(uint256 _percentage) external onlyRewardDistribution {
        require(_percentage <= 10**18, "100% escrow is the max");
        escrowPercentage = _percentage;
    }

    function saveToken(address _token) external {
        require(_token != address(dough) && _token != address(uni), "INVALID_TOKEN");

        IERC20 token = IERC20(_token);

        token.transfer(address(0x4efD8CEad66bb0fA64C8d53eBE65f31663199C6d), token.balanceOf(address(this)));
    }
}