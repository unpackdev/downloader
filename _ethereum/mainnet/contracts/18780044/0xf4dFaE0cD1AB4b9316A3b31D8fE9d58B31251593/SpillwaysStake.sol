// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

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


contract SpillwaysStake is Ownable(msg.sender) {

    IERC20 public spillToken;
    IERC20 public rewardToken;

    uint256 public currentEpoch;
    uint256 public totalStaked;
    uint256 public totalRewardsClaimed;

    uint256 private _antibottime;
    bool private _paused;

    struct Staker {
        uint256 lastClaimedEpoch;
        uint256 totalStakedAmount;
        mapping(uint256 => StakeHistory[]) stakeHistory; // Mapping epoch to StakeHistory array
    }

    struct EpochData {
        uint256 epochStart;
        uint256 epochEnd;
        uint256 epochRewardRate;
    }

    struct StakeHistory {
        uint256 stakedAmount;
        uint256 timeofStaking;
    }

    mapping(address => Staker) public stakers;
    mapping(uint256 => EpochData) public epochData;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);
    event Epoch(uint256 indexed epoch, uint256 epochStart, uint256 epochEnd, uint256 epochRewardRate);

    constructor(address _spilAddress, address _rewardToken) {
        spillToken = IERC20(_spilAddress);
        rewardToken = IERC20(_rewardToken);
        currentEpoch = 0;
        epochData[currentEpoch] = EpochData(block.timestamp, block.timestamp, 0);
        _antibottime = 2 days;
        _paused = true;
    }

    modifier Active() {
        require(!_paused, "Contract is paused");
        require(currentEpoch > 0, "Initial epoch not started");
        _;
    }

    function startInitial() external onlyOwner {
        require(epochData[currentEpoch].epochEnd == epochData[currentEpoch].epochStart, "Initial epoch already started");
        currentEpoch++;
        epochData[currentEpoch] = EpochData(block.timestamp, block.timestamp, 0);
        _paused = false;
    }

    function startNewEpoch(uint256 _rewards) external onlyOwner {
        require(_rewards > 0, "Rewards must be greater than 0");
        epochData[currentEpoch].epochEnd = block.timestamp;
        if (totalStaked>0){
            epochData[currentEpoch].epochRewardRate = (_rewards * 1e18)/totalStaked;
        }else{
            epochData[currentEpoch].epochRewardRate = 0;
            emit Epoch(currentEpoch, epochData[currentEpoch].epochStart, epochData[currentEpoch].epochEnd, epochData[currentEpoch].epochRewardRate);
            currentEpoch++;
            epochData[currentEpoch] = EpochData(block.timestamp, block.timestamp, 0);
            return;
        }
        emit Epoch(currentEpoch, epochData[currentEpoch].epochStart, epochData[currentEpoch].epochEnd, epochData[currentEpoch].epochRewardRate);
        currentEpoch++;
        require(rewardToken.transferFrom(msg.sender, address(this), _rewards), "Reward transfer failed");
        epochData[currentEpoch] = EpochData(block.timestamp, block.timestamp, 0);
    }

    function balanceOf(address user) external view returns (uint256) {
        return stakers[user].totalStakedAmount;
    }

    function setPaused(bool _paused_) external onlyOwner {
        _paused = _paused_;
    }

    function setAntibotTime(uint256 _antibottime_) external onlyOwner {
        _antibottime = _antibottime_;
    }

    function stakersInfo(address[] calldata users) external view returns (uint[][] memory) {
        uint[][] memory stakersInfo_ = new uint[][](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            stakersInfo_[i] = new uint[](2);
            stakersInfo_[i][0] = stakers[users[i]].totalStakedAmount;
            stakersInfo_[i][1] = stakers[users[i]].lastClaimedEpoch;
        }
        return stakersInfo_;
    }

    function stake(uint256 amount) external Active {
        require(amount > 0, "Amount must be greater than 0");
        require(spillToken.transferFrom(msg.sender, address(this), amount), "Staking transfer failed");
        Staker storage staker = stakers[msg.sender];
        uint256 lastClaimedEpoch = staker.lastClaimedEpoch;

        if (staker.totalStakedAmount == 0) {
            lastClaimedEpoch = currentEpoch - 1;
        }else{
            claim();
        }
        staker.stakeHistory[currentEpoch].push(StakeHistory(amount, block.timestamp));
        staker.totalStakedAmount = staker.totalStakedAmount+amount;
        staker.lastClaimedEpoch = currentEpoch - 1;
        totalStaked = totalStaked+amount;

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external Active {
        require(amount > 0, "Amount must be greater than 0");
        Staker storage staker = stakers[msg.sender];
        require(staker.totalStakedAmount >= amount, "Insufficient staked amount");
        claim();
        staker.totalStakedAmount = staker.totalStakedAmount - amount;
        staker.lastClaimedEpoch = currentEpoch - 1;
        totalStaked = totalStaked - amount;

        if (staker.totalStakedAmount == 0) {
            staker.lastClaimedEpoch = 0;
            delete staker.stakeHistory[currentEpoch - 1];
        }
        require(spillToken.transfer(msg.sender, amount), "Unstaking transfer failed");

        emit Unstaked(msg.sender, amount);
    }

    function claim() public Active {
        Staker storage staker = stakers[msg.sender];
        uint256 lastClaimedEpoch = staker.lastClaimedEpoch;

        if (lastClaimedEpoch == currentEpoch - 1 || staker.totalStakedAmount == 0) {
            return;
        }
        uint256 rewards = _calculateRewards(msg.sender, lastClaimedEpoch, currentEpoch - 1);

        if (rewards > 0) {  
            require(rewardToken.transfer(msg.sender, rewards), "Reward transfer failed");
            totalRewardsClaimed = totalRewardsClaimed+rewards;
        }
        staker.lastClaimedEpoch = currentEpoch - 1;
        emit Claimed(msg.sender, rewards);
    }

    function _calculateRewards(address user, uint256 startEpoch, uint256 endEpoch) private returns (uint256 rewards) {
        Staker storage staker = stakers[user];
        rewards = 0;

        if (staker.lastClaimedEpoch != 0) {startEpoch = startEpoch+1;}

        uint256 stakedAmount = staker.totalStakedAmount;
        
        uint128 thresholdTimestamp = uint128(epochData[endEpoch].epochEnd - _antibottime);
        
        if (staker.stakeHistory[endEpoch].length > 0 && currentEpoch != 2) {
            for (uint256 i = staker.stakeHistory[endEpoch].length - 1; i >= 0; i--) {
                if (staker.stakeHistory[endEpoch][i].timeofStaking < thresholdTimestamp) {
                    break;
                }
                if (staker.stakeHistory[endEpoch][i].stakedAmount > stakedAmount) {
                    stakedAmount = 0;
                    break;
                }
                stakedAmount = stakedAmount - staker.stakeHistory[endEpoch][i].stakedAmount;
                if (i == 0) {break;}
            }
        }

        for (uint256 epoch = startEpoch; epoch <= endEpoch; epoch++) {
            if (epochData[epoch].epochStart == 0 || epochData[epoch].epochEnd == 0) {
                continue;
            }
            uint256 epochRewardRate = epochData[epoch].epochRewardRate;
            uint256 epochStartTime = epochData[epoch].epochStart;
            uint256 epochEndTime = epochData[epoch].epochEnd;

            if (block.timestamp < epochStartTime) {
                continue;
            }
            if (block.timestamp >= epochEndTime) {
                rewards = rewards + ((epochRewardRate * stakedAmount) / 1e18);
            }
            delete staker.stakeHistory[epoch];
        }
        return rewards;
    }

    function emergencyWithdraw(address token, uint256 amount, address _to) external onlyOwner {
        require(IERC20(token).transfer(_to, amount), "Emergency withdraw failed");
    }

    function emergencyWithdrawETH(uint256 amount, address _to) external onlyOwner {
        (bool success, ) = _to.call{value: amount}("");
        require(success, "Emergency withdraw failed");
    }

    function calculateRewards(address user) public view returns (uint256 rewards) {
        Staker storage staker = stakers[user];
        rewards = 0;

        uint256 stakedAmount = staker.totalStakedAmount;
        
        uint128 thresholdTimestamp = uint128(epochData[currentEpoch - 1].epochEnd - _antibottime);
        if (staker.stakeHistory[currentEpoch - 1].length > 0 && currentEpoch != 2) {
            for (uint256 i = staker.stakeHistory[currentEpoch - 1].length - 1; i >= 0; i--) {
                if (staker.stakeHistory[currentEpoch - 1][i].timeofStaking < thresholdTimestamp) {
                    break;
                }
                stakedAmount = stakedAmount - staker.stakeHistory[currentEpoch - 1][i].stakedAmount;
                if (i == 0) {break;}
            }
        }

        for (uint256 epoch = staker.lastClaimedEpoch+1; epoch <= currentEpoch - 1; epoch++) {
            if (epochData[epoch].epochStart == 0 || epochData[epoch].epochEnd == 0) {
                continue;
            }
            uint256 epochRewardRate = epochData[epoch].epochRewardRate;
            uint256 epochStartTime = epochData[epoch].epochStart;
            uint256 epochEndTime = epochData[epoch].epochEnd;

            if (block.timestamp < epochStartTime) {
                continue;
            }
            if (block.timestamp >= epochEndTime) {
                rewards = rewards + ((epochRewardRate * stakedAmount) / 1e18);
            }
        }
        return rewards;
    }
}