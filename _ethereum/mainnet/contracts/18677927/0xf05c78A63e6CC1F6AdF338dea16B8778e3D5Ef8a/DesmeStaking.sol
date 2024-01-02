// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

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

// File: @openzeppelin/contracts/utils/Pausable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

//SPDX-License-Identifier: MIT

interface IERC20EXT {
    function decimals() external view returns (uint8);
}

struct StructAccount {
    address selfAddress;
    uint256 totalValueStaked;
    uint256 stakingRewardsClaimed;
    uint256 pendingStakingRewards;
    uint256[] stakingIds;
}

struct StructStaking {
    bool isActive;
    address owner;
    uint256 stakingId;
    uint256 valueStaked;
    uint256 startTime;
    uint256 stakingRewardClaimed;
    uint256 initialRewards;
    uint256 calStartTime;
}

contract DesmeStaking is Ownable, Pausable {
    address[] private _users;
    uint256 private _totalStakingRewardsDistributed;

    uint256 private _stakingsCount;

    uint256 private _calStakingReward;
    uint256 private _valueStaked;

    uint256 private _lastTimeRewardDistributed;
    uint256 private _carryForwardBalance;

    address private _tokenAddress;

    bool private _noReentrancy;

    mapping(address => StructAccount) private _mappingAccounts;
    mapping(uint256 => StructStaking) private _mappingStakings;

    event SelfAddressUpdated(address newAddress);

    event Stake(uint256 value, uint256 stakingId);
    event UnStake(uint256 value);

    event ClaimedStakingReward(uint256 value);
    event DistributeStakingReward(uint256 value);
    event ClaimCarryForwardBalance(address receiver, uint256 value);

    event ContractPaused(bool isPaused);

    modifier noReentrancy() {
        require(!_noReentrancy, "Reentrancy attack.");
        _noReentrancy = true;
        _;
        _noReentrancy = false;
    }

    receive() external payable {
        distributeStakingRewards();
    }

    constructor(address initialOwner) Ownable(initialOwner) {
        uint256 currentTime = block.timestamp;
        _lastTimeRewardDistributed = currentTime;
    }

    function _updateUserAddress(
        StructAccount storage _userAccount,
        address _userAddress
    ) private {
        _userAccount.selfAddress = _userAddress;
        emit SelfAddressUpdated(_userAddress);
    }

    function _updateCalStakingReward(
        StructStaking storage stakingAccount,
        uint256 _value
    ) private {
        if (_calStakingReward > 0) {
            uint256 stakingReward = (_calStakingReward * _value) / _valueStaked;

            stakingAccount.initialRewards += stakingReward;
            _calStakingReward += stakingReward;
        }
    }

    function _stake(address _userAddress, uint256 _value) private {
        require(
            _userAddress != address(0),
            "_stake(): AddressZero cannot stake."
        );
        require(_value > 0, "_stake(): Value should be greater than zero.");

        StructAccount storage userAccount = _mappingAccounts[_userAddress];
        uint256 currentStakingId = _stakingsCount;

        if (userAccount.selfAddress == address(0)) {
            _updateUserAddress(userAccount, _userAddress);
            _users.push(_userAddress);
        }

        userAccount.stakingIds.push(currentStakingId);
        userAccount.totalValueStaked += _value;

        StructStaking storage stakingAccount = _mappingStakings[
            currentStakingId
        ];

        stakingAccount.isActive = true;
        stakingAccount.owner = _userAddress;
        stakingAccount.stakingId = currentStakingId;
        stakingAccount.valueStaked = _value;
        stakingAccount.startTime = block.timestamp;
        stakingAccount.calStartTime = _lastTimeRewardDistributed;

        _updateCalStakingReward(stakingAccount, _value);

        _valueStaked += _value;
        _stakingsCount++;

        emit Stake(_value, currentStakingId);
    }

    function stake(address _userAddress, uint256 _valueInWei)
        external
        whenNotPaused
    {
        bool sent = IERC20(_tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _toTokens(_tokenAddress, _valueInWei)
        );

        require(sent, "unStake(): Tokens not transfered");

        _stake(_userAddress, _valueInWei);
    }

    function _getStakingRewardsById(StructStaking memory stakingAccount)
        private
        view
        returns (
            uint256 userStakingReward,
            uint256 rewardClaimable,
            uint256 carryForwardBalance
        )
    {
        if (
            _calStakingReward > 0 &&
            stakingAccount.isActive &&
            stakingAccount.calStartTime < _lastTimeRewardDistributed
        ) {
            userStakingReward =
                ((_calStakingReward * stakingAccount.valueStaked) /
                    _valueStaked) -
                (stakingAccount.stakingRewardClaimed +
                    stakingAccount.initialRewards);

            if (userStakingReward > 0) {
                carryForwardBalance = ((userStakingReward *
                    (stakingAccount.startTime - stakingAccount.calStartTime)) /
                    (_lastTimeRewardDistributed - stakingAccount.calStartTime));

                rewardClaimable = userStakingReward - carryForwardBalance;
            }
        }
    }

    function getStakingRewardsById(uint256 _stakingId)
        external
        view
        returns (
            uint256 userStakingReward,
            uint256 rewardClaimable,
            uint256 carryForwardBalance
        )
    {
        return _getStakingRewardsById(_mappingStakings[_stakingId]);
    }

    function _getUserAllStakingRewards(StructAccount memory userAccount)
        private
        view
        returns (
            uint256 userTotalStakingReward,
            uint256 totalRewardClaimable,
            uint256 totalCarryForwardBalance
        )
    {
        uint256[] memory userStakingIds = userAccount.stakingIds;

        for (uint256 i; i < userStakingIds.length; ++i) {
            StructStaking memory stakingAccount = _mappingStakings[
                userStakingIds[i]
            ];

            if (stakingAccount.isActive) {
                (
                    uint256 userStakingReward,
                    uint256 rewardClaimable,
                    uint256 carryForwardBalance
                ) = _getStakingRewardsById(stakingAccount);

                userTotalStakingReward += userStakingReward;
                totalRewardClaimable += rewardClaimable;
                totalCarryForwardBalance += carryForwardBalance;
            }
        }
    }

    function getUserStakingRewards(address _userAddress)
        external
        view
        returns (
            uint256 userTotalStakingReward,
            uint256 rewardClaimable,
            uint256 carryForwardBalance
        )
    {
        StructAccount memory userAccount = _mappingAccounts[_userAddress];

        return _getUserAllStakingRewards(userAccount);
    }

    function _claimUserStakingReward(address _userAddress)
        private
        returns (uint256 totalRewardClaimable, uint256 totalCarryForwardBalance)
    {
        StructAccount storage userAccount = _mappingAccounts[_userAddress];
        require(
            userAccount.stakingIds.length > 0,
            "_claimStakingReward(): You have no stakings"
        );

        for (uint256 i; i < userAccount.stakingIds.length; ++i) {
            StructStaking storage stakingAccount = _mappingStakings[
                userAccount.stakingIds[i]
            ];

            require(
                stakingAccount.owner == _userAddress,
                "You are not the owner of this staking."
            );

            if (stakingAccount.isActive) {
                (
                    ,
                    uint256 rewardClaimable,
                    uint256 carryForwardBalance
                ) = _getStakingRewardsById(stakingAccount);

                if (rewardClaimable > 0) {
                    stakingAccount.stakingRewardClaimed += rewardClaimable;
                    totalRewardClaimable += rewardClaimable;
                }

                if (carryForwardBalance > 0) {
                    stakingAccount.initialRewards += carryForwardBalance;
                    totalCarryForwardBalance += carryForwardBalance;
                }
            }
        }

        if (totalRewardClaimable > 0) {
            userAccount.stakingRewardsClaimed += totalRewardClaimable;
            _carryForwardBalance += totalCarryForwardBalance;

            emit ClaimedStakingReward(totalRewardClaimable);
        }
    }

    function claimStakingReward(address _userAddress) external noReentrancy {
        (uint256 rewardClaimable, ) = _claimUserStakingReward(_userAddress);

        require(
            rewardClaimable > 0,
            "_claimUserStakingReward(): No rewards to claim."
        );

        uint256 ethBalanceThis = address(this).balance;

        require(
            ethBalanceThis >= rewardClaimable,
            "claimStakingReward(): Contract has less balance to pay."
        );

        (bool status, ) = payable(_userAddress).call{value: rewardClaimable}(
            ""
        );
        require(status, "claimStakingReward(): Reward ETH Not transfered.");
    }

    function _unStake(address _userAddress)
        private
        returns (uint256 tokenUnStaked, uint256 stakingRewardClaimed)
    {
        StructAccount storage userAccount = _mappingAccounts[_userAddress];

        require(
            userAccount.stakingIds.length > 0,
            "_claimStakingReward(): You have no stakings"
        );

        (uint256 rewardClaimable, ) = _claimUserStakingReward(_userAddress);

        if (rewardClaimable > 0) {
            stakingRewardClaimed += rewardClaimable;
        }

        userAccount.totalValueStaked = 0;
        uint256 calRewards;

        for (uint256 i; i < userAccount.stakingIds.length; ++i) {
            StructStaking storage stakingAccount = _mappingStakings[
                userAccount.stakingIds[i]
            ];

            require(
                stakingAccount.owner == _userAddress,
                "You are not the owner of this staking."
            );

            if (stakingAccount.isActive) {
                stakingAccount.isActive = false;
                tokenUnStaked += stakingAccount.valueStaked;
                calRewards += stakingAccount.stakingRewardClaimed;
                calRewards += stakingAccount.initialRewards;
            }
        }

        require(tokenUnStaked > 0, "_unstake(): No value to unStake.");

        _calStakingReward -= calRewards;

        _valueStaked -= tokenUnStaked;
        emit UnStake(tokenUnStaked);
    }

    function unStake() external {
        address msgSender = msg.sender;
        (uint256 tokenUnStaked, uint256 stakingRewardClaimed) = _unStake(
            msgSender
        );

        if (tokenUnStaked > 0) {
            bool sent = IERC20(_tokenAddress).transfer(
                msgSender,
                _toTokens(_tokenAddress, tokenUnStaked)
            );

            require(sent, "unStake(): Tokens not transfered");
        }

        if (stakingRewardClaimed > 0) {
            (bool status, ) = payable(msgSender).call{
                value: stakingRewardClaimed
            }("");
            require(status, "unstake(): Reward not transfered.");
        }
    }

    function distributeStakingRewards() public payable {
        uint256 msgValue = msg.value;

        require(
            msgValue > 0,
            "distributeStakingRewards(): Reward must be greater than zero."
        );

        if (_carryForwardBalance > 0) {
            msgValue += _carryForwardBalance;
            delete _carryForwardBalance;
        }

        _calStakingReward += msgValue;
        _lastTimeRewardDistributed = block.timestamp;
        _totalStakingRewardsDistributed += msgValue;

        emit DistributeStakingReward(msgValue);
    }

    function getUsersParticipatedList()
        external
        view
        returns (address[] memory)
    {
        return _users;
    }

    function getUserShare(address _userAddress)
        external
        view
        returns (uint256 userShare)
    {
        StructAccount memory userAccount = _mappingAccounts[_userAddress];

        userShare =
            (userAccount.totalValueStaked * 100 * 1 ether) /
            _valueStaked;
    }

    function getContractDefault() external view returns (address tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function setTokenAddress(address tokenAddress_) external onlyOwner {
        _tokenAddress = tokenAddress_;
    }

    function getContractAnalytics()
        external
        view
        returns (
            uint256 usersCount,
            uint256 stakingsCount,
            uint256 totalStakingRewardsDistributed,
            uint256 calStakingReward,
            uint256 valueStaked,
            uint256 lastTimeRewardDistributed,
            uint256 carryForwardBalance
        )
    {
        usersCount = _users.length;
        stakingsCount = _stakingsCount;
        totalStakingRewardsDistributed = _totalStakingRewardsDistributed;
        calStakingReward = _calStakingReward;
        valueStaked = _valueStaked;
        lastTimeRewardDistributed = _lastTimeRewardDistributed;
        carryForwardBalance = _carryForwardBalance;
    }

    function getUserAccount(address _userAddress)
        external
        view
        returns (StructAccount memory)
    {
        return _mappingAccounts[_userAddress];
    }

    function getStakingById(uint256 _stakingId)
        external
        view
        returns (StructStaking memory)
    {
        return _mappingStakings[_stakingId];
    }

    function _toTokens(address tokenAddress_, uint256 _valueInWei)
        private
        view
        returns (uint256 valueInTokens)
    {
        valueInTokens =
            (_valueInWei * 10**IERC20EXT(tokenAddress_).decimals()) /
            1 ether;
    }

    function _toWei(address _tokenAddress_, uint256 _valueInTokens)
        private
        view
        returns (uint256 valueInWei)
    {
        valueInWei =
            (_valueInTokens * 1 ether) /
            10**IERC20EXT(_tokenAddress_).decimals();
    }

    function claimCarryForwardBalance(address _userAddress) external onlyOwner {
        uint256 carryForwardBalance = _carryForwardBalance;
        require(
            carryForwardBalance > 0,
            "claimCarryForwardBalance(): Balance must be above zero."
        );

        (bool sent, ) = payable(_userAddress).call{value: carryForwardBalance}(
            ""
        );
        require(sent, "claimCarryForwardBalance(): ETH Not transfered.");
        delete _carryForwardBalance;

        emit ClaimCarryForwardBalance(_userAddress, carryForwardBalance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}