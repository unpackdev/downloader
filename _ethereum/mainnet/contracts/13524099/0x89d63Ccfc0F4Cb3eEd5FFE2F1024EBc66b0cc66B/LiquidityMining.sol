//"SPDX-License-Identifier: MIT"
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./IERC20.sol";

contract LiquidityMining is Ownable {
    using SafeERC20 for IERC20;

    uint256 constant DECIMALS = 18;
    uint256 constant UNITS = 10**DECIMALS;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardDebtAtBlock; // the last block user stake
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 tokenPerBlock; // tokens to distribute per block. There are aprox. 6500 blocks per day. 6500 * 1825 (5 years) = 11862500 total blocks. 600000000 token to be distributed in 11862500  = 50,579557428872497 token per block.
        uint256 lastRewardBlock; // Last block number that token distribution occurs.
        uint256 acctokenPerShare; // Accumulated tokens per share, times 1e18 (UNITS).
        uint256 waitForWithdraw; // Spent tokens until now, even if they are not withdrawn.
    }

    IERC20 public tokenToken;
    address public tokenLiquidityMiningWallet;

    // The block number when token mining starts.
    uint256 public START_BLOCK;

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

    event TokenPerBlockSet(uint256 amount);

    constructor(
        address _tokenAddress,
        address _tokenLiquidityMiningWallet,
        uint256 _startBlock
    ) public  {
        require(_tokenAddress != address(0), "Token address should not be 0");
        require(_tokenLiquidityMiningWallet != address(0), "TokenLiquidityMiningWallet address should not be 0");
        tokenToken = IERC20(_tokenAddress);
        tokenLiquidityMiningWallet = _tokenLiquidityMiningWallet;
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

        uint256 lastRewardBlock = block.number > START_BLOCK
            ? block.number
            : START_BLOCK;

        tokenToPoolId[address(_token)] = poolInfo.length + 1;

        poolInfo.push(
            PoolInfo({
                token: _token,
                tokenPerBlock: _tokenPerBlock,
                lastRewardBlock: lastRewardBlock,
                acctokenPerShare: 0,
                waitForWithdraw: 0
            })
        );
    }

    // Update the given pool's token allocation point. Can only be called by the owner.
    function set(
        uint256 _poolId,
        uint256 _tokenPerBlock,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        poolInfo[_poolId].tokenPerBlock = _tokenPerBlock;
        emit TokenPerBlockSet(_tokenPerBlock);
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

        // Calculate the amount of token to send to the contract to pay out for this pool
        uint256 rewards = getPoolReward(
            pool.lastRewardBlock,
            block.number,
            pool.tokenPerBlock,
            pool.waitForWithdraw
        );
        pool.waitForWithdraw += rewards;

        // Update the accumulated tokenPerShare
        pool.acctokenPerShare = pool.acctokenPerShare + (rewards * UNITS/poolBalance);

        // Update the last block
        pool.lastRewardBlock = block.number;
    }

    // Get rewards for a specific amount of tokenPerBlocks
    function getPoolReward(
        uint256 _from,
        uint256 _to,
        uint256 _tokenPerBlock,
        uint256 _waitForWithdraw
    ) public view returns (uint256 rewards) {
        // Calculate number of blocks covered.
        uint256 blockCount = _to - _from;

        // Get the amount of token for this pool
        uint256 amount = blockCount*(_tokenPerBlock);

        // Retrieve allowance and balance
        uint256 allowedToken = tokenToken.allowance(
            tokenLiquidityMiningWallet,
            address(this)
        );
        uint256 farmingBalance = tokenToken.balanceOf(tokenLiquidityMiningWallet);

        // If the actual balance is less than the allowance, use the balance.
        allowedToken = farmingBalance < allowedToken
            ? farmingBalance
            : allowedToken;

        //no more token to pay as reward
        if(allowedToken <= _waitForWithdraw){
            return 0;
        }

        allowedToken = allowedToken - _waitForWithdraw;

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

    // Deposit LP tokens to tokenStaking for token allocation.
    function deposit(uint256 _poolId, uint256 _amount) external {
        require(_amount > 0, "Amount cannot be 0");

        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        updatePool(_poolId);

        _harvest(_poolId);

        // This is the very first deposit
        if (user.amount == 0) {
            user.rewardDebtAtBlock = block.number;
        }

        user.amount = user.amount+(_amount);
        user.rewardDebt = user.amount*(pool.acctokenPerShare)/(UNITS);
        emit Deposit(msg.sender, _poolId, _amount);

        pool.token.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
    }

    // Withdraw LP tokens from tokenStaking.
    function withdraw(uint256 _poolId, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        require(_amount > 0, "Amount cannot be 0");

        updatePool(_poolId);
        _harvest(_poolId);

        user.amount = user.amount-(_amount);

        user.rewardDebt = user.amount*(pool.acctokenPerShare)/(UNITS);

        emit Withdraw(msg.sender, _poolId, _amount);

        pool.token.safeTransfer(address(msg.sender), _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _poolId) external {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        uint256 amountToSend = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardDebtAtBlock = 0;

        emit EmergencyWithdraw(msg.sender, _poolId, amountToSend);

        pool.token.safeTransfer(address(msg.sender), amountToSend);
    }

    /********************** EXTERNAL ********************************/

    // Return the number of added pools
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // View function to see pending tokens on frontend.
    function pendingReward(uint256 _poolId, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][_user];

        uint256 acctokenPerShare = pool.acctokenPerShare;
        uint256 poolBalance = pool.token.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && poolBalance > 0) {
            uint256 rewards = getPoolReward(
                pool.lastRewardBlock,
                block.number,
                pool.tokenPerBlock,
                pool.waitForWithdraw
            );
            acctokenPerShare = acctokenPerShare+(
                rewards*(UNITS)/(poolBalance)
            );
        }

        uint256 pending = user.amount*(acctokenPerShare)/(UNITS)-(
            user.rewardDebt
        );

        return pending;
    }

    /********************** INTERNAL ********************************/

    function _harvest(uint256 _poolId) internal {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        if (user.amount == 0) return;

        uint256 pending = user.amount*(pool.acctokenPerShare)/(UNITS)-(user.rewardDebt);

        uint256 tokenAvailable = tokenToken.balanceOf(tokenLiquidityMiningWallet);

        if (pending > tokenAvailable) {
            pending = tokenAvailable;
        }

        if (pending > 0) {
            user.rewardDebtAtBlock = block.number;

            user.rewardDebt = user.amount*(pool.acctokenPerShare)/(UNITS);

            pool.waitForWithdraw -= pending;

            emit SendTokenReward(msg.sender, _poolId, pending);

            // Pay out the pending rewards
            tokenToken.safeTransferFrom(
                tokenLiquidityMiningWallet,
                msg.sender,
                pending
            );
            return;
        }

        user.rewardDebt = user.amount*(pool.acctokenPerShare)/(UNITS);
    }
    function changeRewardsWallet(address _address) external onlyOwner {
        require(_address != address(0),"Address should not be 0");
        tokenLiquidityMiningWallet = _address;
    }
}
