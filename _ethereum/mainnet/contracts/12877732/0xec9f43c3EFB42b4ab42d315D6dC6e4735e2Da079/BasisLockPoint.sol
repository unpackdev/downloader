// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./console.sol";
import "./ERC20Burnable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./Operator.sol";

interface ILock {
    // ==== Lock ====
    struct LockPool {
        bool enable;
        uint256 recipK;
        bool siglePool;
        address store;
        uint256 pid;
        uint256 totalAmount;
        uint256 totalTime;
        uint256 totalUser;
    }
    struct UserLock {
        uint256 amount;
        uint256 end;
    }

    event CreateLock(
        address indexed _pool,
        address indexed _owner,
        uint256 _amount,
        uint256 _end
    );

    function calculatePoints(
        address _pool,
        uint256 _amount,
        uint256 _time
    ) external view returns (uint256);

    function createLock(
        address _owner,
        uint256 _amount,
        uint256 _end
    ) external;

    function createLockFromUser(
        address _pool,
        uint256 _amount,
        uint256 _end
    ) external;

    function canWithdraw(
        address _pool,
        address _owner,
        uint256 _amount
    ) external view returns (bool);

    function checkWithdraw(
        address _pool,
        address _owner,
        uint256 _amount
    ) external;

    // ==== Vote ====
    struct RewardPool {
        bool enable;
        uint256 totalVote;
    }

    event VoteTo(
        address indexed _rewardPool,
        address indexed _owner,
        uint256 _amount
    );
    event UnvoteFrom(
        address indexed _rewardPool,
        address indexed _owner,
        uint256 _amount
    );

    function voteSupply(address _rewardPool) external view returns (uint256);

    function voteBalanceOf(address _rewardPool, address _owner)
        external
        view
        returns (uint256);

    function voteTo(address _rewardPool, uint256 _amount) external;

    function unvoteFrom(address _rewardPool, uint256 _amount) external;

    // ==== Manager ====
    event SetLockPool(
        address indexed _pool,
        bool _enable,
        uint256 _recipK,
        bool _siglePool,
        address indexed _store,
        uint256 _pid
    );

    event SetRewardPool(address indexed _pool, bool _enable);
}

interface ISingleStore {
    function balanceOf(address _owner) external view returns (uint256);
}

interface IMultiStore {
    function balanceOf(uint256 _pid, address _owner)
        external
        view
        returns (uint256);
}

interface IRewardPool {
    function onVoteChange(address _owner) external;
}

contract BasisLockPoint is ERC20Burnable, ILock, Operator {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // ==== Lock ====
    // pool => LockPool
    mapping(address => LockPool) public lockPools;
    // pool => user => UserLock
    mapping(address => mapping(address => UserLock)) public userLock;

    uint256 public MIN_LOCK_TIME = 7 days;
    uint256 public MAX_LOCK_TIME = 1460 days;
    uint256 public MIN_LOCK_AMOUNT = 1e17;

    // ==== Vote ====
    // pool => RewardPool
    mapping(address => RewardPool) public rewardPools;
    // pool => user => amount
    mapping(address => mapping(address => uint256)) public userVote;

    // ==== Manager ====
    uint256 public autoVotePercent = 100;
    bool public pauseTransfer = true;
    uint256 public fee = 0;
    bool migrate = false;

    constructor() ERC20('Basis Lock Point', 'BLP') {
        _setupDecimals(2);
    }

    modifier checkMigrate {
        require(!migrate, 'migrate pause!');
        _;
    }

    // ==== Lock ====
    modifier checkFromLockPool {
        require(lockPools[_msgSender()].enable, 'BLP: not from lock pool');
        _;
    }

    function calculatePoints(
        address _pool,
        uint256 _amount,
        uint256 _time
    ) public view override returns (uint256) {
        return _amount.mul(_time).div(lockPools[_pool].recipK);
    }

    function createLock(
        address _owner,
        uint256 _amount,
        uint256 _end
    ) external override checkFromLockPool {
        update(_msgSender(), _owner);
        _createLock(_msgSender(), _owner, _amount, _end);
    }

    function createLockFromUser(
        address _pool,
        uint256 _amount,
        uint256 _end
    ) external override {
        update(_pool, _msgSender());
        _createLock(_pool, _msgSender(), _amount, _end);
    }

    function _getStoreBalance(address _pool, address _owner)
        internal
        view
        returns (uint256)
    {
        LockPool memory pool = lockPools[_pool];
        if (pool.siglePool) {
            return ISingleStore(pool.store).balanceOf(_owner);
        } else {
            return IMultiStore(pool.store).balanceOf(pool.pid, _owner);
        }
    }

    function getUserLock(address _pool, address _owner)
        public
        view
        returns (UserLock memory)
    {
        UserLock memory user = userLock[_pool][_owner];
        if (user.end <= block.timestamp) {
            user.amount = 0;
            user.end = 0;
        }
        return user;
    }

    function preCreateLock(
        address _pool,
        address _owner,
        uint256 _amount,
        uint256 _end
    ) public view returns (uint256) {
        require(
            block.timestamp < _end &&
                _end.sub(block.timestamp) >= MIN_LOCK_TIME,
            'BLP: cannt short than MIN_LOCK_TIME'
        );
        require(
            _end.sub(block.timestamp) <= MAX_LOCK_TIME,
            'BLP: cannt long than MAX_LOCK_TIME'
        );
        UserLock memory user = getUserLock(_pool, _owner);
        require(
            _amount >= MIN_LOCK_AMOUNT || (user.amount > 0 && _amount == 0),
            'BLP: cannt less than MIN_LOCK_AMOUNT'
        );
        require(_end >= user.end, 'BLP: cannt reduce time');

        uint256 pointAmount = calculatePoints(
            _pool,
            user.amount,
            _end.sub(user.end)
        ).add(calculatePoints(_pool, _amount, _end.sub(block.timestamp)));

        return pointAmount;
    }

    function _createLock(
        address _pool,
        address _owner,
        uint256 _amount,
        uint256 _end
    ) internal checkMigrate {
        uint256 pointAmount = preCreateLock(_pool, _owner, _amount, _end);
        UserLock memory user = getUserLock(_pool, _owner);
        uint256 storeBalance = _getStoreBalance(_pool, _owner);

        require(
            _amount <= storeBalance.sub(user.amount),
            'BLP: lock amount too much'
        );

        // write
        LockPool memory pool = lockPools[_pool];
        if (pointAmount > 0) {
            _mint(_owner, pointAmount);
        }

        pool.totalAmount = pool.totalAmount.add(_amount);
        pool.totalTime = pool.totalTime.add(_end.sub(user.end));
        if (user.end == 0) pool.totalUser += 1; //new user
        lockPools[_pool] = pool;

        user.amount = user.amount.add(_amount);
        user.end = _end;
        userLock[_pool][_owner] = user;

        emit CreateLock(_pool, _owner, _amount, _end);

        // auto vote
        if (
            rewardPools[_pool].enable && autoVotePercent > 0 && pointAmount > 0
        ) {
            _voteTo(
                _owner,
                _pool,
                pointAmount.mul(autoVotePercent).div(100),
                false
            );
        }
    }

    function canWithdraw(
        address _pool,
        address _owner,
        uint256 _amount
    ) public view override returns (bool) {
        uint256 storeBalance = _getStoreBalance(_pool, _owner);
        UserLock memory user = getUserLock(_pool, _owner);
        return _amount <= storeBalance.sub(user.amount);
    }

    function update(address _pool, address _owner)
        public
        returns (UserLock memory)
    {
        UserLock memory user = userLock[_pool][_owner];
        if (user.end <= block.timestamp && user.end > 0) {
            LockPool memory pool = lockPools[_pool];
            pool.totalAmount = pool.totalAmount.sub(user.amount);
            pool.totalTime = pool.totalTime.sub(user.end);
            pool.totalUser = pool.totalUser.sub(1);
            lockPools[_pool] = pool;

            user.amount = 0;
            user.end = 0;
            userLock[_pool][_owner] = user;
        }

        return user;
    }

    function checkWithdraw(
        address _pool,
        address _owner,
        uint256 _amount
    ) external override {
        uint256 storeBalance = _getStoreBalance(_pool, _owner);
        UserLock memory user = update(_pool, _owner);
        require(
            _amount <= storeBalance.sub(user.amount),
            'BLP: cannt withdraw lock limit'
        );
    }

    // ==== Vote ====
    function voteSupply(address _rewardPool)
        external
        view
        override
        returns (uint256)
    {
        RewardPool memory pool = rewardPools[_rewardPool];
        return pool.totalVote;
    }

    function voteBalanceOf(address _rewardPool, address _owner)
        external
        view
        override
        returns (uint256)
    {
        return userVote[_rewardPool][_owner];
    }

    function _voteTo(
        address _owner,
        address _rewardPool,
        uint256 _amount,
        bool callback
    ) internal {
        RewardPool memory pool = rewardPools[_rewardPool];
        require(pool.enable, 'BLP: not in reward pools');
        _transfer(_owner, address(this), _amount);
        userVote[_rewardPool][_owner] = userVote[_rewardPool][_owner].add(
            _amount
        );
        pool.totalVote = pool.totalVote.add(_amount);
        rewardPools[_rewardPool] = pool;
        if (callback) IRewardPool(_rewardPool).onVoteChange(_owner);
        emit VoteTo(_rewardPool, _owner, _amount);
    }

    function voteTo(address _rewardPool, uint256 _amount)
        public
        override
        checkMigrate
    {
        _voteTo(_msgSender(), _rewardPool, _amount, true);
    }

    function unvoteFrom(address _rewardPool, uint256 _amount)
        public
        override
        checkMigrate
    {
        RewardPool memory pool = rewardPools[_rewardPool];
        require(pool.enable, 'BLP: not in reward pools');
        address _owner = _msgSender();
        userVote[_rewardPool][_owner] = userVote[_rewardPool][_owner].sub(
            _amount
        );
        pool.totalVote = pool.totalVote.sub(_amount);
        rewardPools[_rewardPool] = pool;
        IRewardPool(_rewardPool).onVoteChange(_owner);

        _transfer(address(this), _owner, _amount);

        emit UnvoteFrom(_rewardPool, _owner, _amount);
    }

    // ==== Manager ====
    function setLockPool(
        address _pool,
        bool _enable,
        uint256 _recipK,
        bool _siglePool,
        address _store,
        uint256 _pid
    ) external onlyOwner {
        LockPool memory pool = lockPools[_pool];
        pool.enable = _enable;
        pool.siglePool = _siglePool;
        pool.recipK = _recipK;
        pool.store = _store;
        pool.pid = _pid;
        lockPools[_pool] = pool;
        emit SetLockPool(_pool, _enable, _recipK, _siglePool, _store, _pid);
    }

    function setRewardPool(address _pool, bool _enable) external onlyOwner {
        RewardPool memory pool = rewardPools[_pool];
        pool.enable = true;
        rewardPools[_pool] = pool;
        emit SetRewardPool(_pool, _enable);
    }

    function setMigrate(bool _migrate) external onlyOwner {
        migrate = _migrate;
    }

    function setAutoVotePercent(uint8 _autoVotePercent) external onlyOwner {
        autoVotePercent = _autoVotePercent;
    }

    // ==== Token ====

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (pauseTransfer) {
            require(
                sender == address(this) || recipient == address(this),
                'BLP: pause transfer'
            );
            super._transfer(sender, recipient, amount);
        } else {
            if (sender == address(this) || recipient == address(this)) {
                super._transfer(sender, recipient, amount);
            } else {
                uint256 burnAmount = amount.mul(fee).div(10000);
                if (burnAmount > 0) _burn(sender, burnAmount);
                super._transfer(sender, recipient, amount.sub(burnAmount));
            }
        }
    }

    function setDecimals(uint8 _decimals) external onlyOwner {
        _setupDecimals(_decimals);
    }

    function setTokenConfig(bool _pauseTransfer, uint256 _fee)
        external
        onlyOwner
    {
        pauseTransfer = _pauseTransfer;
        fee = _fee;
    }
}
