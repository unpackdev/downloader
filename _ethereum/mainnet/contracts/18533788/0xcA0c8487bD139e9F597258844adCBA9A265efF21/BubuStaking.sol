/*

88                        88                           ,adba,              88                        88
88                        88                           8I  I8              88                        88
88                        88                           "8bdP'              88                        88
88,dPPYba,   88       88  88,dPPYba,   88       88    ,d8"8b  88   ,adPPYb,88  88       88   ,adPPYb,88  88       88
88P'    "8a  88       88  88P'    "8a  88       88  .dP'   Yb,8I  a8"    `Y88  88       88  a8"    `Y88  88       88
88       d8  88       88  88       d8  88       88  8P      888'  8b       88  88       88  8b       88  88       88
88b,   ,a8"  "8a,   ,a88  88b,   ,a8"  "8a,   ,a88  8b,   ,dP8b   "8a,   ,d88  "8a,   ,a88  "8a,   ,d88  "8a,   ,a88
8Y"Ybbd8"'    `"YbbdP'Y8  8Y"Ybbd8"'    `"YbbdP'Y8  `Y8888P"  Yb   `"8bbdP"Y8   `"YbbdP'Y8   `"8bbdP"Y8   `"YbbdP'Y8

https://t.me/bubududuerc
https://twitter.com/BUBU_erc
https://twitter.com/DUDU_erc
https://www.bubududu.xyz/

*/
// SPDX-License-Identifier: Unlicensed

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/prod/Staking.sol

/*

88                        88                           ,adba,              88                        88
88                        88                           8I  I8              88                        88
88                        88                           "8bdP'              88                        88
88,dPPYba,   88       88  88,dPPYba,   88       88    ,d8"8b  88   ,adPPYb,88  88       88   ,adPPYb,88  88       88
88P'    "8a  88       88  88P'    "8a  88       88  .dP'   Yb,8I  a8"    `Y88  88       88  a8"    `Y88  88       88
88       d8  88       88  88       d8  88       88  8P      888'  8b       88  88       88  8b       88  88       88
88b,   ,a8"  "8a,   ,a88  88b,   ,a8"  "8a,   ,a88  8b,   ,dP8b   "8a,   ,d88  "8a,   ,a88  "8a,   ,d88  "8a,   ,a88
8Y"Ybbd8"'    `"YbbdP'Y8  8Y"Ybbd8"'    `"YbbdP'Y8  `Y8888P"  Yb   `"8bbdP"Y8   `"YbbdP'Y8   `"8bbdP"Y8   `"YbbdP'Y8

https://t.me/bubududuerc
https://twitter.com/BUBU_erc
https://twitter.com/DUDU_erc
https://www.bubududu.xyz/

*/

pragma solidity ^0.8;




contract BubuStaking is ReentrancyGuard, Ownable {
    IERC20 public immutable stakingToken;
    IERC20 public immutable duduToken;

    // DUDU
    uint public rewardRateDudu;
    uint public rewardPerDuduStored; // Sum of (reward rate * dt * 1e18 / total supply)
    mapping(address => uint) public userRewardPerDuduPaid; // User address => rewardPerTokenStored
    mapping(address => uint) public rewardsDudu; // User address => rewards to be claimed

    // ETH
    uint public rewardRateEth;
    uint public rewardPerEthStored;
    mapping(address => uint) public userRewardPerEthPaid;
    mapping(address => uint) public rewardsEth;

    // GENERAL
    uint public totalStaked; // Total staked
    uint public totalStakers = 0;
    uint public duration; // Duration of rewards to be paid out (in seconds)
    uint public finishAt; // Timestamp of when the rewards finish
    uint public updatedAt; // Minimum of last updated time and reward finish time
    bool public stakingEnabled = true;

    // POOLS
    uint public currentPoolDudu = 0;
    uint public currentPoolEth = 0;
    uint public currentPoolDuduMinusClaimedDudu = 0;
    uint public currentPoolEthMinusClaimedEth = 0;

    // BATCH
    uint256 public lockDuration = 30 days;
    mapping(uint256 => bool) public stakedTokensLocked;
    mapping(uint256 => uint256) public stakingLockPeriod;
    mapping(uint256 => Batch) batchLookup;
    mapping(address => Batch[]) private batchesByUser;
    uint256 batchIndex = 0;
    struct Batch {
        address user;
        uint256 stakedTimestamp;
        uint256 unlockedAtTimestamp;
        uint256 stakedTokensAmount;
    }
    bool public emergencyWithdrawEnabled = false;

    // USER
    mapping(address => uint) public userTotalStaked; // User address => staked amount
    mapping(address => bool) private approvedOwners;

    // EVENTS
    event EthDeposited(address indexed user, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 batchIndex);
    event RevShareClaimed(
        address indexed user,
        uint256 duduAmount,
        uint256 ethAmount
    );
    event LockDurationUpdated(uint256 newLockDuration);
    event RewardsSet(uint256 duduAmount, uint256 ethAmount, uint256 duration);
    event DuduDeposited(address indexed user, uint256 amount);
    event EthRescued(uint256 amount);
    event DuduRescued(uint256 amount);
    event EmergencyWithdrawToggled(bool status);
    event ERC20Rescued(
        address indexed token,
        address indexed recipient,
        uint256 amount
    );
    event StakingToggled(bool status);
    event Received(uint256 amount);
    event OwnerApproved(address indexed approvedOwner);
    event OwnerRevoked(address indexed revokedOwner);

    constructor(address _stakingToken, address _rewardToken) {
        stakingToken = IERC20(_stakingToken);
        duduToken = IERC20(_rewardToken);
    }

    receive() external payable {
        emit Received(msg.value);
    }


    modifier updateReward(address _account) {
        rewardPerDuduStored = rewardPerDuduToken();
        rewardPerEthStored = rewardPerEthToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewardsDudu[_account] = earnedDudu(_account);
            rewardsEth[_account] = earnedEth(_account);
            userRewardPerDuduPaid[_account] = rewardPerDuduStored;
            userRewardPerEthPaid[_account] = rewardPerEthStored;
        }

        _;
    }

      // ACCESS CONTROL--------------------------------------------------------------
  modifier onlyApprovedOwner() {
      require(msg.sender == owner() || isApprovedOwner(msg.sender), "Not an approved owner");
      _;
  }

  function approveOwner(address _approvedOwner) external onlyApprovedOwner {
    approvedOwners[_approvedOwner] = true;
    emit OwnerApproved(_approvedOwner);
  }

  function revokeOwner(address _revokedOwner) external onlyApprovedOwner {
    approvedOwners[_revokedOwner] = false;
    emit OwnerRevoked(_revokedOwner);
  }

  function isApprovedOwner(address _address) public view returns(bool) {
    return approvedOwners[_address];
  }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerDuduToken() public view returns (uint) {
        if (totalStaked == 0) {
            return rewardPerDuduStored;
        }

        return
            rewardPerDuduStored +
            (rewardRateDudu * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalStaked;
    }

    function rewardPerEthToken() public view returns (uint) {
        if (totalStaked == 0) {
            return rewardPerEthStored;
        }

        return
            rewardPerEthStored +
            (rewardRateEth * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalStaked;
    }

    function stake(
        uint _amount
    ) external updateReward(msg.sender) nonReentrant {
        require(stakingEnabled, "Staking is currently disabled");
        require(_amount > 0, "amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        userTotalStaked[msg.sender] += _amount;
        totalStaked += _amount;
        addBatch(msg.sender, _amount);
        emit Staked(msg.sender, _amount);
    }

    function withdraw(
        uint256 _batchIndex
    ) external updateReward(msg.sender) nonReentrant {
        Batch memory batch = getBatchesForUser(msg.sender)[_batchIndex];
        uint256 _amount = batch.stakedTokensAmount;

        require(
            block.timestamp > batch.unlockedAtTimestamp ||
                emergencyWithdrawEnabled,
            "Cannot unstake, tokens are locked."
        );

        require(_amount > 0, "amount = 0");
        userTotalStaked[msg.sender] -= _amount;
        totalStaked -= _amount;
        removeBatchFromUser(msg.sender, _batchIndex);
        stakingToken.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount, _batchIndex);
    }

    function addBatch(address _account, uint256 stakedTokensAmount) private {
        Batch memory newBatch = Batch({
            user: _account,
            stakedTimestamp: block.timestamp,
            unlockedAtTimestamp: block.timestamp + lockDuration,
            stakedTokensAmount: stakedTokensAmount
        });

        batchLookup[batchIndex] = newBatch;

        if (batchesByUser[_account].length == 0) {
            totalStakers += 1;
        }

        batchesByUser[_account].push(newBatch);
        batchIndex++;
    }

    function getBatchesForUser(
        address _addr
    ) public view returns (Batch[] memory) {
        return batchesByUser[_addr];
    }

    function earnedDudu(address _account) public view returns (uint) {
        return
            ((userTotalStaked[_account] *
                (rewardPerDuduToken() - userRewardPerDuduPaid[_account])) /
                1e18) + rewardsDudu[_account];
    }

    function earnedEth(address _account) public view returns (uint) {
        return
            ((userTotalStaked[_account] *
                (rewardPerEthToken() - userRewardPerEthPaid[_account])) /
                1e18) + rewardsEth[_account];
    }

    function claimRevShare() external updateReward(msg.sender) nonReentrant {
        uint rewardDudu = rewardsDudu[msg.sender];
        uint rewardEth = rewardsEth[msg.sender];

        if (rewardDudu > 0) {
            rewardsDudu[msg.sender] = 0;
            duduToken.transfer(msg.sender, rewardDudu);
            currentPoolDuduMinusClaimedDudu -= rewardDudu;
        }

        if (rewardEth > 0) {
            rewardsEth[msg.sender] = 0;
            payable(msg.sender).transfer(rewardEth);
            currentPoolEthMinusClaimedEth -= rewardEth;
        }
        emit RevShareClaimed(msg.sender, rewardDudu, rewardEth);
    }

    function setLockDuration(uint _seconds) external onlyApprovedOwner {
        lockDuration = _seconds;
        emit LockDurationUpdated(_seconds);
    }

    function setRewards(
        uint _amountDudu,
        uint _amountEth,
        uint _duration
    ) external onlyApprovedOwner updateReward(address(0)) {
        require(_duration > 0, "Duration should be positive");

        // If the previous rewards haven't finished, consider the remaining rewards too.
        if (block.timestamp < finishAt) {
            uint remainingDuduRewards = (finishAt - block.timestamp) *
                rewardRateDudu;
            rewardRateDudu = (_amountDudu + remainingDuduRewards) / _duration;

            uint remainingEthRewards = (finishAt - block.timestamp) *
                rewardRateEth;
            rewardRateEth = (_amountEth + remainingEthRewards) / _duration;
        } else {
            rewardRateDudu =
                (_amountDudu - currentPoolDuduMinusClaimedDudu) /
                _duration;
            rewardRateEth =
                (_amountEth - currentPoolEthMinusClaimedEth) /
                _duration;
        }

        require(
            rewardRateDudu <= duduToken.balanceOf(address(this)) / _duration,
            "Insufficient rewards in the contract"
        );

        require(
            rewardRateEth <= address(this).balance / _duration,
            "Insufficient ETH in the contract"
        );

        require(
            _amountDudu >= currentPoolDuduMinusClaimedDudu,
            "DUDU amount less than unpaid DUDU rewards"
        );
        require(
            _amountEth >= currentPoolEthMinusClaimedEth,
            "ETH amount less than unpaid ETH rewards"
        );

        currentPoolDudu = _amountDudu;
        currentPoolEth = _amountEth;

        currentPoolDuduMinusClaimedDudu = _amountDudu;
        currentPoolEthMinusClaimedEth = _amountEth;

        duration = _duration;
        finishAt = block.timestamp + _duration;
        updatedAt = block.timestamp;

        emit RewardsSet(_amountDudu, _amountEth, _duration);
    }

    function removeBatchFromUser(
        address _account,
        uint256 _batchIndex
    ) private {
        require(
            _batchIndex < batchesByUser[_account].length,
            "Index out of bounds"
        );

        // Move the last item to the location we want to delete
        batchesByUser[_account][_batchIndex] = batchesByUser[_account][
            batchesByUser[_account].length - 1
        ];

        // Remove the last item
        batchesByUser[_account].pop();

        if (batchesByUser[_account].length == 0) {
            totalStakers -= 1;
        }
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    function projectedDuduRewardForUser(
        address _account,
        uint _duration
    ) public view returns (uint) {
        uint dailyTotalReward = rewardRateDudu * _duration;
        return (dailyTotalReward * userTotalStaked[_account]) / totalStaked;
    }

    function projectedEthRewardForUser(
        address _account,
        uint _duration
    ) public view returns (uint) {
        uint dailyTotalReward = rewardRateEth * _duration;
        return (dailyTotalReward * userTotalStaked[_account]) / totalStaked;
    }

    function projectedDailyDuduRewardForAmount(
        uint _amount
    ) public view returns (uint) {
        uint dailyTotalReward = rewardRateDudu * 86400;
        return (dailyTotalReward * _amount) / totalStaked;
    }

    function projectedDailyDuduRewardForEth(
        uint _amount
    ) public view returns (uint) {
        uint dailyTotalReward = rewardRateEth * 86400;
        return (dailyTotalReward * _amount) / totalStaked;
    }

    function depositDudu(uint256 amount) external {
        duduToken.transferFrom(msg.sender, address(this), amount);
        emit DuduDeposited(msg.sender, amount);
    }

    function depositEth() external payable {
        require(msg.value > 0, "Cannot deposit 0 ETH");
        emit EthDeposited(msg.sender, msg.value);
    }

    function rescueEth(uint256 amount) external onlyApprovedOwner {
        require(
            amount <= address(this).balance,
            "Amount exceeds contract ETH balance"
        );

        payable(msg.sender).transfer(amount);
        emit EthRescued(amount);
    }

    function rescueDudu(uint256 amount) external onlyApprovedOwner {
        uint256 contractBalance = duduToken.balanceOf(address(this));
        require(amount <= contractBalance, "Amount exceeds contract balance");
        duduToken.transfer(msg.sender, amount);
        emit DuduRescued(amount);
    }

    function rescueERC20(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external onlyApprovedOwner {
        require(amount > 0, "Amount should be positive");

        if (!emergencyWithdrawEnabled) {
            require(
                tokenAddress != address(stakingToken),
                "Cannot rescue stakingToken"
            );
            require(
                tokenAddress != address(duduToken),
                "Cannot rescue duduToken"
            );
        }

        IERC20(tokenAddress).transfer(recipient, amount);

        emit ERC20Rescued(tokenAddress, recipient, amount);
    }

    function toggleEmergencyWithdraw() external onlyApprovedOwner {
        emergencyWithdrawEnabled = !emergencyWithdrawEnabled;
        emit EmergencyWithdrawToggled(emergencyWithdrawEnabled);
    }

    function getUnlockedContractFunds()
        external
        view
        returns (uint256 duduBalance, uint256 ethBalance)
    {
        uint256 totalDuduInPool = currentPoolDuduMinusClaimedDudu;
        uint256 totalEthInPool = currentPoolEthMinusClaimedEth;

        uint256 contractDuduBalance = duduToken.balanceOf(address(this));
        uint256 contractEthBalance = address(this).balance;

        duduBalance = contractDuduBalance - totalDuduInPool;
        ethBalance = contractEthBalance - totalEthInPool;
    }

    function toggleStakingEnabled() external onlyApprovedOwner {
        stakingEnabled = !stakingEnabled;
        emit StakingToggled(stakingEnabled);
    }
}