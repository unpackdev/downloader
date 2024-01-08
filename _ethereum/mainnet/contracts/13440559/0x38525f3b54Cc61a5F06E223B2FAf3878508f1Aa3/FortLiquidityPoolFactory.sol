// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./TransferHelper.sol";
import "./FortToken.sol";
import "./Bar.sol";

interface IMigrator {
    /**
     * Perform LP token migration from legacy UniswapV2 to FortSwap.
     * Take the current LP token address and return the new LP token address.
     * Migrator should have full access to the caller's LP token.
     * XXX Migrator must have allowance access to UniswapV2 LP tokens.
     * FortSwap must mint EXACTLY the same amount of FortSwap LP tokens or
     * else something bad will happen. Traditional UniswapV2 does not
     * do that so be careful!
     */
    function migrate(address token) external returns (address);
}

contract FortLiquidityPoolFactory is Ownable {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @param amountOfLpToken
     * @param rewardDebt
     */
    struct UserInfo {
        uint256 amountOfLpToken;
        uint256 rewardDebt;
        uint256 lock;
        uint256 lockDebt;
    }

    struct PoolInfo {
        address lpTokenAddress;
        uint256 allocationPoint;
        uint256 lastRewardBlock;
        uint256 accumulatedFortPerShare;
    }

    FortToken public fortToken;
    Bar public bar;
    uint256 public fortPerBlock;
    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public avgDailyBlocks = 6500;
    uint256 public programDuration = 12; // in weeks

    uint256 public poolCounter;
    uint256 public totalAllocationPoint;
    address public migrator;

    mapping(uint256 => PoolInfo) public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        address _fortAddress,
        address _barAddress,
        uint256 _fortPerBlock,
        uint256 _startBlock
    ) public {
        fortToken = FortToken(_fortAddress);
        bar = Bar(_barAddress);
        fortPerBlock = _fortPerBlock;
        startBlock = _startBlock;
        updateEndBlock();

        // Pool 0 (Fort) is a special pool and need to be initialized separately.
        // These dedicated pool ID will be used for further validations.
        poolInfo[poolCounter] = PoolInfo(_fortAddress, 7000, startBlock, 0);
        totalAllocationPoint = totalAllocationPoint.add(7000);
    }

    function setProgramDuration(uint256 _duration) public onlyOwner {
        require(
            _duration > 0,
            "invalid_params: duration must be greater than 0"
        );
        programDuration = _duration;
        updateEndBlock();
    }

    function setAvgDailyBlock(uint256 _avgDailyBlocks) public onlyOwner {
        require(
            _avgDailyBlocks > 0,
            "invalid_params: avg daily blocks must be greater than 0"
        );
        avgDailyBlocks = _avgDailyBlocks;
        updateEndBlock();
    }

    function updateEndBlock() internal {
        uint256 newEndBlock = startBlock.add(
            avgDailyBlocks.mul(programDuration).mul(7)
        );
        require(
            newEndBlock >= block.number,
            "bad_request: end block must be greater than current block"
        );
        endBlock = newEndBlock;
    }

    /**
     * @notice Set the migrator contract. Can only be called by the owner.
     */
    function setMigrator(address _migrator) public onlyOwner {
        require(_migrator != address(0), "Migrator can not equal address0");
        migrator = _migrator;
    }

    /**
     * @notice Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
     */
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = IERC20(pool.lpTokenAddress);
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        address newLpToken = IMigrator(migrator).migrate(pool.lpTokenAddress);
        require(
            bal == IERC20(newLpToken).balanceOf(address(this)),
            "migrate: bad"
        );
        pool.lpTokenAddress = newLpToken;
    }

    /**
     * @notice Add a new lp to the pool. Can only be called by the owner.
     */
    function addLpToken(
        uint256 _allocationPoint,
        address _lpTokenAddress,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        poolCounter++;
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocationPoint = totalAllocationPoint.add(_allocationPoint);

        poolInfo[poolCounter] = PoolInfo(
            _lpTokenAddress,
            _allocationPoint,
            lastRewardBlock,
            0
        );
    }

    function massUpdatePools() public {
        for (uint256 _pid = 1; _pid <= poolCounter; _pid++) {
            updatePool(_pid);
        }
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = IERC20(pool.lpTokenAddress).balanceOf(address(this));
        if (lpSupply > 0) {
            uint256 rewardingBlocks = (
                block.number > endBlock ? endBlock : block.number
            ).sub(pool.lastRewardBlock);
            uint256 fortReward = fortPerBlock
                .mul(rewardingBlocks)
                .mul(pool.allocationPoint)
                .div(totalAllocationPoint);
            pool.accumulatedFortPerShare = pool.accumulatedFortPerShare.add(
                fortReward.mul(1e12).div(lpSupply)
            );
        }
        pool.lastRewardBlock = block.number > endBlock
            ? endBlock
            : block.number;
    }

    function pendingFort(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        require(_pid <= poolCounter, "invalid_params: pool does not exist");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accumulatedFortPerShare = pool.accumulatedFortPerShare;
        uint256 lpSupply = IERC20(pool.lpTokenAddress).balanceOf(address(this));
        if (lpSupply == 0) {
            return 0;
        }

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 rewardingBlocks = (
                block.number > endBlock ? endBlock : block.number
            ) - pool.lastRewardBlock;
            uint256 fortReward = fortPerBlock
                .mul(rewardingBlocks)
                .mul(pool.allocationPoint)
                .div(totalAllocationPoint);
            accumulatedFortPerShare = accumulatedFortPerShare.add(
                fortReward.mul(1e12).div(lpSupply)
            );
        }
        return
            (
                user.amountOfLpToken.mul(accumulatedFortPerShare).sub(
                    user.rewardDebt
                )
            ).div(1e12) + user.lock;
    }

    /**
     * @notice Deposit LP tokens to Factory for fort allocation.
     */
    function deposit(uint256 _pid, uint256 _amount) public {
        require(
            block.number <= endBlock,
            "deposit_not_allowed: program has ended"
        );
        require(_pid <= poolCounter, "invalid_params: pool does not exist");
        require(_pid != 0, "invalid_params: invalid pool id"); // Not allow depositing to Fort pool

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        if (user.amountOfLpToken > 0) {
            uint256 pending = (
                user.amountOfLpToken.mul(pool.accumulatedFortPerShare).sub(
                    user.rewardDebt
                )
            ).div(1e12);
            if (pending > 0) {
                bar.safeFortTransfer(msg.sender, pending);
            }
        }
        IERC20(pool.lpTokenAddress).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amountOfLpToken = user.amountOfLpToken.add(_amount);
        user.rewardDebt = user.amountOfLpToken.mul(
            pool.accumulatedFortPerShare
        );
        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
     * @notice Withdraw LP tokens from Factory
     */
    function withdraw(uint256 _pid, uint256 _amount) public {
        require(_pid <= poolCounter, "invalid_params: pool does not exist");
        require(_pid != 0, "invalid_params: invalid pool id");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(
            user.amountOfLpToken >= _amount,
            "bad_request: not enough fund"
        );

        updatePool(_pid);

        uint256 pending = (
            user.amountOfLpToken.mul(pool.accumulatedFortPerShare).sub(
                user.rewardDebt
            )
        ).div(1e12);
        bar.safeFortTransfer(msg.sender, pending);
        user.amountOfLpToken = user.amountOfLpToken.sub(_amount);
        user.rewardDebt = user.amountOfLpToken.mul(
            pool.accumulatedFortPerShare
        );
        IERC20(pool.lpTokenAddress).safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
     * @notice Stake Fort
     */
    function enterStaking(uint256 _amount) public {
        require(
            block.number <= endBlock,
            "stake_not_allowed: program has ended"
        );

        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];

        updatePool(0);

        if (user.amountOfLpToken > 0) {
            uint256 pending = (
                user.amountOfLpToken.mul(pool.accumulatedFortPerShare).sub(
                    user.rewardDebt
                )
            ).div(1e12);
            if (pending > 0) {
                uint256 release = pending.mul(20).div(100);
                bar.safeFortTransfer(msg.sender, release);
                user.lock = user.lock.add(pending.mul(80).div(100));
            }
        }
        if (_amount > 0) {
            IERC20(pool.lpTokenAddress).safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amountOfLpToken = user.amountOfLpToken.add(_amount);
        }
        user.rewardDebt = user.amountOfLpToken.mul(
            pool.accumulatedFortPerShare
        );

        bar.mint(msg.sender, _amount);
        emit Deposit(msg.sender, 0, _amount);
    }

    /**
     * @notice Unstake Fort
     */
    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(
            user.amountOfLpToken >= _amount,
            "bad_request: not enough fund"
        );

        updatePool(0);

        uint256 pending = (
            user.amountOfLpToken.mul(pool.accumulatedFortPerShare).sub(
                user.rewardDebt
            )
        ).div(1e12);

        uint256 release = pending.mul(20).div(100);
        if (block.number > endBlock) {
            user.lock = user.lock.add(pending.mul(80).div(100));
            // Allow withdrawing 2% per week
            uint256 weekNo = (uint256(block.number).sub(endBlock)).div(
                avgDailyBlocks.mul(7)
            ) + 1;
            uint256 accumulatedReward = user.lock.mul(weekNo).mul(2).div(
                100
            );
            bar.safeFortTransfer(
                msg.sender,
                release.add(accumulatedReward.sub(user.lockDebt))
            );
            user.lockDebt = accumulatedReward;
        } else {
            if (release > 0) {
                bar.safeFortTransfer(msg.sender, release);
                user.lock = user.lock.add(pending.mul(80).div(100));
            }
        }
        if (_amount > 0) {
            user.amountOfLpToken = user.amountOfLpToken.sub(_amount);
            IERC20(pool.lpTokenAddress).safeTransfer(
                address(msg.sender),
                _amount
            );
        }
        user.rewardDebt = user.amountOfLpToken.mul(
            pool.accumulatedFortPerShare
        );
        bar.burn(msg.sender, _amount);
        emit Withdraw(msg.sender, 0, _amount);
    }

    /**
     * @notice Withdraw without caring about rewards. EMERGENCY ONLY.
     */
    function emergencyWithdraw(uint256 _pid) public {
        require(_pid <= poolCounter, "invalid_params: pool does not exist");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 amount = user.amountOfLpToken;
        user.amountOfLpToken = 0;
        user.rewardDebt = 0;
        IERC20(pool.lpTokenAddress).safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Update the given pool's FORT allocation point. Can only be called by the owner.
    function setAllocationPoint(
        uint256 _pid,
        uint256 _allocationPoint,
        bool _withUpdate
    ) public onlyOwner {
        require(_pid <= poolCounter, "invalid_params: pool does not exist");

        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocationPoint = totalAllocationPoint
            .sub(poolInfo[_pid].allocationPoint)
            .add(_allocationPoint);
        poolInfo[_pid].allocationPoint = _allocationPoint;
    }

    receive() external payable {}

    fallback() external payable {}
}
