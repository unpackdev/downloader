// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./console.sol";
import "./IARVO.sol";
import "./ITerminal.sol";
import "./IFarming.sol";

// Debugging solution
// console.log("all it's fine = ", fuckyou);

// FIXME: the percentage from terminal contract

contract Farming is IFarming, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount);

    struct UserData {
        uint256 amount;
        uint256 outgoing;
    }
    mapping(uint256 => mapping(address => UserData)) public users;

    struct PoolData {
        IERC20 lpToken;
        uint256 recentUpdatedBlock;
        uint256 recentRewardsPerBlock;
    }
    PoolData[] public pools;

    // // Info of each pool.
    // struct PoolInfo {
    //     IERC20 lpToken;           // Address of LP token contract.
    //     uint256 allocPoint;       // How many allocation points assigned to this pool. SUSHIs to distribute per block.
    //     uint256 lastRewardBlock;  // Last block number that SUSHIs distribution occurs.
    //     uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    // }

    uint256 public maxPoolsCount;
    uint256 public TotalRewardPerBlock;
    uint256 public rewardsPerPool;

    IARVO public arvoToken;
    ITerminal public terminalContract;

    constructor(IARVO _arvoToken, uint256 _maxPoolsCount, address _terminalContract) public {
        arvoToken = _arvoToken;
        maxPoolsCount = _maxPoolsCount;
        terminalContract = ITerminal(_terminalContract);
    }

    function changeTerminalContract(address _terminalContract) public onlyOwner {
        require(_terminalContract != address(0), 'FARMING: the terminal address it is the zero address');
        terminalContract = ITerminal(_terminalContract);
    }

    function changeMaxPoolsCount(uint256 _maxPoolsCount) public onlyOwner {
        require(_maxPoolsCount > 0, 'FARMING: the maximum pools count is 0');
        maxPoolsCount = _maxPoolsCount;
    }

    function createPool(IERC20 _lpToken, uint256 _recentUpdatedBlock) external override onlyOwner {
        require(address(_lpToken) != address(0), 'FARMING: the lp token it is zero address');
        require(pools.length < maxPoolsCount, 'FARMING: the pools more than maximum');

        this.bulkUpgradePools();
        uint256 recentUpdated = block.number > _recentUpdatedBlock ? block.number : _recentUpdatedBlock;
        pools.push(PoolData({
            lpToken: _lpToken,
            recentUpdatedBlock: recentUpdated,
            recentRewardsPerBlock: 0
        }));
        this.updateRewardsPerPool();
    }

    function updateRewardsPerPool() external override {
        uint256 globalRewards = terminalContract.getRewardsPerBlock();
        rewardsPerPool = globalRewards.div(pools.length);
    }

    function countPools() external override view returns (uint256) {
        return pools.length;
    }

    function deposit(uint256 _poolId, uint256 _amount) public {
        PoolData storage pool = pools[_poolId];
        UserData storage user = users[_poolId][msg.sender];

        this.upgradePool(_poolId);

        if (user.amount > 0) {
            uint256 waiting = user.amount.mul(pool.recentRewardsPerBlock).div(1e12).sub(user.outgoing);
            if (waiting > 0) {
                safeRewardTransfer(msg.sender, waiting);
            }
        }

        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }


        user.outgoing = user.amount.mul(pool.recentRewardsPerBlock).div(1e12);
        // console.log("xxx: ", pool.recentRewardsPerBlock);

        emit Deposit(msg.sender, _poolId, _amount);
    }

    function withdraw(uint256 _poolId, uint256 _amount) public {
        PoolData storage pool = pools[_poolId];
        UserData storage user = users[_poolId][msg.sender];

        require(user.amount >= _amount, 'FARMING: no enough balance');
        this.upgradePool(_poolId);

        uint256 waiting = user.amount.mul(pool.recentRewardsPerBlock).div(1e12).sub(user.outgoing);
        if (waiting > 0) {
            safeRewardTransfer(msg.sender, waiting);
        } else {
            revert("FARMING: no waiting balance");
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        } else {
            revert("FARMING: no amount balance");
        }
        user.outgoing = user.amount.mul(pool.recentRewardsPerBlock).div(1e12);
        emit Withdraw(msg.sender, _poolId, _amount);
    }

    function safeRewardTransfer(address _to, uint256 _amount) public {
        console.log("amount in function", address(arvoToken));
        uint256 balance = arvoToken.balanceOf(address(this));
        if (_amount > balance) {
            arvoToken.transfer(_to, balance);
        } else {
            arvoToken.transfer(_to, _amount);
        }
    }

    function bulkUpgradePools() public {
        uint256 length = pools.length;
        for (uint256 poolId = 0; poolId < length; ++poolId) {
            this.upgradePool(poolId);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function upgradePool(uint256 _poolId) public {
        PoolData storage pool = pools[_poolId];

        if (block.number <= pool.recentUpdatedBlock) {
            return;
        }
        uint256 pooledLp = pool.lpToken.balanceOf(address(this));
        // console.log("pooledLp", pooledLp);
        if (pooledLp == 0) {
            pool.recentUpdatedBlock = block.number;
            return;
        }
        this.updateRewardsPerPool();
        uint256 blockSub = block.number.sub(pool.recentUpdatedBlock);
        uint256 mainReward = blockSub.mul(rewardsPerPool);
        terminalContract.mint(address(this), mainReward);
        pool.recentRewardsPerBlock = pool.recentRewardsPerBlock.add(mainReward.mul(1e12).div(pooledLp));
        pool.recentUpdatedBlock = block.number;
    }

    function waitingRewards(uint256 _poolId, address _user) external view returns (uint256) {
        PoolData storage pool = pools[_poolId];
        UserData storage user = users[_poolId][_user];
        uint256 recentRewardsPerBlock = pool.recentRewardsPerBlock;
        uint256 pooledLp = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.recentUpdatedBlock && pooledLp != 0) {
            uint256 blockSub = block.number.sub(pool.recentUpdatedBlock);
            uint256 mainReward = blockSub.mul(rewardsPerPool);
            recentRewardsPerBlock = recentRewardsPerBlock.add(mainReward.mul(1e12).div(pooledLp));
        }
        return user.amount.mul(recentRewardsPerBlock).div(1e12).sub(user.outgoing);
    }
}
