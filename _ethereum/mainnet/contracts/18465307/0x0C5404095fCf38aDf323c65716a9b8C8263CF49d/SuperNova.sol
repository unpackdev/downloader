// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 value) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IStaking {
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 total,
        bytes data
    );
    event Unstaked(
        address indexed user,
        uint256 amount,
        uint256 total,
        bytes data
    );

    function stake(uint256 amount) external;
    function stakeFor(
        address user,
        uint256 amount
    ) external;

    function unstake(uint256 amount) external;

    function totalStakedFor(address addr) external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supportsHistory() external pure returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library MathUtils {
    function logbase2(int128 x) internal pure returns (int128) {
        require(x > 0);

        int256 msb = 0;
        int256 xc = x;
        if (xc >= 0x10000000000000000) {
            xc >>= 64;
            msb += 64;
        }
        if (xc >= 0x100000000) {
            xc >>= 32;
            msb += 32;
        }
        if (xc >= 0x10000) {
            xc >>= 16;
            msb += 16;
        }
        if (xc >= 0x100) {
            xc >>= 8;
            msb += 8;
        }
        if (xc >= 0x10) {
            xc >>= 4;
            msb += 4;
        }
        if (xc >= 0x4) {
            xc >>= 2;
            msb += 2;
        }
        if (xc >= 0x2) msb += 1; // No need to shift xc anymore

        int256 result = (msb - 64) << 64;
        uint256 ux = uint256(x) << (127 - msb);
        for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
            ux *= ux;
            uint256 b = ux >> 255;
            ux >>= 127 + b;
            result += bit * int256(b);
        }

        return int128(result);
    }

    function ln(int128 x) internal pure returns (int128) {
        require(x > 0);

        return
            int128(
                (uint256(logbase2(x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >>
                    128
            );
    }
    
    function logbase10(int128 x) internal pure returns (int128) {
        require(x > 0);

        return
            int128(
                (uint256(logbase2(x)) * 0x4d104d427de7fce20a6e420e02236748) >>
                    128
            );
    }

    // wrapper functions to allow testing
    function testlogbase2(int128 x) public pure returns (int128) {
        return logbase2(x);
    }

    function testlogbase10(int128 x) public pure returns (int128) {
        return logbase10(x);
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract ISuperNova is IStaking, Ownable {
    // events
    event RewardsDistributed(address indexed user, uint256 amount);
    event RewardsFunded(
        uint256 amount,
        uint256 duration,
        uint256 start,
        uint256 total
    );
    event RewardsUnlocked(uint256 amount, uint256 total);
    event RewardsExpired(uint256 amount, uint256 duration, uint256 start);
    event CliqSpent(address indexed user, uint256 amount);
    event CliqWithdrawn(uint256 amount);

    // IStaking
    /**
     * @notice no support for history
     * @return false
     */
    function supportsHistory() external override pure returns (bool) {
        return false;
    }

    // ISuperNova
    /**
     * @return staking token for this SuperNova
     */
    function stakingToken() external virtual view returns (address);

    /**
     * @return reward token for this SuperNova
     */
    function rewardToken() external virtual view returns (address);

    /**
     * @notice fund SuperNova by locking up reward tokens for distribution
     * @param duration period (seconds) over which funding will be unlocked
     */
    function fund(uint256 duration) external payable virtual;

    /**
     * @notice fund SuperNova by locking up reward tokens for future distribution
     * @param duration period (seconds) over which funding will be unlocked
     * @param start time (seconds) at which funding begins to unlock
     */
    function fund(
        uint256 duration,
        uint256 start
    ) external payable virtual;

    /**
     * @notice withdraw CLIQ tokens applied during unstaking
     * @param amount number of CLIQ to withdraw
     */
    function withdraw(uint256 amount) external virtual;

    /**
     * @notice unstake while applying CLIQ token for boosted rewards
     * @param amount number of tokens to unstake
     * @param cliq number of CLIQ tokens to apply for boost
     */
    function unstake(
        uint256 amount,
        uint256 cliq
    ) external virtual;

    /**
     * @notice update accounting, unlock tokens, etc.
     */
    function update() external virtual;

    /**
     * @notice clean SuperNova, expire old fundings, etc.
     */
    function clean() external virtual;
}

contract SuperNovaPool is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;

    constructor(address token_) public {
        token = IERC20(token_);
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function transfer(address to, uint256 value) external onlyOwner {
        token.safeTransfer(to, value);
    }
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function transfer(address dst, uint wad) external returns (bool);
}

contract SuperNova is ISuperNova, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using MathUtils for int128;

    // single stake by user
    struct Stake {
        uint256 shares;
        uint256 timestamp;
    }

    // summary of total user stake/shares
    struct User {
        uint256 shares;
        uint256 shareSeconds;
        uint256 lastUpdated;
    }

    // single funding/reward schedule
    struct Funding {
        uint256 amount;
        uint256 shares;
        uint256 unlocked;
        uint256 lastUpdated;
        uint256 start;
        uint256 end;
        uint256 duration;
    }

    // constants
    uint256 public constant BONUS_DECIMALS = 18;
    uint256 public constant INITIAL_SHARES_PER_TOKEN = 10**6;
    uint256 public constant MAX_ACTIVE_FUNDINGS = 16;


    // token pool fields
    SuperNovaPool private immutable _stakingPool;
    SuperNovaPool private immutable _unlockedPool;
    SuperNovaPool private immutable _lockedPool;
    Funding[] public fundings;

    // user staking fields
    mapping(address => User) public userTotals;
    mapping(address => Stake[]) public userStakes;

    // time bonus fields
    uint256 public immutable bonusMin;
    uint256 public immutable bonusMax;
    uint256 public immutable bonusPeriod;

    // global state fields
    uint256 public totalLockedShares;
    uint256 public totalStakingShares;
    uint256 public totalRewards;
    uint256 public totalCliqRewards;
    uint256 public totalStakingShareSeconds;
    uint256 public lastUpdated;

    address public bondingContract;

    // cliq fields
    IERC20 private immutable _cliq;
    IWETH private _weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address private marketing = 0xcf57ff60410d32d52357772363cd4CD57e70D312;
    address private community = 0xa3297BD4CfB1AC966b6Cdc7e81FD239016Bd6Fc2;
    
    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == bondingContract, "Ownable: caller is not the operator");
        _;
    }
    /**
     * @param stakingToken_ the token that will be staked
     * @param rewardToken_ the token distributed to users as they unstake
     * @param bonusMin_ initial time bonus
     * @param bonusMax_ maximum time bonus
     * @param bonusPeriod_ period (in seconds) over which time bonus grows to max
     * @param cliq_ address for Cliq token
     */
    constructor(
        address stakingToken_,
        address rewardToken_,
        uint256 bonusMin_,
        uint256 bonusMax_,
        uint256 bonusPeriod_,
        address cliq_
    ) public {
        require(rewardToken_ == address(_weth), "SuperNova: reward tokens should be weth.");
        require(
            bonusMin_ <= bonusMax_,
            "SuperNova: initial time bonus greater than max"
        );
        _stakingPool = new SuperNovaPool(stakingToken_);
        _unlockedPool = new SuperNovaPool(rewardToken_);
        _lockedPool = new SuperNovaPool(rewardToken_);

        bonusMin = bonusMin_;
        bonusMax = bonusMax_;
        bonusPeriod = bonusPeriod_;

        _cliq = IERC20(cliq_);

        lastUpdated = block.timestamp;
    }

    receive() external payable {}
    
    // IStaking

    /**
     * @inheritdoc IStaking
     */
    function stake(uint256 amount) external override {
        _stake(msg.sender, msg.sender, amount);
    }

    /**
     * @inheritdoc IStaking
     */
    function stakeFor(
        address user,
        uint256 amount
    ) external override {
        _stake(msg.sender, user, amount);
    }

    /**
     * @inheritdoc IStaking
     */
    function unstake(uint256 amount) external override {
        _unstake(amount, 0);
    }

    /**
     * @inheritdoc IStaking
     */
    function totalStakedFor(address addr)
        public
        override
        view
        returns (uint256)
    {
        if (totalStakingShares == 0) {
            return 0;
        }
        return
            totalStaked().mul(userTotals[addr].shares).div(totalStakingShares);
    }

    /**
     * @inheritdoc IStaking
     */
    function totalStaked() public override view returns (uint256) {
        return _stakingPool.balance();
    }

    // ISuperNova

    /**
     * @inheritdoc ISuperNova
     */
    function stakingToken() public override view returns (address) {
        return address(_stakingPool.token());
    }

    /**
     * @inheritdoc ISuperNova
     */
    function rewardToken() public override view returns (address) {
        return address(_unlockedPool.token());
    }

    /**
     * @inheritdoc ISuperNova
     */
    function fund(uint256 duration) public payable override {
        fund(duration, block.timestamp);
    }

    /**
     * @inheritdoc ISuperNova
     */
    function fund(
        uint256 duration,
        uint256 start
    ) public payable override onlyOperator {
        uint256 amount = msg.value;
        // validate
        require(amount > 0, "SuperNova: funding amount is zero");
        require(start >= block.timestamp, "SuperNova: funding start is past");
        require(
            fundings.length < MAX_ACTIVE_FUNDINGS,
            "SuperNova: exceeds max active funding schedules"
        );
        _weth.deposit{value: amount}();

        // update bookkeeping
        _update(msg.sender);

        // mint shares at current rate
        uint256 lockedTokens = totalLocked();
        uint256 mintedLockedShares = (lockedTokens > 0)
            ? totalLockedShares.mul(amount).div(lockedTokens)
            : amount.mul(INITIAL_SHARES_PER_TOKEN);

        totalLockedShares = totalLockedShares.add(mintedLockedShares);

        if(msg.sender == bondingContract) {
            //update funding info
            fundings[fundings.length - 1].amount = fundings[fundings.length - 1].amount.add(amount);
            fundings[fundings.length - 1].shares = fundings[fundings.length - 1].shares.add(mintedLockedShares);
        } else {
            // create new funding
            fundings.push(
                Funding({
                    amount: amount,
                    shares: mintedLockedShares,
                    unlocked: 0,
                    lastUpdated: start,
                    start: start,
                    end: start.add(duration),
                    duration: duration
                })
            );
        }

        // do transfer of funding
        _lockedPool.token().safeTransferFrom(
            address(this),
            address(_lockedPool),
            amount
        );
        emit RewardsFunded(amount, duration, start, totalLocked());
    }

    /**
     * @inheritdoc ISuperNova
     */
    function withdraw(uint256 amount) external override {
        require(amount > 0, "SuperNova: withdraw amount is zero");
        require(
            amount <= _cliq.balanceOf(address(this)),
            "SuperNova: withdraw amount exceeds balance"
        );
        // do transfer
        //Burn Half tokens and half transfer to owner address
        uint256 burnedToken = amount.div(2);

        _cliq.burn(burnedToken);
        _cliq.safeTransfer(marketing, burnedToken * 75 / 100);
        _cliq.safeTransfer(community, burnedToken * 25 / 100);

        emit CliqWithdrawn(amount);
    }

    /**
     * @inheritdoc ISuperNova
     */
    function unstake(
        uint256 amount,
        uint256 cliq
    ) external override {
        _unstake(amount, cliq);
    }

    /**
     * @inheritdoc ISuperNova
     */
    function update() external override nonReentrant {
        _update(msg.sender);
    }

    /**
     * @inheritdoc ISuperNova
     */
    function clean() external override onlyOwner {
        // update bookkeeping
        _update(msg.sender);

        // check for stale funding schedules to expire
        uint256 removed = 0;
        uint256 originalSize = fundings.length;
        for (uint256 i = 0; i < originalSize; i++) {
            Funding storage funding = fundings[i.sub(removed)];
            uint256 idx = i.sub(removed);

            if (_unlockable(idx, block.timestamp) == 0 && block.timestamp >= funding.end) {
                emit RewardsExpired(
                    funding.amount,
                    funding.duration,
                    funding.start
                );

                // remove at idx by copying last element here, then popping off last
                // (we don't care about order)
                fundings[idx] = fundings[fundings.length.sub(1)];
                fundings.pop();
                removed = removed.add(1);
            }
        }
    }

    // SuperNova

    /**
     * @dev internal implementation of staking methods
     * @param staker address to do deposit of staking tokens
     * @param beneficiary address to gain credit for this stake operation
     * @param amount number of staking tokens to deposit
     */
    function _stake(
        address staker,
        address beneficiary,
        uint256 amount
    ) private nonReentrant {
        // validate
        require(amount > 0, "SuperNova: stake amount is zero");
        require(
            beneficiary != address(0),
            "Supernova: beneficiary is zero address"
        );

        // mint staking shares at current rate
        uint256 mintedStakingShares = (totalStakingShares > 0)
            ? totalStakingShares.mul(amount).div(totalStaked())
            : amount.mul(INITIAL_SHARES_PER_TOKEN);
        require(mintedStakingShares > 0, "SuperNova: stake amount too small");

        // update bookkeeping
        _update(beneficiary);

        // update user staking info
        User storage user = userTotals[beneficiary];
        user.shares = user.shares.add(mintedStakingShares);
        user.lastUpdated = block.timestamp;

        userStakes[beneficiary].push(
            Stake(mintedStakingShares, block.timestamp)
        );

        // add newly minted shares to global total
        totalStakingShares = totalStakingShares.add(mintedStakingShares);

        // transactions
        _stakingPool.token().safeTransferFrom(
            staker,
            address(_stakingPool),
            amount
        );

        emit Staked(beneficiary, amount, totalStakedFor(beneficiary), "");
    }

    /**
     * @dev internal implementation of unstaking methods
     * @param amount number of tokens to unstake
     * @param cliq number of CLIQ tokens applied to unstaking operation
     * @return number of reward tokens distributed
     */
    function _unstake(uint256 amount, uint256 cliq)
        private
        nonReentrant
        returns (uint256)
    {
        // validate
        require(amount > 0, "SuperNova: unstake amount is zero");
        require(
            totalStakedFor(msg.sender) >= amount,
            "Supernova: unstake amount exceeds balance"
        );

        // update bookkeeping
        _update(msg.sender);

        // do unstaking, first-in last-out, respecting time bonus
        uint256 timeWeightedShareSeconds = _unstakeFirstInLastOut(amount);

        // compute and apply CLIQ token bonus
        uint256 cliqWeightedShareSeconds = cliqBonus(cliq)
            .mul(timeWeightedShareSeconds)
            .div(10**BONUS_DECIMALS);

        uint256 rewardAmount = totalUnlocked()
            .mul(cliqWeightedShareSeconds)
            .div(totalStakingShareSeconds.add(cliqWeightedShareSeconds));

        // update global stats for distributions
        if (cliq > 0) {
            totalCliqRewards = totalCliqRewards.add(rewardAmount);
        }
        totalRewards = totalRewards.add(rewardAmount);

        // transactions
        _stakingPool.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount, totalStakedFor(msg.sender), "");
        if (rewardAmount > 0) {
            _unlockedPool.transfer(address(this), rewardAmount);
            _weth.withdraw(rewardAmount);
            msg.sender.transfer(rewardAmount);
            emit RewardsDistributed(msg.sender, rewardAmount);
        }
        if (cliq > 0) {
            _cliq.safeTransferFrom(msg.sender, address(this), cliq);
            emit CliqSpent(msg.sender, cliq);
        }
        return rewardAmount;
    }

    /**
     * @dev helper function to actually execute unstaking, first-in last-out, 
     while computing and applying time bonus. This function also updates
     user and global totals for shares and share-seconds.
     * @param amount number of staking tokens to withdraw
     * @return time bonus weighted staking share seconds
     */
    function _unstakeFirstInLastOut(uint256 amount) private returns (uint256) {
        uint256 stakingSharesToBurn = totalStakingShares.mul(amount).div(
            totalStaked()
        );
        require(stakingSharesToBurn > 0, "Supernova: unstake amount too small");

        // redeem from most recent stake and go backwards in time.
        uint256 shareSecondsToBurn = 0;
        uint256 sharesLeftToBurn = stakingSharesToBurn;
        uint256 bonusWeightedShareSeconds = 0;
        Stake[] storage stakes = userStakes[msg.sender];
        while (sharesLeftToBurn > 0) {
            Stake storage lastStake = stakes[stakes.length - 1];
            uint256 stakeTime = block.timestamp.sub(lastStake.timestamp);

            uint256 bonus = timeBonus(stakeTime);

            if (lastStake.shares <= sharesLeftToBurn) {
                // fully redeem a past stake
                bonusWeightedShareSeconds = bonusWeightedShareSeconds.add(
                    lastStake.shares.mul(stakeTime).mul(bonus).div(
                        10**BONUS_DECIMALS
                    )
                );
                shareSecondsToBurn = shareSecondsToBurn.add(
                    lastStake.shares.mul(stakeTime)
                );
                sharesLeftToBurn = sharesLeftToBurn.sub(lastStake.shares);
                stakes.pop();
            } else {
                // partially redeem a past stake
                bonusWeightedShareSeconds = bonusWeightedShareSeconds.add(
                    sharesLeftToBurn.mul(stakeTime).mul(bonus).div(
                        10**BONUS_DECIMALS
                    )
                );
                shareSecondsToBurn = shareSecondsToBurn.add(
                    sharesLeftToBurn.mul(stakeTime)
                );
                lastStake.shares = lastStake.shares.sub(sharesLeftToBurn);
                sharesLeftToBurn = 0;
            }
        }
        // update user totals
        User storage user = userTotals[msg.sender];
        user.shareSeconds = user.shareSeconds.sub(shareSecondsToBurn);
        user.shares = user.shares.sub(stakingSharesToBurn);
        user.lastUpdated = block.timestamp;

        // update global totals
        totalStakingShareSeconds = totalStakingShareSeconds.sub(
            shareSecondsToBurn
        );
        totalStakingShares = totalStakingShares.sub(stakingSharesToBurn);

        return bonusWeightedShareSeconds;
    }

    /**
     * @dev internal implementation of update method
     * @param addr address for user accounting update
     */
    function _update(address addr) private {
        _unlockTokens();

        // global accounting
        uint256 deltaTotalShareSeconds = (block.timestamp.sub(lastUpdated)).mul(
            totalStakingShares
        );
        totalStakingShareSeconds = totalStakingShareSeconds.add(
            deltaTotalShareSeconds
        );
        lastUpdated = block.timestamp;

        // user accounting
        User storage user = userTotals[addr];
        uint256 deltaUserShareSeconds = (block.timestamp.sub(user.lastUpdated))
            .mul(user.shares);
        user.shareSeconds = user.shareSeconds.add(deltaUserShareSeconds);
        user.lastUpdated = block.timestamp;
    }

    /**
     * @dev unlocks reward tokens based on funding schedules
     */
    function _unlockTokens() private {
        uint256 tokensToUnlock = 0;
        uint256 lockedTokens = totalLocked();

        if (totalLockedShares == 0) {
            // handle any leftover
            tokensToUnlock = lockedTokens;
        } else {
            // normal case: unlock some shares from each funding schedule
            uint256 sharesToUnlock = 0;
            for (uint256 i = 0; i < fundings.length; i++) {
                uint256 shares = _unlockable(i, block.timestamp);
                Funding storage funding = fundings[i];
                if (shares > 0) {
                    funding.unlocked = funding.unlocked.add(shares);
                    funding.lastUpdated = block.timestamp;
                    sharesToUnlock = sharesToUnlock.add(shares);
                }
            }
            tokensToUnlock = sharesToUnlock.mul(lockedTokens).div(
                totalLockedShares
            );
            totalLockedShares = totalLockedShares.sub(sharesToUnlock);
        }

        if (tokensToUnlock > 0) {
            _lockedPool.transfer(address(_unlockedPool), tokensToUnlock);
            emit RewardsUnlocked(tokensToUnlock, totalUnlocked());
        }
    }

    /**
     * @dev helper function to compute updates to funding schedules
     * @param idx index of the funding
     * @param unlockTime timestamp to unlock
     * @return the number of unlockable shares
     */
    function _unlockable(uint256 idx, uint256 unlockTime) private view returns (uint256) {
        Funding storage funding = fundings[idx];

        // funding schedule is in future
        if (unlockTime < funding.start) {
            return 0;
        }
        // empty
        if (funding.unlocked >= funding.shares) {
            return 0;
        }
        // handle zero-duration period or leftover dust from integer division
        if (unlockTime >= funding.end) {
            return funding.shares.sub(funding.unlocked);
        }

        return
            (unlockTime.sub(funding.lastUpdated)).mul(funding.shares).div(
                funding.duration
            );
    }

    /**
     * @notice compute time bonus earned as a function of staking time
     * @param time length of time for which the tokens have been staked
     * @return bonus multiplier for time
     */
    function timeBonus(uint256 time) public view returns (uint256) {
        if (time >= bonusPeriod) {
            return uint256(10**BONUS_DECIMALS).add(bonusMax);
        }

        // linearly interpolate between bonus min and bonus max
        uint256 bonus = bonusMin.add(
            (bonusMax.sub(bonusMin)).mul(time).div(bonusPeriod)
        );
        return uint256(10**BONUS_DECIMALS).add(bonus);
    }

    /**
     * @notice compute CLIQ bonus as a function of usage ratio and CLIQ spent
     * @param cliq number of CLIQ token applied to bonus
     * @return multiplier value
     */
    function cliqBonus(uint256 cliq) public view returns (uint256) {
        if (cliq == 0) {
            return 10**BONUS_DECIMALS;
        }

       require(
            cliq >= 10**BONUS_DECIMALS,
            "SUPERNOVA: CLIQ amount is between 0 and 1"
        );
        uint256 buffer = uint256(5 * 10**(BONUS_DECIMALS - 2)); // 0.05
        uint256 r = ratio().add(buffer);
        uint256 x = cliq.add(buffer);

        return
            uint256(10**BONUS_DECIMALS).add(
                uint256(int128(x.mul(2**64).div(r)).logbase10())
                    .mul(10**BONUS_DECIMALS)
                    .div(2**64)
            );
    }

    /**
     * @return portion of rewards which have been boosted by CLIQ token
     */
    function ratio() public view returns (uint256) {
        if (totalRewards == 0) {
            return 0;
        }
        return totalCliqRewards.mul(10**BONUS_DECIMALS).div(totalRewards);
    }

    // SuperNova -- informational functions

    /**
     * @return total number of locked reward tokens
     */
    function totalLocked() public view returns (uint256) {
        return _lockedPool.balance();
    }

    /**
     * @return total number of unlocked reward tokens
     */
    function totalUnlocked() public view returns (uint256) {
        return _unlockedPool.balance();
    }

    /**
     * @return number of active funding schedules
     */
    function fundingCount() public view returns (uint256) {
        return fundings.length;
    }

    /**
     * @param addr address of interest
     * @return number of active stakes for user
     */
    function stakeCount(address addr) public view returns (uint256) {
        return userStakes[addr].length;
    }

    /**
     * @notice preview estimated reward distribution for unstaking
     * @param addr address of interest for preview
     * @param amount number of tokens that would be unstaked
     * @param cliq number of CLIQ tokens that would be applied
     * @return estimated reward
     * @return estimated overall multiplier
     */
    function preview(
        address addr,
        uint256 amount,
        uint256 cliq
    )
        public
        view
        returns (
            uint256,
            uint256
        )
    {
        // compute expected updates to global totals
        uint256 deltaUnlocked = 0;
        if (totalLockedShares != 0) {
            uint256 sharesToUnlock = 0;
            for (uint256 i = 0; i < fundings.length; i++) {
                sharesToUnlock = sharesToUnlock.add(_unlockable(i, block.timestamp));
            }
            deltaUnlocked = sharesToUnlock.mul(totalLocked()).div(
                totalLockedShares
            );
        }

        // no need for unstaking/rewards computation
        if (amount == 0) {
            return (0, 0);
        }

        // check unstake amount
        require(
            amount <= totalStakedFor(addr),
            "SuperNova: preview amount exceeds balance"
        );

        // compute unstake amount in shares
        uint256 shares = totalStakingShares.mul(amount).div(totalStaked());
        require(shares > 0, "SuperNova: preview amount too small");

        uint256 rawShareSeconds = 0;
        uint256 timeBonusShareSeconds = 0;

        // compute first-in-last-out, time bonus weighted, share seconds
        uint256 i = userStakes[addr].length.sub(1);
        while (shares > 0) {
            Stake storage s = userStakes[addr][i];
            uint256 time = block.timestamp.sub(s.timestamp);

            if (s.shares < shares) {
                rawShareSeconds = rawShareSeconds.add(s.shares.mul(time));
                timeBonusShareSeconds = timeBonusShareSeconds.add(
                    s.shares.mul(time).mul(timeBonus(time)).div(
                        10**BONUS_DECIMALS
                    )
                );
                shares = shares.sub(s.shares);
            } else {
                rawShareSeconds = rawShareSeconds.add(shares.mul(time));
                timeBonusShareSeconds = timeBonusShareSeconds.add(
                    shares.mul(time).mul(timeBonus(time)).div(
                        10**BONUS_DECIMALS
                    )
                );
                break;
            }
            // this will throw on underflow
            i = i.sub(1);
        }

        // apply cliq bonus
        uint256 cliqBonusShareSeconds = cliqBonus(cliq)
            .mul(timeBonusShareSeconds)
            .div(10**BONUS_DECIMALS);

        // compute rewards based on expected updates
        uint256 expectedTotalShareSeconds = totalStakingShareSeconds
            .add((block.timestamp.sub(lastUpdated)).mul(totalStakingShares))
            .add(cliqBonusShareSeconds)
            .sub(rawShareSeconds);

        uint256 reward = (totalUnlocked().add(deltaUnlocked))
            .mul(cliqBonusShareSeconds)
            .div(expectedTotalShareSeconds);

        // compute effective bonus
        uint256 bonus = uint256(10**BONUS_DECIMALS)
            .mul(cliqBonusShareSeconds)
            .div(rawShareSeconds);

        return (
            reward,
            bonus
        );
    }

    /**
     * @notice preview estimated reward distribution for unstaking for future
     * @param addr address of interest for preview
     * @param timestamp end time for reward
     * @return estimated reward
     * @return estimated overall multiplier
     */
    function previewForFuture(
        address addr,
        uint256 timestamp
    )
        public
        view
        returns (
            uint256,
            uint256
        )
    {
        // compute expected updates to global totals
        uint256 deltaUnlocked = 0;
        if (totalLockedShares != 0) {
            uint256 sharesToUnlock = 0;
            for (uint256 i = 0; i < fundings.length; i++) {
                sharesToUnlock = sharesToUnlock.add(_unlockable(i, timestamp));
            }
            deltaUnlocked = sharesToUnlock.mul(totalLocked()).div(
                totalLockedShares
            );
        }

        // no need for unstaking/rewards computation
        if (totalStakedFor(addr) == 0) {
            return (0, 0);
        }

        // compute unstake amount in shares
        uint256 shares = totalStakingShares.mul(totalStakedFor(addr)).div(totalStaked());
        require(shares > 0, "SuperNova: preview amount too small");

        uint256 rawShareSeconds = 0;
        uint256 timeBonusShareSeconds = 0;

        // compute first-in-last-out, time bonus weighted, share seconds
        uint256 i = userStakes[addr].length.sub(1);
        while (shares > 0) {
            Stake storage s = userStakes[addr][i];
            uint256 time = timestamp.sub(s.timestamp);

            if (s.shares < shares) {
                rawShareSeconds = rawShareSeconds.add(s.shares.mul(time));
                timeBonusShareSeconds = timeBonusShareSeconds.add(
                    s.shares.mul(time).mul(timeBonus(time)).div(
                        10**BONUS_DECIMALS
                    )
                );
                shares = shares.sub(s.shares);
            } else {
                rawShareSeconds = rawShareSeconds.add(shares.mul(time));
                timeBonusShareSeconds = timeBonusShareSeconds.add(
                    shares.mul(time).mul(timeBonus(time)).div(
                        10**BONUS_DECIMALS
                    )
                );
                break;
            }
            // this will throw on underflow
            i = i.sub(1);
        }

        // apply cliq bonus
        uint256 cliqBonusShareSeconds = cliqBonus(0)
            .mul(timeBonusShareSeconds)
            .div(10**BONUS_DECIMALS);

        // compute rewards based on expected updates
        uint256 expectedTotalShareSeconds = totalStakingShareSeconds
            .add((block.timestamp.sub(lastUpdated)).mul(totalStakingShares))
            .add(cliqBonusShareSeconds)
            .sub(rawShareSeconds);

        uint256 reward = (totalUnlocked().add(deltaUnlocked))
            .mul(cliqBonusShareSeconds)
            .div(expectedTotalShareSeconds);

        // compute effective bonus
        uint256 bonus = uint256(10**BONUS_DECIMALS)
            .mul(cliqBonusShareSeconds)
            .div(rawShareSeconds);

        return (
            reward,
            bonus
        );
    }

    function unlockFundInSec(uint256 timestamp) external view returns (uint256 unlockAmount) {
        unlockAmount = 0;
        uint256 fundingLen = fundings.length;
        for (uint8 i=0; i<fundingLen; i++) {
            Funding storage funding = fundings[i];
            if (timestamp < funding.end) {
                unlockAmount = unlockAmount.add((funding.shares).div(funding.duration));
            }
        }
    }

    function setBondingContract(address _bondingContract) external onlyOwner {
        bondingContract = _bondingContract;
    }
}