// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

contract AstroXStakingV3 is Ownable {
    IERC20 public token;

    uint256 public totalStakedAmount;
    uint256 public totalRewardsAmount;

    address public withdrawPenaltyAddress = address(0x47871801c9842CA9645624933EE32E833616e623);
    uint64 public withdrawPenalty = 50; // 5% is 5
    uint64 public withdrawPenaltyBasis = 1000; // 100%
    uint64 public lockDuration = 2 weeks;

    struct StakingDeposit {
        uint120 depositId;
        uint64 createdAt;
        uint64 unlocksAt;
        bool isWithdrawn;
        uint256 amount;
        address depositor;
    }

    StakingDeposit[] public stakingDeposits;

    mapping(address => uint256 totalStaked) public totalStaked;

    event Staked(uint256 depositId, address indexed user, uint256 amount);
    event Unstaked(uint256 depositId, address indexed user, uint256 amount);
    event RewardsFunded(address source, uint256 amount);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function changeContractSettings(
        address _withdrawPenaltyAddress,
        uint64 _withdrawPenalty,
        uint64 _withdrawPenaltyBasis,
        uint64 _lockDuration
    ) external onlyOwner {
        require(_withdrawPenaltyAddress != address(0), "Invalid penalty address");
        require(_withdrawPenaltyBasis > 0, "Invalid penalty basis");
        require(_withdrawPenalty <= _withdrawPenaltyBasis, "Invalid penalty");
        require(_lockDuration > 0, "Invalid lock duration");

        withdrawPenaltyAddress = _withdrawPenaltyAddress;
        withdrawPenalty = _withdrawPenalty;
        withdrawPenaltyBasis = _withdrawPenaltyBasis;
        lockDuration = _lockDuration;
    }

    function getDeposits() external view returns (StakingDeposit[] memory) {
        return stakingDeposits;
    }

    function _calculateReward(uint256 _amount) internal view returns (uint256) {
        require(totalStakedAmount > 0, "No staked amount");
        return (_amount * totalRewardsAmount) / totalStakedAmount;
    }

    function _calculateWithdrawPenalty(uint256 _amount) internal view returns (uint256) {
        return (_amount * withdrawPenalty) / withdrawPenaltyBasis;
    }

    function fundRewards(uint256 amount) external {
        require(amount > 0, "Cannot fund 0 tokens");

        require(token.transferFrom(msg.sender, address(this), amount), "Failed to transfer tokens");

        totalRewardsAmount += amount;

        emit RewardsFunded(msg.sender, amount);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0 tokens");

        require(token.transferFrom(msg.sender, address(this), amount), "Failed to transfer tokens");

        uint256 _depositId = stakingDeposits.length;

        stakingDeposits.push(
            StakingDeposit({
                depositId: uint120(_depositId),
                amount: amount,
                createdAt: uint64(block.timestamp),
                unlocksAt: uint64(block.timestamp + lockDuration),
                isWithdrawn: false,
                depositor: msg.sender
            })
        );

        unchecked {
            totalStaked[msg.sender] += amount;
            totalStakedAmount += amount;
        }

        emit Staked(_depositId, msg.sender, amount);
    }

    function unstakeDeposit(uint256 _depositId) external {
        StakingDeposit storage deposit = stakingDeposits[_depositId];

        require(_depositId < stakingDeposits.length, "Invalid deposit ID");

        require(!deposit.isWithdrawn, "Deposit already withdrawn");

        require(deposit.depositor == msg.sender, "Not depositor");

        require(deposit.unlocksAt <= block.timestamp, "Deposit is still locked");

        uint256 reward = _calculateReward(deposit.amount);

        require(reward > 0, "No reward to claim");

        deposit.isWithdrawn = true;

        unchecked {
            totalStaked[msg.sender] -= deposit.amount;
            totalStakedAmount -= deposit.amount;
            totalRewardsAmount -= reward;
        }

        require(token.transfer(msg.sender, deposit.amount), "Failed to transfer tokens");

        require(token.transfer(msg.sender, reward), "Failed to transfer tokens");

        emit Unstaked(deposit.depositId, msg.sender, deposit.amount);
    }

    function emergencyWithdraw(uint256 _depositId) external {
        StakingDeposit storage deposit = stakingDeposits[_depositId];

        require(_depositId < stakingDeposits.length, "Invalid deposit ID");

        require(!deposit.isWithdrawn, "Deposit already withdrawn");

        require(deposit.depositor == msg.sender, "Not depositor");

        deposit.isWithdrawn = true;

        uint256 amountToWithdraw = deposit.amount;
        uint256 withdrawPenaltyWei = _calculateWithdrawPenalty(amountToWithdraw);
        amountToWithdraw -= withdrawPenaltyWei;

        // Send the penalty to the penalty address
        require(token.transfer(withdrawPenaltyAddress, withdrawPenaltyWei), "Failed to transfer tokens");

        unchecked {
            totalStaked[msg.sender] -= deposit.amount;
            totalStakedAmount -= deposit.amount;
        }

        require(token.transfer(msg.sender, amountToWithdraw), "Failed to transfer tokens");

        emit Unstaked(deposit.depositId, msg.sender, deposit.amount);
    }
}