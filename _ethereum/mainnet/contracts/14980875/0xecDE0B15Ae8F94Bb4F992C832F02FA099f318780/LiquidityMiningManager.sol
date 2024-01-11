// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IBasePool.sol";
import "./TokenSaver.sol";

contract LiquidityMiningManager is Initializable, ReentrancyGuardUpgradeable, TokenSaver {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant GOV_ROLE = keccak256("GOV_ROLE");
    bytes32 public constant REWARD_DISTRIBUTOR_ROLE =
        keccak256("REWARD_DISTRIBUTOR_ROLE");

    IERC20Upgradeable public reward; // address of the token used for rewards
    address public rewardSource;
    uint256 public lastDistribution; // when rewards were last pushed
    uint256 public totalWeight; // total weight of all the pools, this is used to know the proportion in which a pool will get the tokens
    uint256 private constant BP = 1e18;

    // Returns true if the pool address has been added to receive rewards
    mapping(address => bool) public poolAdded;

    // Returns the pool information of a given index
    Pool[] public pools;

    struct Pool {
        IBasePool poolContract;
        uint256 weight;
    }

    modifier onlyGov() {
        require(
            hasRole(GOV_ROLE, _msgSender()),
            "LiquidityMiningManager.onlyGov: permission denied"
        );
        _;
    }

    modifier onlyRewardDistributor() {
        require(
            hasRole(REWARD_DISTRIBUTOR_ROLE, _msgSender()),
            "LiquidityMiningManager.onlyRewardDistributor: permission denied"
        );
        _;
    }

    event PoolAdded(address indexed pool, uint256 weight);
    event PoolRemoved(uint256 indexed poolId, address indexed pool);
    event WeightAdjusted(
        uint256 indexed poolId,
        address indexed pool,
        uint256 newWeight
    );
    event RewardsDistributed(address _from, uint256 indexed _amount);

    function initialize(
        address _reward,
        address _rewardSource
    ) public initializer {
        require(
            _reward != address(0),
            "LiquidityMiningManager.constructor: reward token must be set"
        );
        require(
            _rewardSource != address(0),
            "LiquidityMiningManager.constructor: rewardSource token must be set"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(GOV_ROLE, _msgSender());
        _setupRole(REWARD_DISTRIBUTOR_ROLE, _msgSender());

        reward = IERC20Upgradeable(_reward);
        rewardSource = _rewardSource;
        __TokenSaver_init();
        __ReentrancyGuard_init();
    }

    // Allows the admin to add a new pool that will receive rewards
    // weight: for example if the total weight is 10 and the weiht of one pool is 5, 
    function addPool(address _poolContract, uint256 _weight) 
        external 
        onlyGov
        nonReentrant {
        require(
            _poolContract != address(0),
            "LiquidityMiningManager.addPool: pool contract must be set"
        );
        require(
            !poolAdded[_poolContract],
            "LiquidityMiningManager.addPool: Pool already added"
        );
        
        _updateLastDistributionDate();
        // add pool
        pools.push(
            Pool({poolContract: IBasePool(_poolContract), weight: _weight})
        );
        poolAdded[_poolContract] = true;

        // increase totalWeight
        totalWeight += _weight;

        // Approve max token amount
        reward.safeApprove(_poolContract, type(uint256).max);

        emit PoolAdded(_poolContract, _weight);
    }

    // Allows the admin to delete a pool, so that it won't receive more rewards
    function removePool(uint256 _poolId) external onlyGov nonReentrant {
        require(
            _poolId < pools.length,
            "LiquidityMiningManager.removePool: Pool does not exist"
        );
        _updateLastDistributionDate();
        address poolAddress = address(pools[_poolId].poolContract);

        // decrease totalWeight
        totalWeight -= pools[_poolId].weight;

        // remove pool
        pools[_poolId] = pools[pools.length - 1];
        pools.pop();
        poolAdded[poolAddress] = false;

        emit PoolRemoved(_poolId, poolAddress);
    }

    // Allows the admin to change the proportion rewards that the pool can get
    function adjustWeight(uint256 _poolId, uint256 _newWeight)
        external
        onlyGov
        nonReentrant
    {
        require(
            _poolId < pools.length,
            "LiquidityMiningManager.adjustWeight: Pool does not exist"
        );
        _updateLastDistributionDate();
        Pool storage pool = pools[_poolId];

        totalWeight -= pool.weight;
        totalWeight += _newWeight;

        pool.weight = _newWeight;

        emit WeightAdjusted(_poolId, address(pool.poolContract), _newWeight);
    }

    function _updateLastDistributionDate() private onlyRewardDistributor {
        lastDistribution = block.timestamp;
    }

    // Allows the admin to distribute an amount of rewards to all the pools
    function distributeRewards(uint256 amountToDistribute) 
        public 
        onlyRewardDistributor 
        nonReentrant {

        lastDistribution = block.timestamp;

        if (pools.length == 0 || amountToDistribute == 0) return;
        
        reward.safeTransferFrom(rewardSource, address(this), amountToDistribute);

        for (uint256 i = 0; i < pools.length; i++) {
            Pool memory pool = pools[i];
            uint256 poolRewardAmount = (amountToDistribute * pool.weight) /
                totalWeight;
            // Ignore tx failing to prevent a single pool from halting reward distribution
            address(pool.poolContract).call(
                abi.encodeWithSelector(
                    pool.poolContract.distributeRewards.selector,
                    poolRewardAmount
                )
            );
        }

        uint256 leftOverReward = reward.balanceOf(address(this));

        // send back excess but ignore dust
        if (leftOverReward > 1) {
            reward.safeTransfer(rewardSource, leftOverReward);
        }

        emit RewardsDistributed(_msgSender(), amountToDistribute);
    }

    // Gets the information of the pools that have been added to receive rewards
    function getPools() external view returns (Pool[] memory result) {
        return pools;
    }

    // Gets the amount of the pools added
    function getPoolsLength() external view returns (uint256) {
        return pools.length;
    }

    // Allows to change the rewards source
    function setRewardsSource(address newRewardSource) external onlyGov {
        rewardSource = newRewardSource;
    }
}
