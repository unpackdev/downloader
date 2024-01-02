// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

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
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract StakingPool is Context, Ownable(msg.sender) {
    struct Share {
        uint depositTime;
        uint initialDeposit;
        uint sumReward;
    }

    mapping(address => Share) public shares;
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint public sumReward;
    uint private constant PRECISION = 1e18;
    address private _taxWallet;
    uint public totalReward;
    uint256 public totalDistributed;
    bool public initialized;

    constructor() {
        _taxWallet = _msgSender();
    }

    function init(address _rewardToken, address _stakingToken) external {
        require(!initialized, "alrealy initialized");
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        initialized = true;
    }

    function setStakeToken(IERC20 token_) external onlyOwner {
        stakingToken = token_;
    }

    function setRewardToken(IERC20 token_) external onlyOwner {
        stakingToken = token_;
    }

    function deposit(uint amount) external {
        require(amount > 0, "Amount must be greater than zero");
        Share memory share = shares[_msgSender()];
        stakingToken.transferFrom(_msgSender(), address(this), amount);
        _payoutGainsUpdateShare(
            _msgSender(),
            share,
            share.initialDeposit + amount,
            true
        );
    }

    function withdraw() external {
        Share memory share = shares[_msgSender()];
        require(share.initialDeposit > 0, "No initial deposit");
        require(
            share.depositTime + 1 days < block.timestamp,
            "withdraw after one day"
        );
        stakingToken.transfer(_msgSender(), share.initialDeposit);
        _payoutGainsUpdateShare(_msgSender(), share, 0, true);
    }

    function claimallshares() external {
        Share memory share = shares[_msgSender()];
        require(share.initialDeposit > 0, "No initial deposit");
        _payoutGainsUpdateShare(
            _msgSender(),
            share,
            share.initialDeposit,
            false
        );
    }

    function _payoutGainsUpdateShare(
        address who,
        Share memory share,
        uint newAmount,
        bool resetTimer
    ) private {
        uint gains;
        if (share.initialDeposit != 0)
            gains =
                (share.initialDeposit * (sumReward - share.sumReward)) /
                PRECISION;

        if (newAmount == 0) delete shares[who];
        else if (resetTimer)
            shares[who] = Share(block.timestamp, newAmount, sumReward);
        else shares[who] = Share(share.depositTime, newAmount, sumReward);

        if (gains > 0) {
            rewardToken.transfer(who, gains);
            totalDistributed = totalDistributed + gains;
        }
    }

    function pending(address who) external view returns (uint) {
        Share memory share = shares[who];
        return
            (share.initialDeposit * (sumReward - share.sumReward)) / PRECISION;
    }

    function updateReward(uint256 _amount) external {
        require(
            _msgSender() == address(rewardToken),
            "only accept token contract"
        );

        uint balance = stakingToken.balanceOf(address(this));

        if (_amount == 0 || balance == 0) return;

        uint gpus = (_amount * PRECISION) / balance;
        sumReward += gpus;
        totalReward += _amount;
    }

    function withdrawDividend(address _address) external {
        IERC20(_address).transfer(
            owner(),
            IERC20(_address).balanceOf(address(this))
        );
    }

    function refreshrewards() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}