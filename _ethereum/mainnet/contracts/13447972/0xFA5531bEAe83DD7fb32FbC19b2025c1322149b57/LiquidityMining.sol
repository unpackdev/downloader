// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract LiquidityMining is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant DECIMALS = 18;
    uint256 private constant UNITS = 10**DECIMALS;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 tokenPerBlock; // TOKENs to distribute per block.
        uint256 lastRewardBlock; // Last block number that TOKEN distribution occurs.
        uint256 accTokenPerShare; // Accumulated TOKENs per share, times 1e18 (UNITS).
    }

    IERC20 public immutable token;
    address public tokenRewardsAddress;

    // The block number when TOKEN mining starts.
    uint256 public immutable START_BLOCK;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // tokenToPoolId
    mapping(address => uint256) public tokenToPoolId;

    // Info of each user that stakes LP tokens. pid => user address => info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);

    event Withdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    event SendTokenReward(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    //set token sc, reward address and start block
    constructor(
        address _tokenAddress,
        address _tokenRewardsAddress,
        uint256 _startBlock
    ) public {
        require(_tokenAddress != address(0),"error zero address");
        require(_tokenRewardsAddress != address(0),"error zero address");
        token = IERC20(_tokenAddress);
        tokenRewardsAddress = _tokenRewardsAddress;
        START_BLOCK = _startBlock;
    }

    /********************** PUBLIC ********************************/

    // Add a new erc20 token to the pool. Can only be called by the owner.
    function add(
        uint256 _tokenPerBlock,
        IERC20 _token,
        bool _withUpdate
    ) external onlyOwner {
        require(
            tokenToPoolId[address(_token)] == 0,
            "Token is already in pool"
        );

        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardBlock =
            block.number > START_BLOCK ? block.number : START_BLOCK;

        tokenToPoolId[address(_token)] = poolInfo.length + 1;

        poolInfo.push(
            PoolInfo({
                token: _token,
                tokenPerBlock: _tokenPerBlock,
                lastRewardBlock: lastRewardBlock,
                accTokenPerShare: 0
            })
        );
    }

    // Update the given pool's TOKEN allocation point. Can only be called by the owner.
    function set(
        uint256 _poolId,
        uint256 _tokenPerBlock,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        poolInfo[_poolId].tokenPerBlock = _tokenPerBlock;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;

        for (uint256 poolId = 0; poolId < length; ++poolId) {
            updatePool(poolId);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _poolId) public {
        PoolInfo storage pool = poolInfo[_poolId];

        // Return if it's too early (if START_BLOCK is in the future probably)
        if (block.number <= pool.lastRewardBlock) return;

        // Retrieve amount of tokens held in contract
        uint256 poolBalance = pool.token.balanceOf(address(this));

        // If the contract holds no tokens at all, don't proceed.
        if (poolBalance == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        // Calculate the amount of TOKEN to send to the contract to pay out for this pool
        uint256 rewards =
            getPoolReward(pool.lastRewardBlock, block.number, pool.tokenPerBlock);

        // Update the accumulated TOKENPerShare
        pool.accTokenPerShare = pool.accTokenPerShare.add(
            rewards.mul(UNITS).div(poolBalance)
        );

        // Update the last block
        pool.lastRewardBlock = block.number;
    }

    // Get rewards for a specific amount of TOKENPerBlocks
    function getPoolReward(
        uint256 _from,
        uint256 _to,
        uint256 _tokenPerBlock
    ) public view returns (uint256 rewards) {
        // Calculate number of blocks covered.
        uint256 blockCount = _to.sub(_from);

        // Get the amount of TOKEN for this pool
        uint256 amount = blockCount.mul(_tokenPerBlock);

        // Retrieve allowance and balance
        uint256 allowedToken =
            token.allowance(tokenRewardsAddress, address(this));
        uint256 farmingBalance = token.balanceOf(tokenRewardsAddress);

        // If the actual balance is less than the allowance, use the balance.
        allowedToken = farmingBalance < allowedToken ? farmingBalance : allowedToken;

        // If we reached the total amount allowed already, return the allowedToken
        if (allowedToken < amount) {
            rewards = allowedToken;
        } else {
            rewards = amount;
        }
    }

    function claimReward(uint256 _poolId) external {
        updatePool(_poolId);
        _harvest(_poolId);
    }

    // Deposit LP tokens to TOKENStaking for TOKEN allocation.
    function deposit(uint256 _poolId, uint256 _amount) external {
        require(_amount > 0, "Amount cannot be 0");

        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        updatePool(_poolId);

        _harvest(_poolId);

        pool.token.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(UNITS);
        emit Deposit(msg.sender, _poolId, _amount);
    }

    // Withdraw LP tokens from TOKENStaking.
    function withdraw(uint256 _poolId, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        require(_amount > 0, "Amount cannot be 0");

        updatePool(_poolId);
        _harvest(_poolId);

        user.amount = user.amount.sub(_amount);

        pool.token.safeTransfer(address(msg.sender), _amount);

        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(UNITS);

        emit Withdraw(msg.sender, _poolId, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _poolId) external {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        uint256 amountToSend = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        pool.token.safeTransfer(address(msg.sender), amountToSend);

        emit EmergencyWithdraw(msg.sender, _poolId, amountToSend);
    }

    /********************** EXTERNAL ********************************/

    // Return the number of added pools
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // View function to see pending TOKENs on frontend.
    function pendingReward(uint256 _poolId, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][_user];

        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 poolBalance = pool.token.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && poolBalance > 0) {
            uint256 rewards =
                getPoolReward(
                    pool.lastRewardBlock,
                    block.number,
                    pool.tokenPerBlock
                );
            accTokenPerShare = accTokenPerShare.add(
                rewards.mul(UNITS).div(poolBalance)
            );
        }

        uint256 pending =
            user.amount.mul(accTokenPerShare).div(UNITS).sub(user.rewardDebt);

        return pending;
    }

    /********************** INTERNAL ********************************/

    function _harvest(uint256 _poolId) internal {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        if (user.amount == 0) return;

        uint256 pending =
            user.amount.mul(pool.accTokenPerShare).div(UNITS).sub(
                user.rewardDebt
            );


        if (pending > 0) {
            // Retrieve allowance and balance
            uint256 allowedToken = token.allowance(tokenRewardsAddress, address(this));
            uint256 farmingBalance = token.balanceOf(tokenRewardsAddress);

            require(pending < allowedToken, "Reward wallet approve amount is not high enough!");
            require(pending < farmingBalance, "Reward wallet balance is not high enough!");


            user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(UNITS);

            // Pay out the pending rewards
            token.safeTransferFrom(tokenRewardsAddress, msg.sender, pending);

            emit SendTokenReward(msg.sender, _poolId, pending);
            return;
        }

        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(UNITS);
    }

    /********************** ADMIN ********************************/
    function changeRewardAddress(address _rewardAddress) external onlyOwner {
        require(_rewardAddress != address(0),"Address can't be 0");
        tokenRewardsAddress = _rewardAddress;
    }
}