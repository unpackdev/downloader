// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IUZV1Router.sol";
import "./IUZV1Factory.sol";
import "./IUZV1Staking.sol";
import "./IUZV1RewardPool.sol";
import "./IUZV1PayableRewardPool.sol";
import "./SharedDataTypes.sol";
import "./UZV1ProAccess.sol";

/**
 * @title UnizenStakingRouter
 * @author Unizen
 * @notice Router that is used as central interaction point for reward pools
 **/
contract UZV1Router is IUZV1Router, UZV1ProAccess {
    /* === STATE VARIABLES === */
    IUZV1Factory public factory;
    IUZV1Staking public staking;

    /* === initialize function === */
    function initialize(
        address _factory,
        address _staking,
        address _accessToken
    ) public initializer {
        UZV1ProAccess.initialize(_accessToken);
        factory = IUZV1Factory(_factory);
        staking = IUZV1Staking(_staking);
    }

    /* === VIEW FUNCTIONS === */
    function getPoolStakerUser(address _user)
        external
        view
        returns (SharedDataTypes.PoolStakerUser[] memory)
    {
        address[] memory _pools = getAllPools();
        SharedDataTypes.PoolStakerUser[]
            memory poolStakerUser = new SharedDataTypes.PoolStakerUser[](
                _pools.length
            );
        for (uint256 i = 0; i < _pools.length; i++) {
            poolStakerUser[i] = IUZV1RewardPool(_pools[i]).getUserPoolStake(
                _user
            );
        }
        return poolStakerUser;
    }

    /**
     * @dev Fetches a list of pending rewards from all active reward pools
     *
     * @param _user user address to check for pending rewards
     *
     * @return address[] address list of all active pools
     * @return uint256[] amount of pending rewards for each active pool
     **/
    function getAllUserRewards(address _user)
        external
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        // fetch all pools and pool count
        address[] memory _pools = factory.getActivePools();
        uint256 i = _pools.length;
        uint256[] memory _rewards = new uint256[](i);
        if (i == 0) return (_pools, _rewards);
        // setup memory array for rewards at the size of active pools
        // loop through all pools
        while (i-- > 0) {
            // get pending rewards from pool
            _rewards[i] = IUZV1RewardPool(_pools[i]).getPendingRewards(_user);
        }

        // return pool addresses and rewards
        return (_pools, _rewards);
    }

    /**
     * @dev Fetches all active pools from the factory contract
     *
     * @return address[] list of all pool addresses
     **/
    function getAllPools() public view override returns (address[] memory) {
        return factory.getActivePools();
    }

    /**
     * @dev  Returns relevant data for active tokens from the staking contract.
     *
     * @return tokenList addresses of all active tokens
     * @return tokenTVLs tvl of each active token
     * @return weights Weight of all active tokens
     * @return combinedWeight Sum of all weights from active tokens
     **/
    function getAllTokens()
        external
        view
        override
        returns (
            address[] memory tokenList,
            uint256[] memory tokenTVLs,
            uint256[] memory weights,
            uint256 combinedWeight
        )
    {
        tokenList = staking.getActiveTokens();
        tokenTVLs = staking.getTVLs();
        (weights, combinedWeight) = staking.getTokenWeights();
    }

    /**
     * @dev  Returns relevant data for active tokens from the staking contract.
     *
     * @return tokenList addresses of all active tokens
     * @return tokenTVLs tvl of each active token on a block.number
     * @return weights Weight of all active tokens
     * @return combinedWeight Sum of all weights from active tokens
     **/
    function getAllTokens(uint256 _blocknumber)
        external
        view
        override
        returns (
            address[] memory tokenList,
            uint256[] memory tokenTVLs,
            uint256[] memory weights,
            uint256 combinedWeight
        )
    {
        tokenList = staking.getActiveTokens();
        tokenTVLs = staking.getTVLs(_blocknumber);
        (weights, combinedWeight) = staking.getTokenWeights();
    }

    /**
     * @dev  Returns current tvl for each active token
     *
     * @return _tokenTVLs tvl of each active token
     **/
    function getTVLs()
        external
        view
        override
        returns (uint256[] memory _tokenTVLs)
    {
        _tokenTVLs = staking.getTVLs();
    }

    /**
     * @dev  Returns tvl on a block.number for each active token
     *
     * @return _tokenTVLs tvl of each active token
     **/
    function getTVLs(uint256 _blocknumber)
        external
        view
        override
        returns (uint256[] memory _tokenTVLs)
    {
        _tokenTVLs = staking.getTVLs(_blocknumber);
    }

    /**
     * @dev used to calculate the users stake of the pool
     * @param _user optional user addres, if empty the sender will be used
     * @param _precision optional denominator, default to 3
     *
     * @return array with the percentage stakes of the user based on TVL of each allowed token
     *  [
     *   weightedAverage,
     *   shareOfUtilityToken,
     *   ShareOfLPToken...
     *  ]
     *
     **/
    function getUserTVLShare(address _user, uint256 _precision)
        external
        view
        override
        returns (uint256[] memory)
    {
        return staking.getUserTVLShare(_user, _precision);
    }

    /**
     * @dev Helper function to fetch all existing data to an address
     *
     * @return array of token addresses
     * @return array of users staked amount for each token
     * @return ZCXHT staked amount
     **/
    function getStakingUserData(address _user)
        external
        view
        override
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        )
    {
        return staking.getUserData(_user);
    }

    /**
     * @dev  Returns the weight of all active tokens, including the sum of all tokens
     * combined from the staking contract.
     *
     * @return weights Weight of all active tokens
     * @return combinedWeight Sum of all weights from active tokens
     **/
    function getTokenWeights()
        external
        view
        override
        returns (uint256[] memory weights, uint256 combinedWeight)
    {
        (weights, combinedWeight) = staking.getTokenWeights();
    }

    /**
     * @dev  Returns current tvl of the token, as well as a list
     * of tvl for each active token by the user
     *
     * @param _user Address of the user
     *
     * @return userStakes user tvl list for each active token
     **/
    function getUserStakes(address _user)
        external
        view
        override
        returns (uint256[] memory)
    {
        return staking.getUserStakes(_user);
    }

    /**
     * @dev  Returns tvl of the token on a block.number, as well as a list
     * of tvl for each active token by the user
     *
     * @param _user Address of the user
     *
     * @return userStakes user tvl list for each active token
     **/
    function getUserStakes(address _user, uint256 _blocknumber)
        external
        view
        override
        returns (uint256[] memory)
    {
        return staking.getUserStakes(_user, _blocknumber);
    }

    /**
     * @dev  Returns all block number snapshots for an specific user and token
     *
     * @param _user Address of the user
     * @param _token Address of the token
     * @param _startBlock Start block to search for snapshots
     * @param _endBlock End block to search for snapshots
     *
     * @return snapshots snapshoted data grouped by stakes
     **/
    function getUserStakesSnapshots(
        address _user,
        address _token,
        uint256 _startBlock,
        uint256 _endBlock
    )
        external
        view
        override
        returns (SharedDataTypes.StakeSnapshot[] memory snapshots)
    {
        return
            staking.getUserStakesSnapshots(
                _user,
                _token,
                _startBlock,
                _endBlock
            );
    }

    /**
     * @dev  Returns whether the pool pays out any rewards. Usually true for onchain and
     * false of off-chain reward pools.
     *
     * @param _pool Address of the reward pool
     *
     * @return bool True if the user can receive rewards
     **/
    function canReceiveRewards(address _pool)
        external
        view
        override
        returns (bool)
    {
        return IUZV1RewardPool(_pool).canReceiveRewards();
    }

    /**
     * @dev  Returns whether the pool is a base or native pool
     *
     * @param _pool Address of the reward pool
     *
     * @return bool True, if pool distributes native rewards
     **/
    function isPoolNative(address _pool) external view override returns (bool) {
        return IUZV1RewardPool(_pool).isNative();
    }

    /**
     * @dev  Returns the current state of the pool. Not all states
     * are available on every pool type. f.e. payment
     *
     * @param _pool Address of the reward pool
     *
     * @return PoolState State of the current phase
     *  * pendingStaking
     *  * staking
     *  * pendingPayment
     *  * payment
     *  * pendingDistribution
     *  * distribution
     *  * retired
     **/
    function getPoolState(address _pool)
        external
        view
        override
        returns (SharedDataTypes.PoolState)
    {
        return IUZV1RewardPool(_pool).getPoolState();
    }

    /**
     * @dev  Returns the current type of the pool
     *
     * @param _pool Address of the reward pool
     *
     * @return uint8 id of used pool type
     **/
    function getPoolType(address _pool) external view override returns (uint8) {
        return IUZV1RewardPool(_pool).getPoolType();
    }

    /**
     * @dev  Returns all relevant information of an pool, excluding the stakes
     * of users.
     *
     * @param _pool Address of the reward pool
     *
     * @return PoolData object
     **/
    function getPoolInfo(address _pool)
        external
        view
        override
        returns (SharedDataTypes.PoolData memory)
    {
        return IUZV1RewardPool(_pool).getPoolInfo();
    }

    /**
     * @dev Returns start and end blocks for
     * all existing stages of the pool
     *
     * @param _pool Address of the reward pool
     * @return uint256[] Array with all block numbers. Each phase always has startBlock, endBlock
     */
    function getTimeWindows(address _pool)
        external
        view
        override
        returns (uint256[] memory)
    {
        return IUZV1RewardPool(_pool).getTimeWindows();
    }

    /**
     * @dev Returns the users current address as string, or the user provided
     * native address, if the pool is a native reward pool
     *
     * @param _pool Address of the reward pool
     * @param _user address of the user
     * @return receiverAddress string of the users receiving address
     */
    function getPoolUserReceiverAddress(address _pool, address _user)
        external
        view
        override
        returns (string memory receiverAddress)
    {
        return IUZV1RewardPool(_pool).getUserReceiverAddress(_user);
    }

    /**
     * @dev Returns all relevant staking data for a user.
     *
     * @param _pool Address of the reward pool
     * @param _user address of user to check
     *
     * @return FlatPoolStakerUser data object, containing all information about the staking data
     *  * total tokens staked
     *  * total saved rewards (saved/withdrawn)
     *  * array with stakes for each active token
     **/
    function getPoolUserInfo(address _pool, address _user)
        external
        view
        override
        returns (SharedDataTypes.FlatPoolStakerUser memory)
    {
        return IUZV1RewardPool(_pool).getUserInfo(_user);
    }

    function getTotalPriceForPurchaseableTokens(address _pool, address _user)
        external
        view
        override
        returns (uint256)
    {
        return
            IUZV1PayableRewardPool(_pool).getTotalPriceForPurchaseableTokens(
                _user
            );
    }

    /* === MUTATING FUNCTIONS === */
    /// user functions

    /**
     * @dev  Allows claiming all pending rewards of active pools.
     **/
    function claimAllRewards()
        external
        override
        whenNotPaused
        onlyPro(_msgSender())
    {
        address[] memory _allPools = factory.getActivePools();
        uint256 i = _allPools.length;
        require(i > 0, "NO_ACTIVE_POOL");
        while (i-- > 0) {
            if (
                IUZV1RewardPool(_allPools[i]).getPendingRewards(_msgSender()) >
                0
            ) {
                IUZV1RewardPool(_allPools[i]).claimRewards(_msgSender());
            }
        }
    }

    /**
     * @dev  Allows claiming rewards of a specific pool
     * @param _pool address of the pool, where the user wants to claim rewards from
     * @return bool success of the reward claim
     **/
    function claimReward(address _pool)
        external
        override
        whenNotPaused
        onlyPro(_msgSender())
        returns (bool)
    {
        IUZV1RewardPool _rewardPool = IUZV1RewardPool(_pool);
        uint256 _rewards = _rewardPool.getPendingRewards(_msgSender());
        if (_rewards == 0) return false;

        _rewardPool.claimRewards(_msgSender());
        return true;
    }

    /**
     * @dev  Allows claiming pending rewards for a list of pools.
     * @param pools list of reward pool addresses
     **/
    function claimRewardsFor(IUZV1RewardPool[] calldata pools)
        external
        override
        whenNotPaused
        onlyPro(_msgSender())
    {
        require(pools.length <= 20, "MAX_POOLS");
        uint256 poolCount = pools.length;
        if (poolCount == 0) return;
        while (poolCount-- > 0) {
            // verify that pool is a valid reward pool of this system
            // and no third party contract
            require(
                factory.isValidPool(address(pools[poolCount])) == true,
                "INVALID_POOL"
            );
            // if user has pending rewards, claim them
            if (pools[poolCount].getPendingRewards(_msgSender()) > 0)
                pools[poolCount].claimRewards(_msgSender());
        }
    }

    /**
     * @dev  Allows paying for an existing allocation and
     * set a custom native address as receiver of rewards
     *
     * @param _pool address of the pool, where the user wants to pay for an allocation
     * @param _amount uin256 amount to pay
     * @param _receiver string users native address, where rewards will be sent to
     **/
    function payRewardAndSetNativeAddressForPool(
        address _pool,
        uint256 _amount,
        string calldata _receiver
    ) external override whenNotPaused onlyPro(_msgSender()) {
        payRewardPool(_pool, _amount);
        setNativeAddressForPool(_pool, _receiver);
    }

    /// user functions
    /**
     * @dev  Allows paying for an existing allocation. With this function, users can
     * pay pools, without the need to re-approve every reward pool themselves. Just by
     * approving the router contract, they can pay for every upcoming allocation.
     *
     * @param _pool address of the pool, where the user wants to pay for an allocation
     * @param _amount uin256 amount to pay
     **/
    function payRewardPool(address _pool, uint256 _amount)
        public
        override
        whenNotPaused
        onlyPro(_msgSender())
    {
        // get pool instance
        IUZV1PayableRewardPool _rewardPool = IUZV1PayableRewardPool(_pool);
        require(_rewardPool.isPayable() == true, "NOT_PAYABLE");
        // fetch payment token for the desired pool
        address _token = _rewardPool.getPoolInfo().paymentToken;
        // payment token instance
        IERC20 _paymentToken = IERC20(_token);

        // transfer funds to router
        SafeERC20.safeTransferFrom(
            _paymentToken,
            _msgSender(),
            address(this),
            _amount
        );

        // approve pool
        SafeERC20.safeApprove(_paymentToken, _pool, _amount);

        // pay
        uint256 _refund = _rewardPool.pay(_msgSender(), _amount);

        // check if we need to refund
        if (_refund > 0) {
            SafeERC20.safeTransfer(_paymentToken, _msgSender(), _refund);
        }
    }

    /**
     * @dev  Call factory to create a new reward pool by cloning
     * existing deployed reward pool contracts and initiating them
     * with the desired input data
     *
     * @param totalRewards - amount of tokens / allocation for distribution
     * @param startBlock - block number when distribution phase begins
     * @param endBlock - block number when distribution phase ends
     * @param token - address of rewardable token (not needed for mainnet pools)
     * @param poolType of reward pool
     *  * PoolInfo object containing ui information for pool
     * @param name - optional name of token on blockchain
     * @param blockchain - name of used blockchain
     * @param cAddress - address of token used on blockchain
     * @return address Address of created reward pool
     **/
    function createNewPool(
        uint256 totalRewards,
        uint256 startBlock,
        uint256 endBlock,
        address token,
        uint8 poolType,
        string memory name,
        string memory blockchain,
        string memory cAddress
    ) external override onlyOwner returns (address) {
        return
            factory.createNewPool(
                totalRewards,
                startBlock,
                endBlock,
                token,
                poolType,
                name,
                blockchain,
                cAddress
            );
    }

    /**
     * @dev  Allows the user to set a custom native address as receiver of rewards
     * as these rewards will be distributed off-chain.
     *
     * @param _pool address of the pool, where the user wants set the native address
     * @param _receiver string users native address, where rewards will be sent to
     **/
    function setNativeAddressForPool(address _pool, string calldata _receiver)
        public
        override
        whenNotPaused
        onlyPro(_msgSender())
    {
        require(_pool != address(0), "ZERO_ADDRESS");
        IUZV1RewardPool(_pool).setNativeAddress(_msgSender(), _receiver);
    }

    /// control functions

    /**
     * @dev  Allows updating the internally used factory contract address,
     * in case of an upgrade.
     * @param _factory new address of the factory contract address
     **/
    function setFactory(address _factory) external override onlyOwner {
        require(_factory != address(0), "ZERO_ADDRESS");
        require(_factory != address(factory), "SAME_ADDRESS");
        factory = IUZV1Factory(_factory);
    }

    /**
     * @dev  Allows updating the internally used staking contract address,
     * in case of an upgrade.
     * @param _staking new address of the staking contract address
     **/
    function setStaking(address _staking) external override onlyOwner {
        require(_staking != address(0), "ZERO_ADDRESS");
        require(_staking != address(staking), "SAME_ADDRESS");
        staking = IUZV1Staking(_staking);
    }

    /**
     * @dev  Allows withdrawing of erc20 tokens that were sent to the contract
     * by accident. Similar things happen regularly on other contracts, so this is
     * an additional safeguard to withdraw funds of a specified token
     * @param _token Address of token to withdraw
     * @param _amount amount to withdraw. will withdraw everything if it exceeds the balance
     **/
    function emergencyWithdrawTokenFromRouter(address _token, uint256 _amount)
        external
        override
        onlyOwner
    {
        IERC20 _tokenToSend = IERC20(_token);
        uint256 _tokenBalance = _tokenToSend.balanceOf(address(this));
        require(_tokenBalance > 0, "NO_TOKEN_BALANCE");

        // send everything if amount exceeds balance
        uint256 _amountToWithdraw = (_amount > _tokenBalance)
            ? _tokenBalance
            : _amount;
        // transfer funds to owner
        SafeERC20.safeTransfer(_tokenToSend, owner(), _amountToWithdraw);
    }

    /* === MODIFIER === */
    modifier onlyStaking() {
        require(_msgSender() == address(staking), "FORBIDDEN: STAKING");
        _;
    }

    /* === EVENTS === */
}
