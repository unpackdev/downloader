// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./console.sol";
import "./LpToken.sol";
import "./IARVO.sol";
import "./ITerminal.sol";
import "./IFarming.sol";
import "./IGFarming.sol";
import "./ILpToken.sol";


contract Farming is IFarming, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount,
        uint256 rewards
    );

    struct UserData {
        uint256 amount;
        uint256 outgoing;
    }
    mapping(uint256 => mapping(address => UserData)) public users;

    struct PoolData {
        IERC20 farmingToken;
        uint256 recentUpdatedBlock;
        uint256 recentRewardsPerBlock;
    }
    PoolData[] public pools;

    uint256 public rewardsPerPool;

    IARVO private arvoToken;
    ITerminal private terminalContract;
    IGFarming private GFarming;
    ILpToken public lpToken;

    constructor(
        address _arvoToken,
        address _terminalContract,
        address _GFarming
    ) public {
        arvoToken = IARVO(_arvoToken);
        terminalContract = ITerminal(_terminalContract);
        GFarming = IGFarming(_GFarming);

        // deploy lp token
        lpToken = new LpToken('Arvo Farming LP', 'AFLP', 0, address(this));
    }

    // Emergency change the contract address will be expired with burn the owner address
    function changeTerminalContract(address _terminalContract)
        public
        onlyOwner
    {
        require(
            _terminalContract != address(0),
            '[4508] FARMING: the terminal address is the zero address'
        );
        terminalContract = ITerminal(_terminalContract);
    }

    // Emergency change the contract address will be expired with burn the owner address
    function changeGFarming(address _GFarming) public onlyOwner {
        require(
            _GFarming != address(0),
            '[4507] FARMING: the governance terminal address is the zero address'
        );
        GFarming = IGFarming(_GFarming);
    }

    function createPool(IERC20 _farmingToken, uint256 _recentUpdatedBlock)
        external
        override
        onlyOwner
    {
        require(
            address(_farmingToken) != address(0),
            '[4506] FARMING: the lp token it is zero address'
        );
        require(
            pools.length < GFarming.maxPools(),
            '[4505] FARMING: the pools more than maximum'
        );

        this.bulkUpgradePools();

        uint256 recentUpdated = block.number > _recentUpdatedBlock
            ? block.number
            : _recentUpdatedBlock;
        pools.push(
            PoolData({
                farmingToken: _farmingToken,
                recentUpdatedBlock: recentUpdated,
                recentRewardsPerBlock: 0
            })
        );

        this.updateRewardsPerPool();
    }

    function updateRewardsPerPool() external override {
        uint256 globalRewards = GFarming.rewardsPerBlock();
        rewardsPerPool = globalRewards.div(pools.length);
    }

    function countPools() external override view returns (uint256) {
        return pools.length;
    }

    function deposit(uint256 _poolId, uint256 _amount) public override {
        PoolData storage pool = pools[_poolId];
        UserData storage user = users[_poolId][msg.sender];

        this.upgradePool(_poolId);

        uint256 waiting = 0;
        if (user.amount > 0) {
            waiting = user.amount.mul(pool.recentRewardsPerBlock).div(1e18).sub(
                user.outgoing
            );
            if (waiting > 0) {
                rewardTransfer(address(msg.sender), waiting);
            }
        }

        if (_amount > 0) {
            pool.farmingToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            lpToken.mint(address(msg.sender), _amount);
            user.amount = user.amount.add(_amount);
        }

        if (waiting <= 0 && _amount <= 0) {
            revert('[4504] FARMING: not have any result');
        }

        user.outgoing = user.amount.mul(pool.recentRewardsPerBlock).div(1e18);

        emit Deposit(msg.sender, _poolId, _amount);
    }

    function withdraw(uint256 _poolId, uint256 _amount) public override {
        PoolData storage pool = pools[_poolId];
        UserData storage user = users[_poolId][msg.sender];

        require(user.amount >= _amount, '[4503] FARMING: no enough balance');

        this.upgradePool(_poolId);

        uint256 waiting = user
            .amount
            .mul(pool.recentRewardsPerBlock)
            .div(1e18)
            .sub(user.outgoing);
        if (waiting > 0) {
            waiting = rewardTransfer(address(msg.sender), waiting);
        }

        if (_amount > 0) {
            if (!GFarming.lockForever()) {
                if (lpToken.balanceOf(address(msg.sender)) >= _amount) {
                    lpToken.burn(address(msg.sender), _amount);
                    user.amount = user.amount.sub(_amount);
                    pool.farmingToken.safeTransfer(
                        address(msg.sender),
                        _amount
                    );
                }
            }
        }

        if (waiting <= 0 && _amount <= 0) {
            revert('[4502] FARMING: not have any result');
        }

        user.outgoing = user.amount.mul(pool.recentRewardsPerBlock).div(1e18);

        emit Withdraw(msg.sender, _poolId, _amount, waiting);
    }

    function rewardTransfer(address _to, uint256 _amount)
        internal
        returns (uint256)
    {
        uint256 balance = arvoToken.balanceOf(address(this));

        if (_amount > balance) {
            arvoToken.transfer(_to, balance);
            return balance;
        } else {
            arvoToken.transfer(_to, _amount);
            return _amount;
        }
    }

    function bulkUpgradePools() public override {
        uint256 length = pools.length;

        for (uint256 poolId = 0; poolId < length; ++poolId) {
            this.upgradePool(poolId);
        }
    }

    function upgradePool(uint256 _poolId) public override {
        PoolData storage pool = pools[_poolId];

        if (block.number <= pool.recentUpdatedBlock) {
            return;
        }

        uint256 pooledLp = pool.farmingToken.balanceOf(address(this));
        if (pooledLp == 0) {
            pool.recentUpdatedBlock = block.number;
            return;
        }

        this.updateRewardsPerPool();

        uint256 blockSub = block.number.sub(pool.recentUpdatedBlock);
        uint256 mainReward = blockSub.mul(rewardsPerPool);

        // Mint rewards from terminal contract
        terminalContract.mint(address(this), mainReward);

        pool.recentRewardsPerBlock = pool.recentRewardsPerBlock.add(
            mainReward.mul(1e18).div(pooledLp)
        );

        pool.recentUpdatedBlock = block.number;
    }

    // Return waiting rewards for every user in pool
    function waitingRewards(uint256 _poolId, address _user)
        external
        view
        override
        returns (uint256)
    {
        PoolData storage pool = pools[_poolId];
        UserData storage user = users[_poolId][_user];

        require(user.amount > 0, '[4501] FARMING: this user not have any deposits');
        require(arvoToken.totalSupply() < terminalContract.getMaximumSupply(), '[4500] FARMING: you exceeded the limit');

        uint256 recentRewardsPerBlock = pool.recentRewardsPerBlock;
        uint256 pooledLp = pool.farmingToken.balanceOf(address(this));

        if (block.number > pool.recentUpdatedBlock && pooledLp != 0) {
            uint256 blockSub = block.number.sub(pool.recentUpdatedBlock);
            uint256 mainReward = blockSub.mul(rewardsPerPool);
            recentRewardsPerBlock = recentRewardsPerBlock.add(
                mainReward.mul(1e18).div(pooledLp)
            );
        }

        return
            user.amount.mul(recentRewardsPerBlock).div(1e18).sub(user.outgoing);
    }
}
