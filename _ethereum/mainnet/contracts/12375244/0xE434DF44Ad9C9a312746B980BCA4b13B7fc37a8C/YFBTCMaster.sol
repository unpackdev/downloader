// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./YFBitcoin.sol";
import "./UniswapV2Pair.sol";

contract YFBTCMaster is Ownable {
    using SafeMath for *;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 lastRewardBlock;
        uint256 accYfbtcPerShare; // Accumulated YFBTC per share, times 1e12. See below.
        uint256 totalSupply;
    }

    struct RewardInfo {
        uint256 startBlock;
        uint256 endBlock;
        uint256 rewardFrom;
        uint256 rewardTo;
        uint256 rewardPerBlock;
    }

    uint256 public lastPrice = 0;

    uint256 public constant PERIOD = 24 hours;

    uint256 public constant CHANGE_IN_PERCENTAGE = 5;

    // hold factory address that will be used to fetch pair address
    address public pairAddress;

    // block time of last update
    uint32 public blockTimestampLast;

    // The YFBTC TOKEN!
    YFBitcoin public yfbtc;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    //info of reward pools

    RewardInfo[] public rewardInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // The block number when YFBTC mining starts.
    uint256 public startedBlock;

    event SetDevAddress(address indexed _devAddress);
    event SetTransferFee(uint256 _fee);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdrawExceptional(address indexed user, uint256 amount);

    constructor(
        YFBitcoin _yfbtc,
        address _pairAddress,
        uint256 _startedBlock
    ) public {
        yfbtc = _yfbtc;
        pairAddress = _pairAddress;
        startedBlock = _startedBlock;
        (uint112 reserve0, uint112 reserve1, uint32 blockTime) = UniswapV2Pair(pairAddress).getReserves(); // gas savings
        blockTimestampLast = blockTime;
        lastPrice = reserve1;
        require(reserve0 != 0 && reserve1 != 0, "ORACLE: NO_RESERVES"); // ensure that there's liquidity in the pair
        addRewardSet();
    }

    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    function setDevAddress(address _devAddress) external onlyOwner {
        require(_devAddress != address(0x0), "zero address is not allowed");
        yfbtc.setDevAddress(_devAddress);
        emit SetDevAddress(_devAddress);
    }

    function setTransferFee(uint256 _fee) external onlyOwner {
        require(_fee > 0 && _fee < 1000, "YFBTC: fee should be between 0 and 10");
        yfbtc.setTransferFee(_fee);
        emit SetTransferFee(_fee);
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        yfbtc.mint(_to, _amount);
    }

    function burn(address _sender, uint256 _amount) public onlyOwner {
        yfbtc.burn(_sender, _amount);
    }

    function update() public returns (bool) {
        uint32 blockTimestamp = currentBlockTimestamp();
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        if (timeElapsed >= PERIOD) {
            uint256 change = 0;
            (, uint112 _reserve1, ) = UniswapV2Pair(pairAddress).getReserves(); // gas savings

            uint256 currentPrice = _reserve1;

            if (lastPrice > currentPrice) {
                change = lastPrice.sub(currentPrice).mul(100).div(lastPrice);
            }

            if (change >= CHANGE_IN_PERCENTAGE) {
                return false;
            } else {
                lastPrice = currentPrice;
                blockTimestampLast = blockTimestamp;
            }
        }

        return true;
    }

    function updateOwnerShip(address newOwner) public onlyOwner {
        yfbtc.transferOwnership(newOwner);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(IERC20 _lpToken) external onlyOwner {
        //EDIT commenting lastRewardBlock per pool (it is now common for all pools)
        //uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        require(address(_lpToken) != address(0), "MC: _lpToken should not be address zero");

        for (uint256 i = 0; i < poolInfo.length; i++) {
            require(address(poolInfo[i].lpToken) != address(_lpToken), "MC: DO NOT add the same LP token more than once");
        }
        uint256 lastRewardBlock = block.number > startedBlock ? block.number : startedBlock;
        poolInfo.push(PoolInfo({lpToken: _lpToken, accYfbtcPerShare: 0, lastRewardBlock: lastRewardBlock, totalSupply: 0}));
    }

    function addRewardSet() internal returns (uint256) {
        rewardInfo.push(
            RewardInfo({
                startBlock: startedBlock,
                endBlock: startedBlock.add(172800),
                rewardFrom: 1900 * 10**18,
                rewardTo: 3150 * 10**18,
                rewardPerBlock: 17606095680000000
            })
        );
        rewardInfo.push(
            RewardInfo({
                startBlock: startedBlock.add(172800),
                endBlock: startedBlock.add(1036800),
                rewardFrom: 3150 * 10**18,
                rewardTo: 8960 * 10**18,
                rewardPerBlock: 8641975309000000
            })
        );
        rewardInfo.push(
            RewardInfo({
                startBlock: startedBlock.add(1036800),
                endBlock: startedBlock.add(2073600),
                rewardFrom: 8960 * 10**18,
                rewardTo: 16590 * 10**18,
                rewardPerBlock: 4320987654000000
            })
        );
        rewardInfo.push(
            RewardInfo({
                startBlock: startedBlock.add(2073600),
                endBlock: startedBlock.add(3110400),
                rewardFrom: 16590 * 10**18,
                rewardTo: 18830 * 10**18,
                rewardPerBlock: 2160493827000000
            })
        );
        rewardInfo.push(
            RewardInfo({
                startBlock: startedBlock.add(3110400),
                endBlock: startedBlock.add(4147200),
                rewardFrom: 18830 * 10**18,
                rewardTo: 19950 * 10**18,
                rewardPerBlock: 1080246914000000
            })
        );
        rewardInfo.push(
            RewardInfo({
                startBlock: startedBlock.add(4147200),
                endBlock: startedBlock.add(5184000),
                rewardFrom: 19950 * 10**18,
                rewardTo: 20510 * 10**18,
                rewardPerBlock: 540123456800000
            })
        );
        rewardInfo.push(
            RewardInfo({
                startBlock: startedBlock.add(5184000),
                endBlock: startedBlock.add(6220800),
                rewardFrom: 20510 * 10**18,
                rewardTo: 20790 * 10**18,
                rewardPerBlock: 270061728400000
            })
        );
        rewardInfo.push(
            RewardInfo({
                startBlock: startedBlock.add(6220800),
                endBlock: startedBlock.add(7257600),
                rewardFrom: 20790 * 10**18,
                rewardTo: 20930 * 10**18,
                rewardPerBlock: 135030864200000
            })
        );
        rewardInfo.push(
            RewardInfo({
                startBlock: startedBlock.add(7257600),
                endBlock: startedBlock.add(8294400),
                rewardFrom: 20930 * 10**18,
                rewardTo: 21000 * 10**18,
                rewardPerBlock: 67515432100000
            })
        );
        return 0;
    }

    function getPoolBaseMultiplier(uint256 _pid) public view returns (uint256) {
        if (_pid == 0) {
            return 20;
        } else if (_pid == 1) {
            return 4;
        } else if (_pid == 2) {
            return 1;
        } else {
            return 1;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 difference = _to.sub(_from);
        if (difference <= 0 || _from < startedBlock) return 0;

        uint256 totalReward = 0;

        uint256 supply = yfbtc.totalSupply();

        if (supply >= rewardInfo[rewardInfo.length.sub(1)].rewardTo) return 0;

        uint256 rewardSetlength = rewardInfo.length;

        if (_to >= rewardInfo[rewardInfo.length.sub(1)].endBlock) {
            totalReward = _to.sub(_from).mul(rewardInfo[3].rewardPerBlock);
        } else {
            for (uint256 rid = 0; rid < rewardSetlength; ++rid) {
                // if (supply >= rewardInfo[rid].rewardFrom) {
                if (_to <= rewardInfo[rid].endBlock) {
                    totalReward = totalReward.add(((_to.sub(_from)).mul(rewardInfo[rid].rewardPerBlock)));
                    break;
                } else {
                    if (rewardInfo[rid].endBlock <= _from) {
                        continue;
                    }
                    totalReward = totalReward.add(((rewardInfo[rid].endBlock.sub(_from)).mul(rewardInfo[rid].rewardPerBlock)));
                    supply = rewardInfo[rid].rewardTo;
                    _from = rewardInfo[rid].endBlock;
                }
                // }
            }
        }
        uint256 totalMultipliers = sumOfMultipliers();

        if (totalMultipliers == 0) return 0;

        uint256 rewardPerPool = totalReward.div(totalMultipliers);

        return rewardPerPool;
    }

    // View function to see pending YFBTC on frontend.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        require(address(pool.lpToken) != address(0), "MC: _pid is incorrect");
        UserInfo memory user = userInfo[_pid][_user];

        uint256 accYfbtcPerShare = pool.accYfbtcPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 rewardPerPool = getMultiplier(pool.lastRewardBlock, block.number);
            accYfbtcPerShare = accYfbtcPerShare.add(rewardPerPool.mul(getPoolBaseMultiplier(_pid)).mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accYfbtcPerShare).div(1e12).sub(user.rewardDebt);
    }

    function estimateReward(
        uint256 _pid,
        address _user,
        uint256 to
    ) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        require(address(pool.lpToken) != address(0), "MC: _pid is incorrect");
        UserInfo memory user = userInfo[_pid][_user];

        uint256 accYfbtcPerShare = pool.accYfbtcPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 rewardPerPool = getMultiplier(pool.lastRewardBlock, to);
            accYfbtcPerShare = accYfbtcPerShare.add(rewardPerPool.mul(getPoolBaseMultiplier(_pid)).mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accYfbtcPerShare).div(1e12).sub(user.rewardDebt);
    }

    function sumOfMultipliers() internal view returns (uint256) {
        uint256 eligibleMultipliers = 0;
        uint256 length = poolInfo.length;

        // Reward will only be assign to pools when they the staked balance is > 0
        for (uint256 pid = 0; pid < length; ++pid) {
            if (poolInfo[pid].totalSupply > 0) {
                eligibleMultipliers = eligibleMultipliers.add(getPoolBaseMultiplier(pid));
            }
        }
        return eligibleMultipliers;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        require(address(pool.lpToken) != address(0), "MC: _pid is incorrect");

        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        bool doMint = update();

        if (doMint) {
            uint256 yfbtcReward = getMultiplier(pool.lastRewardBlock, block.number);
            if (yfbtcReward <= 0) return;

            yfbtcReward = yfbtcReward.mul(getPoolBaseMultiplier(_pid));
            pool.accYfbtcPerShare = pool.accYfbtcPerShare.add(yfbtcReward.mul(1e12).div(lpSupply));

            yfbtc.mint(address(this), yfbtcReward);
            pool.lastRewardBlock = block.number;
        }
    }

    // Deposit LP tokens to MasterChef for YFBTC allocation.
    function deposit(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        require(address(pool.lpToken) != address(0), "MC: _pid is incorrect");

        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accYfbtcPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeYfbtcTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            pool.totalSupply = pool.totalSupply.add(_amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accYfbtcPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        require(address(pool.lpToken) != address(0), "MC: _pid is incorrect");
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accYfbtcPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeYfbtcTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.totalSupply = pool.totalSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accYfbtcPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // let user exist in case of emergency
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        require(address(pool.lpToken) != address(0), "MC: _pid is incorrect");
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        pool.totalSupply = pool.totalSupply.sub(amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe yfbtcReward transfer function, just in case if rounding error causes pool to not have enough YFBTC.
    function safeYfbtcTransfer(address _to, uint256 _amount) internal {
        uint256 yfbtcBal = yfbtc.balanceOf(address(this));
        if (_amount > yfbtcBal) {
            yfbtc.transfer(_to, yfbtcBal);
            emit EmergencyWithdrawExceptional(_to, _amount);
        } else {
            yfbtc.transfer(_to, _amount);
        }
    }
}
