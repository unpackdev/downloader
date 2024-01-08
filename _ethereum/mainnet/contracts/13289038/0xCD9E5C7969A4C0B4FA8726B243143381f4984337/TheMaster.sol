// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2ERC20.sol";
import "./ITheMaster.sol";
import "./MasterChefModule.sol";

contract TheMaster is Ownable, MasterChefModule, ITheMaster {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        address addr;
        bool delegate;
        ISupportable supportable;
        uint8 supportingRatio; //out of 100
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
        uint256 supply;
    }

    uint256 private constant PRECISION = 1e20;

    uint256 public immutable override initialRewardPerBlock;
    uint256 public immutable override decreasingInterval;
    uint256 public immutable override startBlock;

    IMaidCoin public immutable override maidCoin;
    IRewardCalculator public override rewardCalculator;

    PoolInfo[] public override poolInfo;
    mapping(uint256 => mapping(uint256 => UserInfo)) public override userInfo;
    mapping(uint256 => mapping(address => uint256)) private sushiRewardDebt;
    mapping(address => bool) public override mintableByAddr;
    uint256 public override totalAllocPoint;

    constructor(
        uint256 _initialRewardPerBlock,
        uint256 _decreasingInterval,
        uint256 _startBlock,
        IMaidCoin _maidCoin,
        IUniswapV2Pair _lpToken,
        IERC20 _sushi
    ) MasterChefModule(_lpToken, _sushi) {
        initialRewardPerBlock = _initialRewardPerBlock;
        decreasingInterval = _decreasingInterval;
        startBlock = _startBlock;
        maidCoin = _maidCoin;
    }

    function poolCount() external view override returns (uint256) {
        return poolInfo.length;
    }

    function pendingReward(uint256 pid, uint256 userId) external view override returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][userId];
        (uint256 accRewardPerShare, uint256 supply) = (pool.accRewardPerShare, pool.supply);
        uint256 _lastRewardBlock = pool.lastRewardBlock;
        if (block.number > _lastRewardBlock && supply != 0) {
            uint256 reward = ((block.number - _lastRewardBlock) * rewardPerBlock() * pool.allocPoint) / totalAllocPoint;
            accRewardPerShare = accRewardPerShare + (reward * PRECISION) / supply;
        }
        uint256 pending = ((user.amount * accRewardPerShare) / PRECISION) - user.rewardDebt;
        uint256 _supportingRatio = pool.supportingRatio;
        if (_supportingRatio == 0) {
            return pending;
        } else {
            return pending - ((pending * _supportingRatio) / 100);
        }
    }

    function rewardPerBlock() public view override returns (uint256) {
        if (address(rewardCalculator) != address(0)) {
            return rewardCalculator.rewardPerBlock();
        }
        uint256 era = (block.number - startBlock) / decreasingInterval;
        return initialRewardPerBlock / (era + 1);
    }

    function changeRewardCalculator(address addr) external override onlyOwner {
        rewardCalculator = IRewardCalculator(addr);
        emit ChangeRewardCalculator(addr);
    }

    function add(
        address addr,
        bool delegate,
        bool mintable,
        address supportable,
        uint8 supportingRatio,
        uint256 allocPoint
    ) external override onlyOwner {
        if (supportable != address(0)) {
            require(supportingRatio > 0 && supportingRatio <= 80, "TheMaster: Outranged supportingRatio");
        } else {
            require(supportingRatio == 0, "TheMaster: Not supportable pool");
        }
        massUpdatePools();
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint += allocPoint;
        uint256 pid = poolInfo.length;
        poolInfo.push(
            PoolInfo(addr, delegate, ISupportable(supportable), supportingRatio, allocPoint, lastRewardBlock, 0, 0)
        );
        if (mintable) {
            mintableByAddr[addr] = true;
        }
        emit Add(pid, addr, delegate, mintableByAddr[addr], supportable, supportingRatio, allocPoint);
    }

    function set(uint256[] calldata pids, uint256[] calldata allocPoints) external override onlyOwner {
        massUpdatePools();
        for (uint256 i = 0; i < pids.length; i += 1) {
            totalAllocPoint = totalAllocPoint - poolInfo[pids[i]].allocPoint + allocPoints[i];
            poolInfo[pids[i]].allocPoint = allocPoints[i];
            emit Set(pids[i], allocPoints[i]);
        }
    }

    function updatePool(PoolInfo storage pool) internal {
        uint256 _lastRewardBlock = pool.lastRewardBlock;
        if (block.number <= _lastRewardBlock) {
            return;
        }
        uint256 supply = pool.supply;
        if (supply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 reward = ((block.number - _lastRewardBlock) * rewardPerBlock() * pool.allocPoint) / totalAllocPoint;
        maidCoin.mint(address(this), reward);
        pool.accRewardPerShare = pool.accRewardPerShare + (reward * PRECISION) / supply;
        pool.lastRewardBlock = block.number;
    }

    function massUpdatePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(poolInfo[pid]);
        }
    }

    function deposit(
        uint256 pid,
        uint256 amount,
        uint256 userId
    ) public override {
        PoolInfo storage pool = poolInfo[pid];
        require(address(pool.supportable) == address(0), "TheMaster: Use support func");
        UserInfo storage user = userInfo[pid][userId];
        if (pool.delegate) {
            require(pool.addr == msg.sender, "TheMaster: Not called by delegate");
            _deposit(pid, pool, user, amount, false);
        } else {
            require(address(uint160(userId)) == msg.sender, "TheMaster: Deposit to your address");
            _deposit(pid, pool, user, amount, true);
        }
        emit Deposit(userId, pid, amount);
    }

    function _deposit(
        uint256 pid,
        PoolInfo storage pool,
        UserInfo storage user,
        uint256 amount,
        bool tokenTransfer
    ) internal {
        updatePool(pool);
        uint256 _accRewardPerShare = pool.accRewardPerShare;
        uint256 _amount = user.amount;
        if (_amount > 0) {
            uint256 pending = ((_amount * _accRewardPerShare) / PRECISION) - user.rewardDebt;
            if (pending > 0) safeRewardTransfer(msg.sender, pending);
        }
        if (amount > 0) {
            if (tokenTransfer) {
                IERC20(pool.addr).safeTransferFrom(msg.sender, address(this), amount);
                uint256 _mcPid = masterChefPid;
                if (_mcPid > 0 && pool.addr == address(lpToken)) {
                    sushiRewardDebt[pid][msg.sender] = _depositModule(
                        _mcPid,
                        amount,
                        _amount,
                        sushiRewardDebt[pid][msg.sender]
                    );
                }
            }
            pool.supply += amount;
            _amount += amount;
            user.amount = _amount;
        }
        user.rewardDebt = (_amount * _accRewardPerShare) / PRECISION;
    }

    function depositWithPermit(
        uint256 pid,
        uint256 amount,
        uint256 userId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        IUniswapV2ERC20(poolInfo[pid].addr).permit(msg.sender, address(this), amount, deadline, v, r, s);
        deposit(pid, amount, userId);
    }

    function depositWithPermitMax(
        uint256 pid,
        uint256 amount,
        uint256 userId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        IUniswapV2ERC20(poolInfo[pid].addr).permit(msg.sender, address(this), type(uint256).max, deadline, v, r, s);
        deposit(pid, amount, userId);
    }

    function withdraw(
        uint256 pid,
        uint256 amount,
        uint256 userId
    ) public override {
        PoolInfo storage pool = poolInfo[pid];
        require(address(pool.supportable) == address(0), "TheMaster: Use desupport func");
        UserInfo storage user = userInfo[pid][userId];
        if (pool.delegate) {
            require(pool.addr == msg.sender, "TheMaster: Not called by delegate");
            _withdraw(pid, pool, user, amount, false);
        } else {
            require(address(uint160(userId)) == msg.sender, "TheMaster: Not called by user");
            _withdraw(pid, pool, user, amount, true);
        }
        emit Withdraw(userId, pid, amount);
    }

    function _withdraw(
        uint256 pid,
        PoolInfo storage pool,
        UserInfo storage user,
        uint256 amount,
        bool tokenTransfer
    ) internal {
        uint256 _amount = user.amount;
        require(_amount >= amount, "TheMaster: Insufficient amount");
        updatePool(pool);
        uint256 _accRewardPerShare = pool.accRewardPerShare;
        uint256 pending = ((_amount * _accRewardPerShare) / PRECISION) - user.rewardDebt;
        if (pending > 0) safeRewardTransfer(msg.sender, pending);
        if (amount > 0) {
            pool.supply -= amount;
            _amount -= amount;
            user.amount = _amount;
            if (tokenTransfer) {
                uint256 _mcPid = masterChefPid;
                if (_mcPid > 0 && pool.addr == address(lpToken)) {
                    sushiRewardDebt[pid][msg.sender] = _withdrawModule(
                        _mcPid,
                        amount,
                        _amount + amount,
                        sushiRewardDebt[pid][msg.sender]
                    );
                }

                IERC20(pool.addr).safeTransfer(msg.sender, amount);
            }
        }
        user.rewardDebt = (_amount * _accRewardPerShare) / PRECISION;
    }

    function emergencyWithdraw(uint256 pid) external override {
        PoolInfo storage pool = poolInfo[pid];
        require(address(pool.supportable) == address(0), "TheMaster: Use desupport func");
        require(!pool.delegate, "TheMaster: Pool should be non-delegate");
        UserInfo storage user = userInfo[pid][uint256(uint160(msg.sender))];
        uint256 amounts = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.supply -= amounts;

        uint256 _mcPid = masterChefPid;
        if (_mcPid > 0 && pool.addr == address(lpToken)) {
            sushiRewardDebt[pid][msg.sender] = _withdrawModule(
                _mcPid,
                amounts,
                amounts,
                sushiRewardDebt[pid][msg.sender]
            );
        }

        IERC20(pool.addr).safeTransfer(msg.sender, amounts);
        emit EmergencyWithdraw(msg.sender, pid, amounts);
    }

    function support(
        uint256 pid,
        uint256 amount,
        uint256 supportTo
    ) public override {
        PoolInfo storage pool = poolInfo[pid];
        ISupportable supportable = pool.supportable;
        require(address(supportable) != address(0), "TheMaster: Use deposit func");
        UserInfo storage user = userInfo[pid][uint256(uint160(msg.sender))];
        updatePool(pool);
        uint256 _accRewardPerShare = pool.accRewardPerShare;
        uint256 _amount = user.amount;
        if (_amount > 0) {
            uint256 pending = ((_amount * _accRewardPerShare) / PRECISION) - user.rewardDebt;
            if (pending > 0) {
                (address to, uint256 amounts) = supportable.shareRewards(pending, msg.sender, pool.supportingRatio);
                if (amounts > 0) safeRewardTransfer(to, amounts);
                safeRewardTransfer(msg.sender, pending - amounts);
            }
        }
        if (amount > 0) {
            if (_amount == 0) {
                supportable.setSupportingTo(msg.sender, supportTo, amount);
            } else {
                supportable.changeSupportedPower(msg.sender, int256(amount));
            }
            IERC20(pool.addr).safeTransferFrom(msg.sender, address(this), amount);

            uint256 _mcPid = masterChefPid;
            if (_mcPid > 0 && pool.addr == address(lpToken)) {
                sushiRewardDebt[pid][msg.sender] = _depositModule(
                    _mcPid,
                    amount,
                    _amount,
                    sushiRewardDebt[pid][msg.sender]
                );
            }

            pool.supply += amount;
            _amount += amount;
            user.amount = _amount;
        }
        user.rewardDebt = (_amount * _accRewardPerShare) / PRECISION;
        emit Support(msg.sender, pid, amount);
    }

    function supportWithPermit(
        uint256 pid,
        uint256 amount,
        uint256 supportTo,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        IUniswapV2ERC20(poolInfo[pid].addr).permit(msg.sender, address(this), amount, deadline, v, r, s);
        support(pid, amount, supportTo);
    }

    function supportWithPermitMax(
        uint256 pid,
        uint256 amount,
        uint256 supportTo,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        IUniswapV2ERC20(poolInfo[pid].addr).permit(msg.sender, address(this), type(uint256).max, deadline, v, r, s);
        support(pid, amount, supportTo);
    }

    function desupport(uint256 pid, uint256 amount) external override {
        PoolInfo storage pool = poolInfo[pid];
        ISupportable supportable = pool.supportable;
        require(address(supportable) != address(0), "TheMaster: Use withdraw func");
        UserInfo storage user = userInfo[pid][uint256(uint160(msg.sender))];
        uint256 _amount = user.amount;
        require(_amount >= amount, "TheMaster: Insufficient amount");
        updatePool(pool);
        uint256 _accRewardPerShare = pool.accRewardPerShare;
        uint256 pending = ((_amount * _accRewardPerShare) / PRECISION) - user.rewardDebt;
        if (pending > 0) {
            (address to, uint256 amounts) = supportable.shareRewards(pending, msg.sender, pool.supportingRatio);
            if (amounts > 0) safeRewardTransfer(to, amounts);
            safeRewardTransfer(msg.sender, pending - amounts);
        }
        if (amount > 0) {
            supportable.changeSupportedPower(msg.sender, -int256(amount));

            uint256 _mcPid = masterChefPid;
            if (_mcPid > 0 && pool.addr == address(lpToken)) {
                sushiRewardDebt[pid][msg.sender] = _withdrawModule(
                    _mcPid,
                    amount,
                    _amount,
                    sushiRewardDebt[pid][msg.sender]
                );
            }

            pool.supply -= amount;
            _amount -= amount;
            user.amount = _amount;
            IERC20(pool.addr).safeTransfer(msg.sender, amount);
        }
        user.rewardDebt = (_amount * _accRewardPerShare) / PRECISION;
        emit Desupport(msg.sender, pid, amount);
    }

    function emergencyDesupport(uint256 pid) external override {
        PoolInfo storage pool = poolInfo[pid];
        ISupportable supportable = pool.supportable;
        require(address(supportable) != address(0), "TheMaster: Use emergencyWithdraw func");
        UserInfo storage user = userInfo[pid][uint256(uint160(msg.sender))];
        uint256 amounts = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.supply -= amounts;
        supportable.changeSupportedPower(msg.sender, -int256(amounts));

        uint256 _mcPid = masterChefPid;
        if (_mcPid > 0 && pool.addr == address(lpToken)) {
            sushiRewardDebt[pid][msg.sender] = _withdrawModule(
                _mcPid,
                amounts,
                amounts,
                sushiRewardDebt[pid][msg.sender]
            );
        }

        IERC20(pool.addr).safeTransfer(msg.sender, amounts);
        emit EmergencyDesupport(msg.sender, pid, amounts);
    }

    function mint(address to, uint256 amount) external override {
        require(mintableByAddr[msg.sender], "TheMaster: Called from un-mintable");
        maidCoin.mint(to, amount);
    }

    function safeRewardTransfer(address to, uint256 amount) internal {
        uint256 balance = maidCoin.balanceOf(address(this));
        if (amount > balance) {
            maidCoin.transfer(to, balance);
        } else {
            maidCoin.transfer(to, amount);
        }
    }

    function pendingSushiReward(uint256 pid) external view override returns (uint256) {
        return
            _pendingSushiReward(userInfo[pid][uint256(uint160(msg.sender))].amount, sushiRewardDebt[pid][msg.sender]);
    }

    function claimSushiReward(uint256 pid) public override {
        PoolInfo storage pool = poolInfo[pid];
        require(pool.addr == address(lpToken) && !pool.delegate, "TheMaster: Invalid pid");

        sushiRewardDebt[pid][msg.sender] = _claimSushiReward(
            userInfo[pid][uint256(uint160(msg.sender))].amount,
            sushiRewardDebt[pid][msg.sender]
        );
    }

    function claimAllReward(uint256 pid) public {
        PoolInfo storage pool = poolInfo[pid];
        require(pool.addr == address(lpToken) && !pool.delegate, "TheMaster: Invalid pid");

        UserInfo storage user = userInfo[pid][uint256(uint160(msg.sender))];
        uint256 amount = user.amount;
        require(amount > 0, "TheMaster: Nothing can be claimed");
        sushiRewardDebt[pid][msg.sender] = _claimSushiReward(amount, sushiRewardDebt[pid][msg.sender]);

        updatePool(pool);
        ISupportable supportable = pool.supportable;

        if (address(supportable) == address(0)) {
            uint256 _accRewardPerShare = pool.accRewardPerShare;
            uint256 pending = ((amount * _accRewardPerShare) / PRECISION) - user.rewardDebt;
            if (pending > 0) safeRewardTransfer(msg.sender, pending);
            user.rewardDebt = (amount * _accRewardPerShare) / PRECISION;
        } else {
            uint256 _accRewardPerShare = pool.accRewardPerShare;
            uint256 pending = ((amount * _accRewardPerShare) / PRECISION) - user.rewardDebt;
            if (pending > 0) {
                (address to, uint256 amounts) = supportable.shareRewards(pending, msg.sender, pool.supportingRatio);
                if (amounts > 0) safeRewardTransfer(to, amounts);
                safeRewardTransfer(msg.sender, pending - amounts);
            }
            user.rewardDebt = (amount * _accRewardPerShare) / PRECISION;
        }
    }
}
