pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


/*
*   [Hardwork]
*   This pool doesn't mint.
*   the rewards should be first transferred to this pool, then get "notified"
*   by calling `notifyRewardAmount`
*/

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";

contract PopulousTokenRewardPool is Ownable {
    using SafeMath for uint256;

    using Address for address;

    ERC20 public pToken;
    ERC20 public rewardToken;
    uint256 public duration;

    uint256 public periodFinish = 0;

    uint256 public totalDeposit = 0;
    uint256 public totalRewardPaid = 0;

    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    mapping(address => uint256) internal userInfo;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    //event RewardDenied(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(address _pToken,
        address _rewardToken,
        uint256 _duration) public
    {   
        pToken = ERC20(_pToken);
        rewardToken = ERC20(_rewardToken);
        duration = _duration;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        uint256 PTokenSupply = pToken.balanceOf(address(this));
        if (PTokenSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(PTokenSupply)
            );
    }

    function getuserinfo(address _user) public view returns(uint256 ){
        return userInfo[_user];
    }

    function earned(address account) public view returns (uint256) {
        return
            userInfo[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public updateReward(msg.sender) {
        //require(msg.sender == exclusiveAddress, "Must be the exclusiveAddress to stake");
        require(amount > 0, "Cannot stake 0");
        //UserInfo storage user = userInfo[msg.sender];
        pToken.transferFrom(address(msg.sender), address(this), amount);
        //user.amount = user.amount.add(amount);
        userInfo[msg.sender] = userInfo[msg.sender].add(amount);
        totalDeposit = totalDeposit.add(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        userInfo[msg.sender] = userInfo[msg.sender].sub(amount);
        totalDeposit = totalDeposit.sub(amount);
        pToken.transfer(address(msg.sender), amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(userInfo[msg.sender]);
        getReward();
    }

    function withdrawAll() external {
        withdraw(userInfo[msg.sender]);
    }

    function getTotalDeposit() public view returns(uint256) {
        return totalDeposit;
    }

    function getTotalRewardPaid() public view returns(uint256) {
        return totalRewardPaid;
    }

    /**
     * A push mechanism for accounts that have not claimed their rewards for a long time.
     * The implementation is semantically analogous to getReward(), but uses a push pattern
     * instead of pull pattern.
     */
    function pushReward(address recipient) public updateReward(recipient) onlyOwner {
        uint256 reward = earned(recipient);
        if (reward > 0) {
            rewards[recipient] = 0;
            totalRewardPaid = totalRewardPaid.add(reward);
            rewardToken.transfer(recipient, reward);
            emit RewardPaid(recipient, reward);
        }
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            totalRewardPaid = totalRewardPaid.add(reward);
            rewardToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyOwner
        updateReward(address(0))
    {
        // overflow fix according to https://sips.synthetix.io/sips/sip-77
        require(reward < uint(-1) / 1e18, "the notified reward cannot invoke multiplication overflow");

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(duration);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);
        emit RewardAdded(reward);
    }
} 