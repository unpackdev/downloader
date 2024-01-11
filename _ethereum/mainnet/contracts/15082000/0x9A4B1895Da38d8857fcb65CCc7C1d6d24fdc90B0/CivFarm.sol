// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./ERC20Burnable.sol";
import "./ICivRT.sol";

/// @title  Civ FT Farm
/// @author Lorenz-Ren
/// @notice This contract creates a simple yield farming dApp that rewards users for
///         locking up their LP Tokens with an ERC20 represent xToken
/// @dev  The calculateYieldTotal function
///      takes care of current yield calculations for frontend data.
///      At any time user can withdraw yield rewards. This is executed also during new staking positions and withdraw of LPTokens
///      Ownership of the StoneToken contract should be transferred to the xCIVFarm contract after deployment


contract CivFarm is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has locked in CivFarm
        uint256 rewardDebt; // user reward debt. See explanation below.
        //
        // At any point in time, the amount of reward tokens (0NE)
        // entitled to a user but pending to be distributed is:
        //
        //   pending reward = (user.amount  * accTokenPerShare) - user.rewardDebt              <<<< Wallet Earn (WE)
        //
        // Whenever an user deposits or withdraws LP tokens to the pool, here's what happens:
        //   1. The pool's `accTokenPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to her/his address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; 			// Address of LP token contract.
        uint256 allocPoint; 		// TP logic>>>> pool's weight: how many allocation points assigned to this pool. 0NE to distribute per block.
        uint256 lastRewardBlock; 	// Last block number that 0NE distribution occurs.
        uint256 accTokensPerShare; // Accumulated 0NE per share, times 1e18. See below.
        ICivRT representToken; 		// Represent Token contract, for us xSomething
    }

    // The Represent token
    ICivRT public representToken;
    // The reward Token
    IERC20 public stone;
    // xTokens tokens rewards per block. FR logic, Farming Rate logic
    uint256 public tokensPerBlock;
    // Bonus multiplier, booster. could be modified based on DAO voting
    uint256 public BONUS_MULTIPLIER = 1;

    // pools structure with Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.   TP logic, TPpool 1 + TPpool 2 + ... + TPpool z = Total TPS
    uint256 public totalAllocPoint = 104;
    // The block number when farm starts.
    uint256 public startBlock;

    uint256 public immutable MAX_UINT = 2**256-1;

    //events triggered
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event YieldWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event AddPool(
        uint256 indexed pid,
        uint256 indexed allocPoint,
        IERC20 lpToken,
        IERC20 representToken
    );
    event SetPool(
        uint256 indexed pid,
        uint256 indexed prevAllocPoint,
        uint256 indexed newAllocPoint
    );
    event SetTotalAllocPoint(
        uint256 indexed prevTotalAllocPoint,
        uint256 indexed newTotalAllocPoint
    );
    event SetTokensPerBlock(
        uint256 indexed prevTokensPerBlock,
        uint256 indexed newTokensPerBlock
    );

    constructor(
        IERC20 _lptoken,
        IERC20 _stone,
        ICivRT _xCIV
    ) public {
        representToken = _xCIV;
        stone = _stone;
        tokensPerBlock = 1000000;
        startBlock = block.number;

        totalAllocPoint = 104; //our total TP considering requirements

        // staking pool
        poolInfo.push(
            PoolInfo({
                lpToken: _lptoken,
                allocPoint: 10, //pool id=0, stake CIV --> reward 0NE. TP = 10 / 104, FR = 1M/block
                lastRewardBlock: startBlock,
                accTokensPerShare: 0,
                representToken: _xCIV
            })
        );
        emit AddPool(poolInfo.length - 1, 10, _lptoken, _xCIV);
    }

    //update bonus multiplier for early farmers. Can only be called by the owner.
    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    //update Farming Rate, reward tokensdistributed per block. Can only be called by the owner.
    function updateRate(uint256 rateNumber) public onlyOwner {
        emit SetTokensPerBlock(tokensPerBlock, rateNumber);
        tokensPerBlock = rateNumber;
    }

    //update Farm totalAllocPoints. Can only be called by the owner.
    function setTotalAllocPoint(uint256 _totalAllocPoint) public onlyOwner {
        emit SetTotalAllocPoint(totalAllocPoint, _totalAllocPoint);
        totalAllocPoint = _totalAllocPoint;
    }

    //number of pools.
    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function addPool(
        uint256 _allocPoint,
        IERC20 _lpToken,
        ICivRT _representToken
    ) public onlyOwner {
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;

        //adding a new LP
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken, //LP Token
                allocPoint: _allocPoint, //TP of the new pool (e.g. pool 1, stake 0NE -> 0NE, TP=10 -> allocPoint = 10)
                lastRewardBlock: lastRewardBlock,
                accTokensPerShare: 0, //init = always 0
                representToken: _representToken
            })
        );
        emit AddPool(
            poolInfo.length - 1,
            _allocPoint,
            _lpToken,
            _representToken
        );
    }

    // Update the given pool's reward token allocation point. Can only be called by the owner.
    function setPool(uint256 _pid, uint256 _allocPoint) public onlyOwner {
        require(poolInfo.length > _pid, "Pool does not exist");
        emit SetPool(_pid, poolInfo[_pid].allocPoint, _allocPoint);

        poolInfo[_pid].allocPoint = _allocPoint;
        if (poolInfo[_pid].allocPoint != _allocPoint) {
            updatePool(_pid);
        }
    }

    // Return reward multiplier over the given _from to _to block considering possible MULTIPLIER for EARLY FARMERS/STAKERS
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        return (_to - _from) * (BONUS_MULTIPLIER);
    }

    // Returns LP tokens provided by user on a given pool
    function getUserLP(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        UserInfo memory user = userInfo[_pid][_user];
        return user.amount;
    }

    // View function to see pending Tokens on frontend.
    function pendingTokens(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accTokensPerShare = pool.accTokensPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 tokensReward = (multiplier *
                (tokensPerBlock) *
                (pool.allocPoint) *
                (10**18)) / (totalAllocPoint);
            accTokensPerShare =
                accTokensPerShare +
                ((tokensReward * (10**18)) / (lpSupply));
        }
        return
            (user.amount * (accTokensPerShare)) / (10**18) - (user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokensReward = (multiplier *
            (tokensPerBlock) *
            (pool.allocPoint) *
            (10**18)) / (totalAllocPoint);

        pool.accTokensPerShare =
            pool.accTokensPerShare +
            ((tokensReward * (10**18)) / (lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to CIV Farm for xTokens allocation and 0NE rewards
    function deposit(uint256 _pid, uint256 _amount) public whenNotPaused nonReentrant {
        require(_pid != 0, "deposit CIV Tokens by staking, selecting the right pool");
        require(poolLength() > _pid, "Can't find pool");
        require(_amount <= uint256(MAX_UINT), "Wrong amount");

        
        UserInfo storage user = userInfo[_pid][_msgSender()];

        updatePool(_pid);

        PoolInfo memory pool = poolInfo[_pid];

        uint256 pending = (user.amount * (pool.accTokensPerShare)) /
            (10**18) -
            (user.rewardDebt);
        user.rewardDebt = ((user.amount + _amount) * (pool.accTokensPerShare)) / (10**18);

        if (pending > 0) {
            stone.safeTransfer(_msgSender(), pending);
            emit YieldWithdraw(_msgSender(), _pid, pending);
        }

        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(_msgSender(), address(this), _amount);
            user.amount += _amount;
            pool.representToken.mint(_msgSender(), _amount);
        }
        
        emit Deposit(_msgSender(), _pid, _amount);
    }

    // Withdraw LP tokens from CIV Farm
    function withdraw(uint256 _pid, uint256 _amount) public whenNotPaused nonReentrant {
        require(_pid != 0, "withdraw CIV tokens by unstaking");
        require(poolLength() > _pid, "Can't find pool");
        require(_amount <= uint256(MAX_UINT), "Wrong amount");

       
        UserInfo storage user = userInfo[_pid][_msgSender()];
        require(user.amount >= _amount, "amount exceeds user's balance");

        updatePool(_pid);

        PoolInfo memory pool = poolInfo[_pid];

        uint256 pending = (user.amount * (pool.accTokensPerShare)) /
            (10**18) -
            (user.rewardDebt);

        user.rewardDebt = ((user.amount - _amount) * (pool.accTokensPerShare)) / (10**18);

        if (pending > 0) {
            stone.safeTransfer(_msgSender(), pending);
            emit YieldWithdraw(_msgSender(), _pid, pending);
        }
        if (_amount > 0) {
            pool.representToken.burnFrom(_msgSender(), _amount);
            user.amount -= _amount;
            pool.lpToken.safeTransfer(address(_msgSender()), _amount);
        }
        emit Withdraw(_msgSender(), _pid, _amount);
    }

    // Stake CIVS tokens to CIV Farm. CIV ->xCIV, 0NE as reward
    function enterStaking(uint256 _amount) public whenNotPaused nonReentrant {
        
        UserInfo storage user = userInfo[0][_msgSender()];
        require(_amount <= uint256(MAX_UINT), "Wrong amount");

        updatePool(0);

        PoolInfo memory pool = poolInfo[0];

        uint256 pending = (user.amount * (pool.accTokensPerShare)) /
            (10**18) -
            (user.rewardDebt);

        user.rewardDebt = ((user.amount + _amount) * (pool.accTokensPerShare)) / (10**18);

        if (pending > 0) {
            stone.safeTransfer(_msgSender(), pending);
            emit YieldWithdraw(_msgSender(), 0, pending);
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(_msgSender()),
                address(this),
                _amount
            );
            user.amount += _amount;
        }
        
        pool.representToken.mint(_msgSender(), _amount);
        emit Deposit(_msgSender(), 0, _amount);
    }

    // Withdraw LP tokens from STAKING.
    function leaveStaking(uint256 _amount) public whenNotPaused nonReentrant {
        
        UserInfo storage user = userInfo[0][_msgSender()];
        require(_amount <= uint256(MAX_UINT), "Wrong amount");

        require(
            user.amount >= _amount,
            "amount exceeds user's balance"
        );
        updatePool(0);

        PoolInfo memory pool = poolInfo[0];

        uint256 pending = (user.amount * (pool.accTokensPerShare)) /
            (10**18) -
            (user.rewardDebt);
        user.rewardDebt = ((user.amount - _amount) * (pool.accTokensPerShare)) / (10**18);
        
        if (pending > 0) {
            stone.safeTransfer(_msgSender(), pending);
            emit YieldWithdraw(_msgSender(), 0, pending);
        }
        if (_amount > 0) {
            user.amount -= _amount;
            pool.lpToken.safeTransfer(address(_msgSender()), _amount);
        }

        pool.representToken.burnFrom(
            _msgSender(),
            _amount
        );
        emit Withdraw(_msgSender(), 0, _amount);
    }

    /// @notice Transfers accrued 0NE yield to the user
    /// @dev The if conditional statement checks for a stored xToken balance.

    function withdrawYield(uint256 _pid) public whenNotPaused{
        
        UserInfo storage user = userInfo[_pid][_msgSender()];

        updatePool(_pid);

        PoolInfo memory pool = poolInfo[_pid];

        uint256 toTransfer = (user.amount * (pool.accTokensPerShare)) /
            (10**18) -
            (user.rewardDebt);
        user.rewardDebt = (user.amount * (pool.accTokensPerShare)) / (10**18);

        require(toTransfer > 0, "Nothing to withdraw Sir");

        stone.safeTransfer(_msgSender(), toTransfer);

        emit YieldWithdraw(_msgSender(), _pid, toTransfer);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public whenNotPaused nonReentrant {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];

        pool.representToken.burnFrom(
            _msgSender(),
            user.amount
        );

        pool.lpToken.safeTransfer(address(_msgSender()), user.amount);

        user.amount = 0;
        user.rewardDebt = 0;

        emit EmergencyWithdraw(_msgSender(), _pid, user.amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /* Just in case anyone sends tokens by accident to this contract */

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "CivFarm");
    }

    function withdrawETH() external payable onlyOwner {
        safeTransferETH(_msgSender(), address(this).balance);
    }

    function withdrawERC20(IERC20 _tokenContract) external onlyOwner {
        _tokenContract.safeTransfer(
            _msgSender(),
            _tokenContract.balanceOf(address(this))
        );
    }

    /**
     * @dev allow the contract to receive ETH
     * without payable fallback and receive, it would fail
     */
    fallback() external payable {}

    receive() external payable {}
}