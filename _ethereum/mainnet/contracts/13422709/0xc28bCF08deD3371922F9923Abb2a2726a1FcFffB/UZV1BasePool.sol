// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IUZV1RewardPool.sol";
import "./IUZV1Router.sol";

import "./SharedDataTypes.sol";
import "./UZV1ProAccess.sol";

/**
 * @title UnizenBasePool
 * @author Unizen
 * @notice Base Reward pool for Unizen. Serves as base for all existing pool types,
 * to ease more pool types and reduce duplicated code.
 * The base rewards calculation approach is based on the great work of MasterChef.sol by SushiSwap.
 * https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol
 **/
abstract contract UZV1BasePool is IUZV1RewardPool, UZV1ProAccess {
    using SafeMath for uint256;
    /* === STATE VARIABLES === */
    // router address
    IUZV1Router internal _router;
    address public override factory;

    // data of user stakes and rewards
    mapping(address => SharedDataTypes.PoolStakerUser) internal _poolStakerUser;

    // pool data
    SharedDataTypes.PoolData internal _poolData;

    // total rewards left
    uint256 internal _totalRewardsLeft;

    modifier onlyFactoryOrOwner() {
        require(
            _msgSender() == factory || _msgSender() == owner(),
            "ONLY_FACTORY_OR_OWNER"
        );
        _;
    }

    function initialize(address _newRouter, address _accessToken)
        public
        virtual
        override
        initializer
    {
        UZV1ProAccess.initialize(_accessToken);
        _router = IUZV1Router(_newRouter);
        emit PoolInitiated();
    }

    function setFactory(address _factory) external override onlyOwner {
        factory = _factory;
    }

    function transferOwnership(address _newOwner)
        public
        override(IUZV1RewardPool, OwnableUpgradeable)
        onlyOwner
    {
        OwnableUpgradeable.transferOwnership(_newOwner);
    }

    /* === VIEW FUNCTIONS === */
    function getUserPoolStake(address _user)
        public
        view
        virtual
        override
        returns (SharedDataTypes.PoolStakerUser memory)
    {
        return _poolStakerUser[_user];
    }

    function getPendingRewards(address _user)
        external
        view
        virtual
        override
        returns (uint256 reward)
    {
        return _getPendingRewards(_user);
    }

    /**
     * @dev  Calculates the current pending reward amounts of a user
     * @param _user The user to check
     *
     * @return reward uint256 pending amount of user rewards
     **/
    function _getPendingRewards(address _user)
        internal
        view
        returns (uint256 reward)
    {
        uint256 _totalRewards = _getTotalRewards(_user);
        return
            _totalRewards > _poolStakerUser[_user].totalSavedRewards
                ? _totalRewards.sub(_poolStakerUser[_user].totalSavedRewards)
                : 0;
    }

    /**
     * @dev  Calculates the current total reward amounts of a user
     * @param _user The user to check
     *
     * @return reward uint256 total amount of user rewards
     **/
    function _getTotalRewards(address _user)
        internal
        view
        returns (uint256 reward)
    {
        // no need to calculate, if rewards haven't started yet
        if (block.number < _poolData.startBlock) return 0;

        // get all tokens
        (
            address[] memory _allTokens,
            ,
            uint256[] memory _weights,
            uint256 _combinedWeight
        ) = _router.getAllTokens(_getLastRewardBlock());

        // loop through all active tokens and get users currently pending reward
        for (uint8 i = 0; i < _allTokens.length; i++) {
            // read user stakes for every token
            SharedDataTypes.StakeSnapshot[] memory _snapshots = _router
                .getUserStakesSnapshots(
                    _user,
                    _allTokens[i],
                    _poolData.startBlock,
                    _getLastRewardBlock()
                );

            // calculates reward for every snapshoted block period
            for (uint256 bl = 0; bl < _snapshots.length; bl++) {
                // calculate pending rewards for token and add it to total pending reward amount
                reward = reward.add(
                    _calculateTotalRewardForToken(
                        _snapshots[bl].stakedAmount,
                        _weights[i],
                        _combinedWeight,
                        _snapshots[bl].tokenTVL,
                        _snapshots[bl].endBlock.sub(_snapshots[bl].startBlock)
                    )
                );
            }
        }
    }

    /**
     * @dev  Returns whether the pool is currently active
     *
     * @return bool active status of pool
     **/
    function isPoolActive() public view virtual override returns (bool) {
        return (block.number >= _poolData.startBlock &&
            block.number <= _poolData.endBlock);
    }

    /**
     * @dev  Returns whether the pool can be payed with a token
     *
     * @return bool status if pool is payable
     **/
    function isPayable() public view virtual override returns (bool);

    /**
     * @dev  Returns whether the pool is a base or native pool
     *
     * @return bool True, if pool distributes native rewards
     **/
    function isNative() public view virtual override returns (bool);

    /**
     * @dev  Returns all relevant information of an pool, excluding the stakes
     * of users.
     *
     * @return PoolData object
     **/
    function getPoolInfo()
        external
        view
        virtual
        override
        returns (SharedDataTypes.PoolData memory)
    {
        SharedDataTypes.PoolData memory _data = _poolData;
        _data.state = getPoolState();
        return _data;
    }

    /**
     * @dev  Returns the current state of the pool. Not all states
     * are available on every pool type. f.e. payment
     *
     * @return PoolState State of the current phase
     *  * pendingStaking
     *  * staking
     *  * retired
     **/
    function getPoolState()
        public
        view
        virtual
        override
        returns (SharedDataTypes.PoolState)
    {
        // if current block is bigger than end block, return retired state
        if (block.number > _poolData.endBlock) {
            return SharedDataTypes.PoolState.retired;
        }

        // if current block is within start and end block, return staking phase
        if (
            block.number >= _poolData.startBlock &&
            block.number <= _poolData.endBlock
        ) {
            return SharedDataTypes.PoolState.staking;
        }

        // otherwise, pool is in pendingStaking state
        return SharedDataTypes.PoolState.pendingStaking;
    }

    /**
     * @dev  Returns the current state of the pool user
     *
     * @return UserPoolState State of the user for the current phase
     *  * notclaimed
     *  * claimed
     *  * rejected
     *  * missed
     **/
    function getUserPoolState()
        public
        view
        virtual
        override
        returns (SharedDataTypes.UserPoolState)
    {
        return SharedDataTypes.UserPoolState.notclaimed;
    }

    /**
     * @dev  Returns the current type of the pool
     *
     * @return uint8 id of used pool type
     **/
    function getPoolType() external view virtual override returns (uint8);

    /**
     * @dev Returns all relevant staking data for a user.
     *
     * @param _user address of user to check
     *
     * @return FlatPoolStakerUser data object, containing all information about the staking data
     *  * total tokens staked
     *  * total saved rewards (saved/withdrawn)
     *  * array with stakes for each active token
     **/
    function getUserInfo(address _user)
        public
        view
        virtual
        override
        returns (SharedDataTypes.FlatPoolStakerUser memory)
    {
        SharedDataTypes.FlatPoolStakerUser memory _userData;

        // use data from staking contract
        uint256[] memory _userStakes = _router.getUserStakes(
            _user,
            _getLastRewardBlock()
        );

        // get all tokens
        (address[] memory _allTokens, , , ) = _router.getAllTokens();

        _userData.totalSavedRewards = _poolStakerUser[_user].totalSavedRewards;
        _userData.pendingRewards = _getPendingRewards(_user);

        _userData.amounts = new uint256[](_allTokens.length);
        _userData.tokens = new address[](_allTokens.length);

        for (uint8 i = 0; i < _allTokens.length; i++) {
            _userData.tokens[i] = _allTokens[i];
            _userData.amounts[i] = _userStakes[i];
        }
        _userData.state = getPoolState();
        _userData.userState = getUserPoolState();

        return _userData;
    }

    /**
     * @dev  Returns whether the pool pays out any rewards. Usually true for onchain and
     * false of off-chain reward pools.
     *
     * @return bool True if the user can receive rewards
     **/
    function canReceiveRewards() external view virtual override returns (bool);

    /**
     * @dev  Returns the rewards that are left on the pool. This can be different, based
     * on the type of pool. While basic reward pools will just return the reward token balance,
     * off-chain pools will just store virtual allocations for users and incubators have different
     * returns, based on their current pool state
     *
     * @return uint256 Amount of rewards left
     **/
    function getAmountOfOpenRewards()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _totalRewardsLeft;
    }

    /**
     * @dev Returns the start block for staking
     * @return uint256 Staking start block number
     **/
    function getStartBlock() public view virtual override returns (uint256) {
        return _poolData.startBlock;
    }

    /**
     * @dev Returns the end block for staking
     * @return uint256 Staking end block number
     **/
    function getEndBlock() public view virtual override returns (uint256) {
        return _poolData.endBlock;
    }

    /**
     * @dev Returns start and end blocks for
     * all existing stages of the pool
     * @return uint256[] Array with all block numbers. Each phase always has startBlock, endBlock
     */
    function getTimeWindows()
        external
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256[] memory timeWindows = new uint256[](2);
        timeWindows[0] = getStartBlock();
        timeWindows[1] = getEndBlock();
        return timeWindows;
    }

    /* === MUTATING FUNCTIONS === */
    /// user functions
    function pay(address _user, uint256 _amount)
        external
        virtual
        override
        onlyRouterOrProAccess(_msgSender())
        returns (uint256 refund)
    {
        revert();
    }

    function claimRewards(address _user)
        external
        virtual
        override
        whenNotPaused
        onlyRouterOrProAccess(_msgSender())
    {
        _claimRewards(_user);
    }

    function _claimRewards(address _user) internal virtual {
        uint256 _pendingRewards = _getPendingRewards(_user);

        // check if there are pending rewards
        if (_pendingRewards > 0) {
            // claim rewards
            _safeClaim(_user, _pendingRewards);
        }
    }

    /**
     * @dev  Allows the user to set a custom native address as receiver of rewards
     * as these rewards will be distributed off-chain.
     *
     * @param _user address of the user, we want to update
     * @param _receiver string users native address, where rewards will be sent to
     **/
    function setNativeAddress(address _user, string calldata _receiver)
        external
        override
        onlyRouterOrProAccess(_msgSender())
    {
        require(isNative() == true, "NO_NATIVE_ADDR_REQ");
        require(_user != address(0), "ZERO_ADDRESS");
        require(bytes(_receiver).length > 0, "EMPTY_RECEIVER");
        // if sender is not router, sender and user have to
        // be identical
        if (_msgSender() != address(_router)) {
            require(_msgSender() == _user, "FORBIDDEN");
        }

        _poolStakerUser[_user].nativeAddress = _receiver;
    }

    /**
     * @dev Returns the users current address as string, or the user provided
     * native address, if the pool is a native reward pool
     *
     * @param user address of the user
     * @return receiverAddress string of the users receiving address
     */
    function getUserReceiverAddress(address user)
        external
        view
        override
        returns (string memory receiverAddress)
    {
        require(user != address(0), "ZERO_ADDRESS");
        receiverAddress = (isNative() == true)
            ? _poolStakerUser[user].nativeAddress
            : _addressToString(user);
    }

    // helpers to convert address to string
    // https://ethereum.stackexchange.com/questions/72677/convert-address-to-string-after-solidity-0-5-x
    function _addressToString(address _addr)
        internal
        pure
        returns (string memory)
    {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(51);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    /**
     * @dev Calculates the last reward block
     * @return uint256 Last reward block (block.number or _poolData.endBlock)
     **/
    function _getLastRewardBlock() internal view virtual returns (uint256) {
        return
            (block.number <= _poolData.endBlock)
                ? block.number
                : _poolData.endBlock;
    }

    /**
     * @dev  Safety function that takes care of claiming amounts that
     * exceed the reward that is left, in case there is a slight offset
     * due to rounding issues.
     *
     * @param _user The user we want to send rewards to
     * @param _amount The amount of rewards that should be claimed / sent
     **/
    function _safeClaim(address _user, uint256 _amount)
        internal
        virtual
        returns (uint256)
    {
        uint256 _realAmount = (_amount <= _totalRewardsLeft)
            ? _amount
            : _totalRewardsLeft;
        require(_realAmount > 0, "ZERO_REWARD_AMOUNT");

        _poolStakerUser[_user].totalSavedRewards = _poolStakerUser[_user]
            .totalSavedRewards
            .add(_realAmount);
        _totalRewardsLeft = _totalRewardsLeft.sub(_realAmount);

        emit RewardClaimed(_user, _realAmount);
        return _realAmount;
    }

    function _rewardsForToken(
        uint256 _weight,
        uint256 _combinedWeight,
        uint256 _tvl,
        uint256 _blocks
    ) internal view returns (uint256) {
        uint256 _reward = _blocks
            .mul(_poolData.rewardsPerBlock)
            .mul(_weight)
            .div(_combinedWeight);
        if (_tvl > 0) {
            return _reward.mul(1e18).div(_tvl);
        } else {
            return 0;
        }
    }

    function _calculateTotalRewardForToken(
        uint256 _userStakes,
        uint256 _weight,
        uint256 _combinedWeight,
        uint256 _tvl,
        uint256 _blocks
    ) internal view returns (uint256 reward) {
        uint256 _rewardsPerShare;

        // we only need to calculate this, if the user holds any
        // amount of this token
        if (_userStakes > 0) {
            // check if we need to calculate the rewards for more than the current block
            if (_tvl > 0) {
                // calculate the rewards per share
                _rewardsPerShare = _rewardsForToken(
                    _weight,
                    _combinedWeight,
                    _tvl,
                    _blocks
                );
                // check if there is any reward to calculate
                if (_rewardsPerShare > 0) {
                    // get the current reward for users stakes
                    reward = _userStakes.mul(_rewardsPerShare).div(1e18);
                }
            }
        }
    }

    /// control functions
    /**
     * @dev Withdrawal function to remove payments, leftover rewards or tokens sent by accident, to the owner
     *
     * @param _tokenAddress address of token to withdraw
     * @param _amount amount of tokens to withdraw, 0 for all
     */
    function withdrawTokens(address _tokenAddress, uint256 _amount)
        external
        override
        onlyFactoryOrOwner
    {
        require(_tokenAddress != address(0), "ZERO_ADDRESS");

        IERC20 _token = IERC20(_tokenAddress);
        uint256 _balance = _token.balanceOf(address(this));
        require(_balance > 0, "NO_TOKEN_BALANCE");

        uint256 _amountToWithdraw = (_amount > 0 && _amount <= _balance)
            ? _amount
            : _balance;

        SafeERC20.safeTransfer(_token, owner(), _amountToWithdraw);
    }

    /**
     * @dev Updates the start / endblock of the staking window. Also updated the rewards
     * per block based on the new timeframe. Use with caution: this function can result
     * in unexpected issues, if used during an active staking window.
     *
     * @param _startBlock start of the staking window
     * @param _endBlock end of the staking window
     */
    function setStakingWindow(uint256 _startBlock, uint256 _endBlock)
        public
        virtual
        override
        onlyFactoryOrOwner
    {
        require(_endBlock > _startBlock, "INVALID_END_BLOCK");
        require(_startBlock > 0, "INVALID_START_BLOCK");
        require(_endBlock > 0, "INVALID_END_BLOCK");
        // start block cant be in the past
        require(_startBlock >= block.number, "INVALID_START_BLOCK");

        _poolData.startBlock = _startBlock;
        _poolData.endBlock = _endBlock;

        // calculate rewards per block
        _poolData.rewardsPerBlock = _poolData.totalRewards.div(
            _poolData.endBlock.sub(_poolData.startBlock)
        );
    }

    /**
     * @dev  Updates the whole pool meta data, based on the new pool input object
     * This function should be used with caution, as it could result in unexpected
     * issues on the calculations. Ideally only used during waiting state
     *
     * @param _inputData object containing all relevant pool information
     **/
    function setPoolData(SharedDataTypes.PoolInputData calldata _inputData)
        external
        virtual
        override
        onlyFactoryOrOwner
    {
        // set pool data
        _poolData.totalRewards = _inputData.totalRewards;
        _poolData.token = _inputData.token;
        _poolData.poolType = _inputData.poolType;
        _poolData.info = _inputData.tokenInfo;

        _totalRewardsLeft = _inputData.totalRewards;

        // set staking window and calculate rewards per block
        setStakingWindow(_inputData.startBlock, _inputData.endBlock);

        emit PoolDataSet(
            _poolData.token,
            _poolData.totalRewards,
            _poolData.startBlock,
            _poolData.endBlock
        );
    }

    /* === MODIFIERS === */
    modifier onlyRouter() {
        require(_msgSender() == address(_router), "FORBIDDEN: ROUTER");
        _;
    }

    modifier onlyRouterOrProAccess(address _user) {
        if (_user != address(_router)) {
            _checkPro(_user);
        }
        _;
    }

    /* === EVENTS === */
    event PoolInitiated();

    event PoolDataSet(
        address rewardToken,
        uint256 totalReward,
        uint256 startBlock,
        uint256 endBlock
    );

    event RewardClaimed(address indexed user, uint256 amount);

    event AllocationPaid(
        address indexed user,
        address token,
        uint256 paidAmount,
        uint256 paidAllocation
    );
}
