//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";

// Token with rewards capability for https://onx.finance
// ERC20 that allows ONX holders to deposit their tokens and receive 3rd-party rewards
// Based on Ellipsis RewardsToken.sol - https://github.com/ellipsis-finance/ellipsis
contract ONXRewards is Initializable, ReentrancyGuardUpgradeable, AccessControlUpgradeable, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public override symbol;
    string public override name;
    uint8 public constant override decimals = 18;
    uint256 public override totalSupply;

    IERC20 public onxToken;

    struct Reward {
        uint256 rewardsDuration;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    mapping(address => Reward) public rewardData;
    address[] public rewardTokens;

    // user -> reward token -> amount
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;

    mapping(address => uint256) public override balanceOf;

    // owner -> spender -> amount
    mapping(address => mapping(address => uint256)) public override allowance;

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);
    event RewardsDurationUpdated(address token, uint256 newDuration);
    event Recovered(address token, uint256 amount);

    function initialize(
        string memory _name,
        string memory _symbol,
        IERC20 _onx
    ) public virtual initializer {
        __ONXRewards_init(_name, _symbol, _onx);
    }

    function __ONXRewards_init(
        string memory _name,
        string memory _symbol,
        IERC20 _onx
    ) internal onlyInitializing {
        __AccessControl_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ONXRewards_init_unchained(_name, _symbol, _onx);
    }

    function __ONXRewards_init_unchained(
        string memory _name,
        string memory _symbol,
        IERC20 _onx
    ) internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        name = _name;
        symbol = _symbol;
        onxToken = _onx;

        emit Transfer(address(0), _msgSender(), 0);
    }

    modifier updateReward(address[2] memory accounts) {
        for (uint256 i; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            rewardData[token].rewardPerTokenStored = rewardPerToken(token);
            rewardData[token].lastUpdateTime = lastTimeRewardApplicable(token);
            for (uint256 x = 0; x < accounts.length; x++) {
                address account = accounts[x];
                if (account == address(0)) break;
                rewards[account][token] = earned(account, token);
                userRewardPerTokenPaid[account][token] = rewardData[token].rewardPerTokenStored;
            }
        }
        _;
    }

    function lastTimeRewardApplicable(address _rewardsToken) public view returns (uint256) {
        return Math.min(block.timestamp, rewardData[_rewardsToken].periodFinish);
    }

    function rewardPerToken(address _rewardsToken) public view returns (uint256) {
        Reward storage reward = rewardData[_rewardsToken];
        if (totalSupply == 0) {
            return reward.rewardPerTokenStored;
        }
        uint256 last = lastTimeRewardApplicable(_rewardsToken);
        return (
            reward.rewardPerTokenStored.add(
                last.sub(reward.lastUpdateTime).mul(reward.rewardRate).mul(1e18).div(totalSupply)
            )
        );
    }

    function earned(address _account, address _rewardsToken) public view returns (uint256) {
        uint256 balance = balanceOf[_account];
        uint256 perToken = rewardPerToken(_rewardsToken).sub(userRewardPerTokenPaid[_account][_rewardsToken]);
        return balance.mul(perToken).div(1e18).add(rewards[_account][_rewardsToken]);
    }

    function getRewardForDuration(address _rewardsToken) external view returns (uint256) {
        return rewardData[_rewardsToken].rewardRate.mul(rewardData[_rewardsToken].rewardsDuration);
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {
        allowance[_msgSender()][_spender] = _value;
        emit Approval(_msgSender(), _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        _transfer(_msgSender(), _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool) {
        uint256 allowed = allowance[_from][_msgSender()];
        require(allowed >= _value, "ONXRewards: insufficient allowance");
        if (allowed != type(uint256).max) {
            allowance[_from][_msgSender()] = allowed.sub(_value);
        }
        _transfer(_from, _to, _value);
        return true;
    }

    function getReward() public nonReentrant updateReward([_msgSender(), address(0)]) {
        for (uint256 i; i < rewardTokens.length; i++) {
            address _rewardsToken = rewardTokens[i];
            uint256 reward = rewards[_msgSender()][_rewardsToken];
            if (reward > 0) {
                rewards[_msgSender()][_rewardsToken] = 0;
                IERC20(_rewardsToken).safeTransfer(_msgSender(), reward);
                emit RewardPaid(_msgSender(), _rewardsToken, reward);
            }
        }
    }

    function notifyRewardAmount(address _rewardsToken, uint256 _reward)
        external
        updateReward([address(0), address(0)])
    {
        require(rewardData[_rewardsToken].rewardsDuration != 0, "ONXRewards: reward pool does not exist");
        // handle the transfer of reward tokens via `transferFrom` to reduce the number
        // of transactions required and ensure correctness of the reward amount
        IERC20(_rewardsToken).safeTransferFrom(_msgSender(), address(this), _reward);

        if (block.timestamp >= rewardData[_rewardsToken].periodFinish) {
            rewardData[_rewardsToken].rewardRate = _reward.div(rewardData[_rewardsToken].rewardsDuration);
        } else {
            uint256 remaining = rewardData[_rewardsToken].periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardData[_rewardsToken].rewardRate);
            rewardData[_rewardsToken].rewardRate = _reward.add(leftover).div(rewardData[_rewardsToken].rewardsDuration);
        }

        rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken].periodFinish = block.timestamp.add(rewardData[_rewardsToken].rewardsDuration);
        emit RewardAdded(_reward);
    }

    // Exchange ONX tokens for sONXv in 1:1 ratio
    function deposit(uint256 _value) external updateReward([_msgSender(), address(0)]) {
        require(_value > 0, "ONXRewards: cannot deposit 0 tokens");
        onxToken.safeTransferFrom(_msgSender(), address(this), _value);
        _mint(_msgSender(), _value);
    }

    // Withdraw deposited ONX tokens from the contract
    function withdraw(uint256 _value) external updateReward([_msgSender(), address(0)]) {
        require(_value > 0, "ONXRewards: cannot withdraw 0 tokens");
        _burn(_msgSender(), _value);
        onxToken.safeTransfer(_msgSender(), _value);
    }

    function setRewardsDuration(address _rewardsToken, uint256 _rewardsDuration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(block.timestamp > rewardData[_rewardsToken].periodFinish, "ONXRewards: reward period still active");
        require(_rewardsDuration > 0, "ONXRewards: reward duration must be non-zero");
        rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(_rewardsToken, rewardData[_rewardsToken].rewardsDuration);
    }

    // Added to support recovering token rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(rewardData[_tokenAddress].lastUpdateTime == 0, "ONXRewards: reward pool already exists");
        address owner = _msgSender();
        IERC20(_tokenAddress).safeTransfer(owner, _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    function addReward(address _rewardsToken, uint256 _rewardsDuration) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(rewardData[_rewardsToken].rewardsDuration == 0, "ONXRewards: duplicate reward");
        rewardTokens.push(_rewardsToken);
        rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal updateReward([_from, _to]) {
        require(_from != address(0), "ONXRewards: transfer from the zero address");
        require(_to != address(0), "ONXRewards: transfer to the zero address");
        require(balanceOf[_from] >= _value, "ONXRewards: insufficient balance");

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function _mint(address _to, uint256 _value) internal {
        balanceOf[_to] = balanceOf[_to].add(_value);
        totalSupply = totalSupply.add(_value);
        emit Transfer(address(0), _to, _value);
    }

    function _burn(address _from, uint256 _value) internal {
        require(balanceOf[_from] >= _value, "ONXRewards: burn amount exceeds balance");
        balanceOf[_from] = balanceOf[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(_from, address(0), _value);
    }
}
