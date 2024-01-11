// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IPool.sol";
import "./ICorePool.sol";
import "./ITokenRecipient.sol";
import "./IFactory.sol";

/**
 * @title Cart Pool Base
 *
 * @notice An abstract contract containing common logic for a core pool (permanent pool like CART/ETH or CART pool)
 *
 * @dev Deployment and initialization.
 *      Any pool deployed must be bound to the deployed pool factory (CartPoolFactory)
 *      Additionally, 3 token instance addresses must be defined on deployment:
 *          - CART token address
 *          - pool token address, it can be CART token address, CART/ETH pair address, and others
 *
 * @dev Pool weight defines the fraction of the yield current pool receives among the other pools,
 *      pool factory is responsible for the weight synchronization between the pools.
 * @dev The weight is logically 20% for CART pool and 80% for CART/ETH pool.
 *      Since Solidity doesn't support fractions the weight is defined by the division of
 *      pool weight by total pools weight (sum of all registered pools within the factory)
 * @dev For CART Pool we use 200 as weight and for CART/ETH pool - 800.
 *
 */
abstract contract CartPoolBase is IPool, ReentrancyGuard, ITokenRecipient {
    
    /// @dev Link to CART STREET ERC20 Token instance
    address public immutable override CART;

    /// @dev Token holder storage, maps token holder address to their data record
    mapping(address => User) public users;

    /// @dev Link to the pool factory CartPoolFactory addresss
    address public immutable factory;

    /// @dev Link to the pool token instance, for example CART or CART/ETH pair
    address public immutable override poolToken;

    /// @dev Pool weight, 200 for CART pool or 800 for CART/ETH
    uint256 public override weight;

    /// @dev Block number of the last yield distribution event
    uint256 public override lastYieldDistribution;

    /// @dev Used to calculate yield rewards
    /// @dev This value is different from "reward per token" used in locked pool
    /// @dev Note: stakes are different in duration and "weight" reflects that
    uint256 public override yieldRewardsPerWeight;

    /// @dev Used to calculate yield rewards, keeps track of the tokens weight locked in staking
    uint256 public override usersLockingWeight;

    /// @dev Support for specified NFT whitelist address, True representing this NFT can be staked
    mapping(address => uint256) public supportNTF;

    /**
     * @dev Stake weight is proportional to deposit amount and time locked, precisely
     *      "deposit amount wei multiplied by (fraction of the year locked plus one)"
     * @dev To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
     *      weight is stored multiplied by 1e24 constant, as an integer
     * @dev Corner case 1: if time locked is zero, weight is deposit amount multiplied by 1e24
     * @dev Corner case 2: if time locked is one year, fraction of the year locked is one, and
     *      weight is a deposit amount multiplied by 2 * 1e24
     */
    uint256 public weightMultiplier;

    /**
     * @dev Rewards per weight are stored multiplied by 1e48, as integers.
     */
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e48;

    /**
     * @dev We want to get deposits batched but not one by one, thus here is define the size of each batch.
     */
    uint256 internal constant DEPOSIT_BATCH_SIZE  = 20;

    /**
     * @dev Fired in _stake() and stake()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _from token holder address, the tokens will be returned to that address
     * @param amount amount of tokens staked
     */
    event Staked(address indexed _by, address indexed _from, uint256 amount);


    /**
     * @dev Fired in _unstake() and unstake()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _to an address which received the unstaked tokens, usually token holder
     * @param amount amount of tokens unstaked
     */
    event Unstaked(address indexed _by, address indexed _to, uint256 amount);

    /**
     * @dev Fired in _sync(), sync() and dependent functions (stake, unstake, etc.)
     *
     * @param _by an address which performed an operation
     * @param yieldRewardsPerWeight updated yield rewards per weight value
     * @param lastYieldDistribution usually, current block number
     */
    event Synchronized(address indexed _by, uint256 yieldRewardsPerWeight, uint256 lastYieldDistribution);

    /**
     * @dev Fired in _processRewards(), processRewards() and dependent functions (stake, unstake, etc.)
     *
     * @param _by an address which performed an operation
     * @param _to an address which claimed the yield reward
     * @param amount amount of yield paid
     */
    event YieldClaimed(address indexed _by, address indexed _to, uint256 amount);

    /**
     * @dev Fired in setWeight()
     *
     * @param _fromVal old pool weight value
     * @param _toVal new pool weight value
     */
    event PoolWeightUpdated(uint256 _fromVal, uint256 _toVal);

    /**
     * @dev Fired in _emergencyWithdraw()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param amount amount of tokens withdraw
     */
    event EmergencyWithdraw(address indexed _by, uint256 amount);

    /**
     * @dev Overridden in sub-contracts to construct the pool
     *
     * @param _cart CART ERC20 Token IlluviumERC20 address
     * @param _factory Pool factory CartPoolFactory address
     * @param _poolToken token the pool operates on, for example CART or CART/ETH pair
     * @param _weight number representing a weight of the pool, actual weight fraction
     *      is calculated as that number divided by the total pools weight and doesn't exceed one
     */
    constructor(
        address _cart,
        address _factory,
        address _poolToken,
        uint256 _weight
    ) {
        // verify the inputs are set
        require(_cart != address(0), "cart token address not set");
        require(_factory != address(0), "CART Pool fct address not set");
        require(_poolToken != address(0), "pool token address not set");
        require(_weight > 0, "pool weight not set");

        // verify CartPoolFactory instance supplied
        require(
            IFactory(_factory).FACTORY_UID() == 0xb77099a6d99df5887a6108e413b3c6dfe0c11a1583c9d9b3cd08bfb8ca996aef,
            "unexpected FACTORY_UID"
        );

        // save the inputs into internal state variables
        CART = _cart;
        factory = _factory;
        poolToken = _poolToken;
        weight = _weight;
        weightMultiplier = 1e24;
    }

    /**
     * @notice Returns total staked token balance for the given address
     *
     * @param _user an address to query balance for
     * @return total staked token balance
     */
    function balanceOf(address _user) external view override returns (uint256) {
        // read specified user token amount and return
        return users[_user].tokenAmount;
    }

    /**
     * @notice Returns origin information on the given deposit for the given address
     *
     * @dev See getDepositsLength
     *
     * @param _user an address to query deposit for
     * @param _depositId zero-indexed deposit ID for the address specified
     * @return deposit info as Deposit structure
     */
    function getOriginDeposit(address _user, uint256 _depositId) external view override returns (Deposit memory) {
        // read deposit at specified index and return
        return users[_user].deposits[_depositId];
    } 

    /**
     * @notice Returns number of deposits for the given address. Allows iteration over deposits.
     *
     * @dev See getDeposit
     *
     * @param _user an address to query deposit length for
     * @return number of deposits for the given address
     */
    function getDepositsLength(address _user) external view override returns (uint256) {
        // read deposits array length and return
        return users[_user].deposits.length;
    }
    
    /**
     * @notice Returns weight of NFT
     *
     * @param _nftAddress an address to query weight of NFT
     * @return weight of NFT
     */
    function getNFTWeight(address _nftAddress) external view returns (uint256) {
        // return weight of NFT
        return supportNTF[_nftAddress];
    }

    /**
     * @notice Returns structure of user
     *
     * @param _user an address to query deposit length for
     * @return user data structure
     */
    function getUser(address _user) external view returns (User memory) {
        return users[_user];
    }

    /**
     * @notice TokenRecipient. if got cart tokens, it will receive and stake.
     *
     * @param _staker an address which stakes tokens and which will receive them back
     * @param _amount amount of tokens to stake
     * @param _data include stake period, NFT address, NFT Token ID.
     */
    function tokensReceived(address _staker, uint _amount, bytes calldata _data) external override nonReentrant returns (bool) {
        require(msg.sender == CART, "must from cart");
        require(_data.length == 60, "length of bytes error");

        // stake period as unix timestamp; zero means no locking
        uint64 _lockPeriod = uint64(toUint(_data, 0));
        address _nftAddress = address(toBytes20(_data, 20));
        uint _nftTokenId = toUint(_data, 40);
    
        _stake(_staker, _amount, _lockPeriod, _nftAddress, _nftTokenId);
        return true;
    }
    
    /**
     * @notice to 20 bytes
     *
     * @param _b bytes 
     * @param _offset initial position to processing
     */
    function toBytes20(bytes memory _b, uint _offset) private pure returns (bytes20) {
        bytes20 out;
        for (uint i = 0; i < 20; i++) {
        out |= bytes20(_b[_offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    /**
     * @notice bytes to uint
     *
     * @param _b bytes 
     * @param _offset initial position to processing
     */
    function toUint(bytes memory _b, uint _offset) private pure returns (uint) {
        uint out;
        for(uint i = 0; i < 20; i++){
        out = out + uint8(_b[_offset + i])*(2**(8*(20-(i+1))));
        }
        return out;
    }

    /**
     * @notice Stakes specified amount of tokens for the specified amount of time,
     *      and pays pending yield rewards if any
     *
     * @dev Requires amount to stake to be greater than zero
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     * @param _amount amount of tokens to stake
     * @param _lockPeriod stake period as unix timestamp; zero means no locking
     * @param _nftAddress supported nft address
     * @param _nftTokenId users hold nft tokenId
     */
    function stake (
        uint256 _amount,
        uint64 _lockPeriod,
        address _nftAddress,
        uint256 _nftTokenId
    ) external override nonReentrant {
        // transfer `_amount`
        transferPoolTokenFrom(msg.sender, address(this), _amount);
        // delegate call to an internal function
        _stake(msg.sender, _amount, _lockPeriod, _nftAddress, _nftTokenId);
    }

    /**
     * @notice Unstakes specified amount of tokens, and pays pending yield rewards if any
     *
     * @dev Requires amount to unstake to be greater than zero
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     * @param _depositId deposit ID to unstake from, zero-indexed
     * @param _amount amount of tokens to unstake
     */
    function unstake(
        uint256 _depositId,
        uint256 _amount
    ) external override nonReentrant {
        // delegate call to an internal function
        _unstake(msg.sender, _depositId, _amount);
    }

    /**
     * @notice Service function to synchronize pool state with current time
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      at least one block passes between synchronizations
     * @dev Executed internally when staking, unstaking, processing rewards in order
     *      for calculations to be correct and to reflect state progress of the contract
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     */
    function sync() external override {
        // delegate call to an internal function
        _sync();
    }

    /**
     * @notice Service function to calculate and pay pending yield rewards to the sender
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      executed by deposit holder and when at least one block passes from the
     *      previous reward processing
     * @dev Executed internally when staking and unstaking, executes sync() under the hood
     *      before making further calculations and payouts
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     */
    function processRewards() external virtual override nonReentrant {
        // delegate call to an internal function
        _processRewards(msg.sender, true);
    }

    /**
     * @dev Executed by the factory to modify pool weight; the factory is expected
     *      to keep track of the total pools weight when updating
     *
     * @dev Set weight to zero to disable the pool
     *
     * @param _weight new weight to set for the pool
     */
    function setWeight(uint256 _weight) external override {
        // verify function is executed by the factory
        require(msg.sender == factory, "access denied");

        // emit an event logging old and new weight values
        emit PoolWeightUpdated(weight, _weight);

        // set the new weight value
        weight = _weight;
    }

    /**
     * @dev Executed by the factory to modify NFTWeight
     *
     * @dev Set new weight to the NFT address
     *
     * @param _nftAddress address of NFT
     * @param _nftWeight weight of NFT
     */
    function NFTWeightUpdated(address _nftAddress, uint256 _nftWeight) external {
        // verify function is executed by the factory
        require(msg.sender == factory, "access denied");
        // set new weight of NFT
        supportNTF[_nftAddress] = _nftWeight;
    }

    /**
     * @dev Executed by the factory to modify weightMultiplier
     *
     * @dev Set new weight to weightMultiplier
     *
     * @param _newWeightMultiplier new weightMultiplier
     */
    function setWeightMultiplierbyFactory(uint256 _newWeightMultiplier) external {
        // verify function is executed by the factory
        require(msg.sender == factory, "access denied");
        // set the new weight multiplier
        weightMultiplier = _newWeightMultiplier;
    }

    /**
     * @dev Similar to public pendingYieldRewards, but performs calculations based on
     *      current smart contract state only, not taking into account any additional
     *      time/blocks which might have passed
     *
     * @param _staker an address to calculate yield rewards value for
     * @return pending calculated yield reward value for the given address
     */
    function _pendingYieldRewards(address _staker) internal view returns (uint256 pending) {
        // read user data structure into memory
        User memory user = users[_staker];

        // and perform the calculation using the values read
        return weightToReward(user.totalWeight, yieldRewardsPerWeight) - user.subYieldRewards;
    }

    /**
     * @dev Used internally, mostly by children implementations, see stake()
     *
     * @param _staker an address which stakes tokens and which will receive them back
     * @param _amount amount of tokens to stake
     * @param _lockPeriod stake period as unix timestamp; zero means no locking 
     * @param _nftAddress supported nft address, zero means no NFT token
     * @param _nftTokenId users hold nft tokenId, zero means no NFT token
     */
    function _stake(
        address _staker,
        uint256 _amount,
        uint64 _lockPeriod,
        address _nftAddress,
        uint256 _nftTokenId
    ) internal virtual {
        // validate the inputs

        require(_amount > 0, "zero amount");
        require(_lockPeriod == 0 || _lockPeriod <= 365 days,"invalid lock interval");
 
        // update smart contract state
        _sync();

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // process current pending rewards if any
        if (user.tokenAmount > 0) {
            _processRewards(_staker, false);
        }

        // if length of deposits is zero, then push zero value of unlocked deposit
        if (user.deposits.length == 0) {
            // create zero value of unlocked deposit and save the deposit (append it to deposits array)
            Deposit memory unlockedDeposit =
                Deposit({
                    tokenAmount: 0,
                    weight: 0,
                    lockedFrom: 0,
                    lockedUntil: 0,
                    isYield: false
                });
            user.deposits.push(unlockedDeposit);
        }

        // zero value for `_lockPeriod` means "no locking" and leads to zero values
        uint64 lockFrom = uint64(now256());
        uint64 lockPeriod = _lockPeriod;

        // stakeWeight
        uint256 stakeWeight = ((lockPeriod * weightMultiplier) / 365 days + weightMultiplier) * _amount;

        // makes sure stakeWeight is valid
        require(stakeWeight > 0, "invalid stakeWeight");    

        // if the user has new unlocked stake, deposit will merge it
        if (lockPeriod == 0) {
            // init weight of NFT
            uint nft_weight = 0;
            // if the user hold the right NFT tokenId, nft_weight will increase
            if (_nftTokenId != 0 && _nftAddress != address(0) ) {
                require(IERC721(_nftAddress).ownerOf(_nftTokenId) == msg.sender, "the NFT tokenId doesn't match the user");
                nft_weight = supportNTF[_nftAddress];
            }
            
            // old stakeWeight
            uint256 oldStakeWeight = user.deposits[0].weight;
            // new stakeWeight, only check user's NFT info for unlocked deposit
            uint256 newStakeWeight = oldStakeWeight + _amount * weightMultiplier + nft_weight * weightMultiplier;
            // the stake is currently unlocked 
            user.deposits[0].tokenAmount += _amount;
            user.deposits[0].weight = newStakeWeight;
            user.deposits[0].lockedFrom = 0;

            // update user record
            user.tokenAmount += _amount;
            user.totalWeight = (user.totalWeight - oldStakeWeight + newStakeWeight);
            user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

            // update global variable
            usersLockingWeight = (usersLockingWeight - oldStakeWeight + newStakeWeight);
        } else {
            // the stake is currently locking
            // create and save the deposit (append it to deposits array)
            Deposit memory deposit =
                Deposit({
                    tokenAmount: _amount,
                    weight: stakeWeight,
                    lockedFrom: lockFrom,
                    lockedUntil: lockFrom + lockPeriod,
                    isYield: false
                });
            // deposit ID is an index of the deposit in `deposits` array
            user.deposits.push(deposit);

            // update user record
            user.tokenAmount += _amount;
            user.totalWeight += stakeWeight;
            user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

            // update global variable
            usersLockingWeight += stakeWeight;
        }

        // emit an event
        emit Staked(msg.sender, _staker, _amount);
    }

    /**
     * @dev Used internally, mostly by children implementations, see unstake()
     *
     * @param _staker an address which unstakes tokens (which previously staked them)
     * @param _depositId deposit ID to unstake from, zero-indexed
     * @param _amount amount of tokens to unstake
     */
    function _unstake(
        address _staker,
        uint256 _depositId,
        uint256 _amount
    ) internal virtual {
        // verify an amount is set
        require(_amount > 0, "zero amount");

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // get a link to the corresponding deposit, we may write to it later
        Deposit storage stakeDeposit = user.deposits[_depositId];
        // deposit structure may get deleted, so we save isYield flag to be able to use it
        bool isYield = stakeDeposit.isYield;

        // verify available balance
        // if staker address ot deposit doesn't exist this check will fail as well
        require(stakeDeposit.tokenAmount >= _amount, "amount exceeds stake");

        // update smart contract state
        _sync();
        // and process current pending rewards if any
        _processRewards(_staker, false);

        // recalculate deposit weight
        uint256 previousWeight = stakeDeposit.weight;
        uint256 newWeight =
            (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) * weightMultiplier) /
                365 days +
                weightMultiplier) * (stakeDeposit.tokenAmount - _amount);

        // update the deposit, or delete it if its depleted
        if (stakeDeposit.tokenAmount == _amount) {
            //set all deposits value to zero (default)
            delete user.deposits[_depositId];
        } else {
            stakeDeposit.tokenAmount -= _amount;
            stakeDeposit.weight = newWeight;
        }

        // update user record
        user.tokenAmount -= _amount;
        user.totalWeight = user.totalWeight - previousWeight + newWeight;
        user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

        // update global variable
        usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

        // if the deposit was created by the pool itself as a yield reward
        if (isYield) {
            user.rewardAmount -= _amount;
            // mint the yield via the factory
            IFactory(factory).mintYieldTo(msg.sender, _amount);
        } else {
            // otherwise just return tokens back to holder, staking for a year
            transferPoolToken(msg.sender, _amount);
        }

        // emit an event
        emit Unstaked(msg.sender, _staker, _amount);
    }

    /**
     * @notice Emergency withdraw specified amount of tokens
     *
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     */
    function emergencyWithdraw() external nonReentrant {
        require(IFactory(factory).totalWeight() == 0, "totalWeight != 0");

        // delegate call to an internal function
        _emergencyWithdraw(msg.sender);
    }

    /**
     * @dev Used internally, mostly by children implementations, see emergencyWithdraw()
     *
     * @param _staker an address which unstakes tokens (which previously staked them)
     */
    function _emergencyWithdraw(
        address _staker
    ) internal virtual {
        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];

        uint256 totalWeight = user.totalWeight ;
        uint256 amount = user.tokenAmount;
        uint256 reward = user.rewardAmount;

        // update user record
        user.tokenAmount = 0;
        user.rewardAmount = 0;
        user.totalWeight = 0;
        user.subYieldRewards = 0;

        // delete entire array directly
        delete user.deposits;

        // update global variable
        usersLockingWeight = usersLockingWeight - totalWeight;

        // just return tokens back to holder
        transferPoolToken(msg.sender, amount - reward);
        // mint the yield via the factory
        IFactory(factory).mintYieldTo(msg.sender, reward);

        emit EmergencyWithdraw(msg.sender, amount);
    }

    /**
     * @dev Used internally, mostly by children implementations, see sync()
     *
     * @dev Updates smart contract state (`yieldRewardsPerWeight`, `lastYieldDistribution`),
     */
    function _sync() internal virtual {

        // Initialize lastYieldDistribution when the first stake
        if (lastYieldDistribution == 0) {
            lastYieldDistribution = blockNumber();
        }
        // check bound conditions and if these are not met -
        // exit silently, without emitting an event
        uint256 endBlock = IFactory(factory).endBlock();
        if (lastYieldDistribution >= endBlock) {
            return;
        }
        if (blockNumber() <= lastYieldDistribution) {
            return;
        }
        // if locking weight is zero - update only `lastYieldDistribution` and exit
        if (usersLockingWeight == 0) {
            lastYieldDistribution = blockNumber();
            return;
        }

        // to calculate the reward we need to know how many blocks passed, and reward per block
        uint256 currentBlock = blockNumber() > endBlock ? endBlock : blockNumber();
        uint256 blocksPassed = currentBlock - lastYieldDistribution;
        uint256 cartPerBlock = IFactory(factory).cartPerBlock();

        // calculate the reward
        uint256 cartReward = (blocksPassed * cartPerBlock * weight) / IFactory(factory).totalWeight();

        // update rewards per weight and `lastYieldDistribution`
        yieldRewardsPerWeight += rewardToWeight(cartReward, usersLockingWeight);
        lastYieldDistribution = currentBlock;

        // emit an event
        emit Synchronized(msg.sender, yieldRewardsPerWeight, lastYieldDistribution);
    }

    /**
     * @dev Used internally, mostly by children implementations, see processRewards()
     *
     * @param _staker an address which receives the reward (which has staked some tokens earlier)
     * @param _withUpdate flag allowing to disable synchronization (see sync()) if set to false
     * @return pendingYield the rewards calculated and optionally re-staked
     */
    function _processRewards(
        address _staker,
        bool _withUpdate
    ) internal virtual returns (uint256 pendingYield) {
        // update smart contract state if required
        if (_withUpdate) {
            _sync();
        }

        // calculate pending yield rewards, this value will be returned
        pendingYield = _pendingYieldRewards(_staker);

        // if pending yield is zero - just return silently
        if (pendingYield == 0) return 0;

        // get link to a user data structure, we will write into it later
        User storage user = users[_staker];

        if (poolToken == CART) {
            // mint the yield via the factory
            IFactory(factory).mintYieldTo(_staker, pendingYield);
        } else {
            // for other pools - stake as pool
            address cartPool = IFactory(factory).getPoolAddress(CART);
            require(cartPool != address(0),"invalid cart pool address");
            ICorePool(cartPool).stakeAsPool(_staker, pendingYield);
        }

        // update users's record for `subYieldRewards` if requested
        if (_withUpdate) {
            user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);
        }

        // emit an event
        emit YieldClaimed(msg.sender, _staker, pendingYield);
    }


    /**
     * @dev Converts stake weight (not to be mixed with the pool weight) to
     *      CART reward value, applying the 10^48 division on weight
     *
     * @param _weight stake weight
     * @param rewardPerWeight CART reward per weight
     * @return reward value normalized to 10^48
     */
    function weightToReward(uint256 _weight, uint256 rewardPerWeight) public pure returns (uint256) {
        // apply the formula and return
        return (_weight * rewardPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    /**
     * @dev Converts reward CART value to stake weight (not to be mixed with the pool weight),
     *      applying the 10^12 multiplication on the reward
     *      - OR -
     * @dev Converts reward CART value to reward/weight if stake weight is supplied as second
     *      function parameter instead of reward/weight
     *
     * @param reward yield reward
     * @param rewardPerWeight reward/weight (or stake weight)
     * @return stake weight (or reward/weight)
     */
    function rewardToWeight(uint256 reward, uint256 rewardPerWeight) public pure returns (uint256) {
        // apply the reverse formula and return
        return (reward * REWARD_PER_WEIGHT_MULTIPLIER) / rewardPerWeight;
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override block number in helper test smart contracts
     *
     * @return `block.number` in mainnet, custom values in testnets (if overridden)
     */
    function blockNumber() public view virtual returns (uint256) {
        // return current block number
        return block.number;
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override time in helper test smart contracts
     *
     * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
     */
    function now256() public view virtual returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }

    /**
     * @dev Executes SafeERC20.safeTransfer on a pool token
     *
     */
    function transferPoolToken(address _to, uint256 _value) internal {
        SafeERC20.safeTransfer(IERC20(poolToken), _to, _value);
    }

    /**
     * @dev Executes SafeERC20.safeTransferFrom on a pool token
     *
     */
    function transferPoolTokenFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        SafeERC20.safeTransferFrom(IERC20(poolToken), _from, _to, _value);
    }
}