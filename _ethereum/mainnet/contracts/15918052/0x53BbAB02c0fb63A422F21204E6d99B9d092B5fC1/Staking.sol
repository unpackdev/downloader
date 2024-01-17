// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IFungibleToken.sol";

contract Staking is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IFungibleToken;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 stakingToken; // Address of LP token contract.
        uint256 lastRewardBlock; // Last block number that MIDASes distribution occurs.
        uint256 accTokensPerShare; // Accumulated MIDASes per share, times 1e12. See below.
        uint256 totalDeposited; // Total deposited tokens amount.
    }

    // The MIDAS token
    IFungibleToken public rewardToken;
    // Dev address.
    address public devaddr;
    // Dev fee percent reward.
    uint256 public devfee;
    // MIDAS tokens created per block.
    uint256 public tokensPerBlock;
    // Bonus muliplier for early rewardToken makers.
    uint256 public rewardMultiplier;
    // The block number when MIDAS mining starts.
    uint256 public startBlock;
    // Info of each pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    /*
    __gap is using here to reserve future state variables adding. After adding new variable decrease gap size by 1.
    */
    uint256[42] private __gap;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event MintError();
    event TokenPerBlockSet(uint256 amount);
    event RewardMultiplierSet(uint256 multiplier);
    event DevSet(address account);
    event DevFeeSet(uint256 fee);

    /**
     * @dev Constructor are disabled by Initializable, use initialize instead.
     */

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Implements access control to upgrades.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Initialization
     */
    function initialize(
        IFungibleToken _midasToken,
        address _devaddr,
        uint256 _tokensPerBlock,
        uint256 _startBlock
    ) public initializer {
        require(address(_midasToken) != address(0) && _devaddr != address(0), "Master chef: constructor set");
        __Ownable_init();
        __UUPSUpgradeable_init();

        devfee = 12;
        rewardMultiplier = 1;

        rewardToken = _midasToken;
        devaddr = _devaddr;
        tokensPerBlock = _tokensPerBlock;
        startBlock = _startBlock;

        // staking pool
        poolInfo = PoolInfo({
            stakingToken: _midasToken,
            lastRewardBlock: startBlock,
            accTokensPerShare: 0,
            totalDeposited: 0
        });
    }

    /**
     * @dev Set tokens per block. Zero set disable mining.
     */
    function setTokensPerBlock(uint256 _amount) external onlyOwner {
        updatePool();
        tokensPerBlock = _amount;
        emit TokenPerBlockSet(_amount);
    }

    /**
     * @dev Set reward multiplier. Zero set disable mining.
     */
    function setRewardMultiplier(uint256 _multiplier) external onlyOwner {
        updatePool();
        rewardMultiplier = _multiplier;
        emit RewardMultiplierSet(_multiplier);
    }

    /**
     * @dev Deposit token.
     *      Send `_amount` as 0 for claim effect.
     */
    function deposit(uint256 _amount) external {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = ((user.amount * pool.accTokensPerShare) / 1e12) - user.rewardDebt;
            if (pending > 0) {
                _safeTransfer(msg.sender, pending);
            }
        }
        if (_amount != 0) {
            pool.stakingToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount + _amount;
            pool.totalDeposited += _amount;
        }
        user.rewardDebt = (user.amount * pool.accTokensPerShare) / 1e12;
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @dev Withdraw tokens with reward.
     */
    function withdraw(uint256 _amount) external {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        uint256 pending = ((user.amount * pool.accTokensPerShare) / 1e12) - user.rewardDebt;
        if (pending > 0) {
            _safeTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            pool.totalDeposited -= _amount;
            pool.stakingToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = (user.amount * pool.accTokensPerShare) / 1e12;
        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @dev Withdraw without caring about rewards. EMERGENCY ONLY.
     */
    function emergencyWithdraw() external {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        pool.totalDeposited -= user.amount;
        pool.stakingToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    /**
     * @dev Reclaim lost tokens.
     */
    function reclaim(address _token) external onlyOwner {
        require(_token != address(rewardToken), "Only not reward token");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        require(amount != 0, "NO_RECLAIM");
        IERC20(_token).safeTransfer(owner(), amount);
    }

    /**
     * @dev Update dev address by the previous dev.
     */
    function setDev(address _account) external {
        require(msg.sender == devaddr, "dev: wut?");
        require(_account != address(0), "Zero address set");

        devaddr = _account;
        emit DevSet(_account);
    }

    function setDevFee(uint256 _fee) external {
        require(msg.sender == devaddr, "dev: wut?");
        require(_fee <= 25, "max dev reward reached");

        devfee = _fee;
        emit DevFeeSet(_fee);
    }

    /**
     * @dev View function to see pending MIDASes on frontend.
     */
    function pendingReward(address _user) external view returns (uint256 reward) {
        PoolInfo memory pool = poolInfo;
        UserInfo memory user = userInfo[_user];
        uint256 accTokensPerShare = pool.accTokensPerShare;
        uint256 lpSupply = pool.totalDeposited;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier * tokensPerBlock;
            accTokensPerShare = accTokensPerShare + ((tokenReward * 1e12) / lpSupply);
        }
        reward = (user.amount * accTokensPerShare) / 1e12 - user.rewardDebt;
    }

    /**
     * @dev Update reward variables of the given pool to be up-to-date.
     */
    function updatePool() public {
        PoolInfo storage pool = poolInfo;
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.totalDeposited;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier * tokensPerBlock;
        if (tokenReward == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        if (devaddr != address(0) && devfee != 0) {
            try rewardToken.mint(devaddr, (tokenReward * devfee) / 100) {
                //
            } catch {
                emit MintError();
            }
        }

        try rewardToken.mint(address(this), tokenReward) {
            //
        } catch {
            emit MintError();
        }

        pool.accTokensPerShare = pool.accTokensPerShare + ((tokenReward * 1e12) / lpSupply);
        pool.lastRewardBlock = block.number;
    }

    /**
     * @dev Return reward multiplier over the given _from to _to block.
     */
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256 multiplier) {
        multiplier = (_to - _from) * rewardMultiplier;
    }

    /**
     * @dev Safe rewardToken transfer function, just in case
     * if rounding error causes pool to not have enough MIDASes.
     */
    function _safeTransfer(address _to, uint256 _amount) internal {
        uint256 midasBalance = rewardToken.balanceOf(address(this)) - poolInfo.totalDeposited;
        if (_amount > midasBalance) {
            rewardToken.safeTransfer(_to, midasBalance);
        } else {
            rewardToken.safeTransfer(_to, _amount);
        }
    }
}
