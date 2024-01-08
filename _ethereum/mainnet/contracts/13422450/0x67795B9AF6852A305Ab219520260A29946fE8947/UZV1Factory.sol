// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./SafeERC20.sol";
import "./IERC20.sol";

import "./IUZV1Factory.sol";
import "./IUZV1Router.sol";
import "./IUZV1RewardPool.sol";
import "./IUZV1PayableRewardPool.sol";

import "./TransparentUpgradeableProxy.sol";
import "./SharedDataTypes.sol";
import "./UZV1ProAccess.sol";

/**
 * @title UnizenStakingFactory
 * @author Unizen
 * @notice Factory is used to keep track of existing reward pools and generate new reward pool contracts
 **/
contract UZV1Factory is IUZV1Factory, UZV1ProAccess {
    /* === STATE VARIABLES === */
    // address of currently used router
    address public router;
    address public proxyAdmin;
    // list of all existing reward pools
    address[] public activePools;
    // list of all created pools
    address[] public allPools;
    // lookup table for pool addresses
    mapping(address => bool) public validPools;
    // base contracts for pool types that can be cloned
    mapping(uint8 => address) public basePools;

    function initialize(address _accessToken) public override initializer {
        UZV1ProAccess.initialize(_accessToken);
    }

    /* === VIEW FUNCTIONS === */
    /**
     * @dev  Loops through the maximum amount of valid active pools,
     * returns an array of pool address and the count of currently active pools
     * @return address[] List of active pool addresses
     **/
    function getActivePools()
        external
        view
        override
        returns (address[] memory)
    {
        // return pool list and pool count
        return activePools;
    }

    /**
     * @dev Checks if a pool address is a valid pool address
     * of this staking system, to ensure it can be trusted and
     * nor harmful third-party code gets executed.
     * @param pool address of the pool contract to check
     **/
    function isValidPool(address pool) external view override returns (bool) {
        // if pool address has an id, it's valid since it was
        // added via the factory contract.
        return validPools[pool];
    }

    /* === MUTATING FUNCTIONS === */
    /// control functions
    /**
     * @dev  Updates the router address
     * @param _router Address of new router
     **/
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "ZERO_ADDRESS");
        require(_router != router, "SAME_ADDRESS");
        router = _router;
    }

    // function setProxyAdmin()
    /**
     * @dev Allow the owner to add / update / remove addresses for base pools
     * of specific type.
     *
     * @param _pool address of the new base pool contract
     * @param _type type of the base reward pool
     **/
    function setBaseContractForType(address _pool, uint8 _type)
        external
        onlyOwner
    {
        // only allow zero addresses for existing base pools (for deletions)
        if (basePools[_type] == address(0)) {
            require(_pool != address(0), "ZERO_ADDRESS");
        }
        // update base contract address for pool type
        basePools[_type] = _pool;
    }

    function setProxyAdmin(address _proxyAdmin) external onlyOwner {
        require(proxyAdmin != _proxyAdmin, "SAME_ADDRESS");
        proxyAdmin = _proxyAdmin;
    }

    /**
     * @dev  Pool factory that creates a new reward pool by cloning
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
    ) external override onlyRouterOrOwner returns (address) {
        require(
            proxyAdmin != address(0) && router != address(0),
            "ZERO_ADDRESS"
        );
        // check reward amount
        require(totalRewards > 0, "ZERO_REWARDS");
        // start block cant be in the past
        require(startBlock >= block.number, "INVALID_START_BLOCK");
        // end block cant be in the past
        require(endBlock > startBlock, "INVALID_END_BLOCK");
        // a base pool contract needs to exist for that pool type
        require(basePools[poolType] != address(0), "INVALID_POOL_TYPE");
        address _implement = basePools[poolType];

        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(address,address)",
            router,
            membershipToken()
        );
        TransparentUpgradeableProxy proxyContract = new TransparentUpgradeableProxy(
                _implement,
                proxyAdmin,
                _initializationCalldata
            );
        IUZV1RewardPool _newPool = IUZV1RewardPool(address(proxyContract));

        // Setup pool data
        SharedDataTypes.PoolInfo memory _poolInfo;
        _poolInfo.name = name;
        _poolInfo.blockchain = blockchain;
        _poolInfo.cAddress = cAddress;
        // Init the input data of new pool
        SharedDataTypes.PoolInputData memory _inputData;

        _inputData.totalRewards = totalRewards;
        _inputData.startBlock = startBlock;
        _inputData.endBlock = endBlock;
        _inputData.poolType = poolType;
        _inputData.token = token;
        _inputData.tokenInfo = _poolInfo;
        _newPool.setFactory(address(this));
        _newPool.setPoolData(_inputData);
        _newPool.transferOwnership(owner());

        // check if pool type is a token or mainnet reward pool
        bool _isTokenPool = _newPool.canReceiveRewards();

        if (_isTokenPool) {
            // onchain distribution, so token address needs to exist
            require(token != address(0), "NO_REWARD_TOKEN");

            IERC20 _token = IERC20(token);
            // transfer funds to contract, if needed
            SafeERC20.safeTransferFrom(
                _token,
                _msgSender(),
                address(proxyContract),
                _inputData.totalRewards
            );
        }

        // if everything went well, add new pool to pool list
        addPoolToPoolList(address(proxyContract));

        emit PoolCreated(
            address(proxyContract),
            _inputData.token,
            _inputData.totalRewards,
            _inputData.startBlock,
            _inputData.endBlock
        );

        // return the new pool address
        return address(proxyContract);
    }

    /**
     * @dev  Adds pool to active pool list
     * @param _pool Address of pool
     **/
    function addPoolToPoolList(address _pool) public onlyOwner {
        require(_pool != address(0), "ZERO_ADDRESS");
        // add pool to active list on desired index
        activePools.push(_pool);
        // add pools to total pool list
        allPools.push(_pool);
        // add index to lookup table for valid pools list
        validPools[_pool] = true;
    }

    /**
     * @dev  Removes pool from active pool list
     * @param _pool Address of pool
     **/
    function removePool(address _pool) external override onlyOwner {
        require(validPools[_pool], "INVALID_POOL");

        // get index of active pool
        uint256 _idx;
        // loop through maximum active pool count
        for (uint256 i = 0; i < activePools.length; i++) {
            // check if pool address is the desired address
            if (activePools[i] == _pool) {
                // assign current index
                _idx = i;
            }
        }
        // remove from active pools list
        activePools[_idx] = activePools[activePools.length - 1];
        activePools.pop();
        validPools[_pool] = false;
    }

    function setNative(address _pool, bool _isNative)
        external
        override
        onlyOwner
    {
        require(validPools[_pool], "INVALID_POOL");

        IUZV1PayableRewardPool(_pool).setNative(_isNative);
    }

    /**
     * @dev  Updates reward pool with a new staking window
     * @param _pool address of the pool to change
     * @param _startBlock start of the staking window
     * @param _endBlock end of the staking window
     **/
    function setStakingWindow(
        address _pool,
        uint256 _startBlock,
        uint256 _endBlock
    ) external override onlyOwner {
        require(validPools[_pool], "INVALID_POOL");

        IUZV1RewardPool(_pool).setStakingWindow(_startBlock, _endBlock);
    }

    /**
     * @dev Updates the reward pool with a new payment receiver
     * @param _pool address of the pool to change
     * @param _receiver address of the payment receiver
     **/
    function setPaymentAddress(address _pool, address _receiver)
        external
        override
        onlyOwner
    {
        require(validPools[_pool], "INVALID_POOL");
        IUZV1PayableRewardPool(_pool).setPaymentAddress(_receiver);
    }

    /**
     * @dev  Updates reward pool with a new payment window
     * @param _pool address of the pool to change
     * @param _startBlock start of the payment window window
     * @param _endBlock end of the payment window
     **/
    function setPaymentWindow(
        address _pool,
        uint256 _startBlock,
        uint256 _endBlock
    ) external override onlyOwner {
        require(validPools[_pool], "INVALID_POOL");

        IUZV1PayableRewardPool(_pool).setPaymentWindow(_startBlock, _endBlock);
    }

    /**
     * @dev  Adds a new payable token to a incubator pool
     * @param _pool address of the pool to change
     * @param _token address of the payable token
     * @param _pricePerReward price of a single reward
     **/
    function setPaymentToken(
        address _pool,
        address _token,
        uint256 _pricePerReward
    ) external override onlyOwner {
        require(validPools[_pool], "INVALID_POOL");

        IUZV1PayableRewardPool(_pool).setPaymentToken(_token, _pricePerReward);
    }

    /**
     * @dev  Updates reward pool with a new distribution window
     * @param _pool address of the pool to change
     * @param _startBlock start of the distribution window
     * @param _endBlock end of the distribution window
     **/
    function setDistributionWindow(
        address _pool,
        uint256 _startBlock,
        uint256 _endBlock
    ) external override onlyOwner {
        require(validPools[_pool], "INVALID_POOL");

        IUZV1PayableRewardPool(_pool).setDistributionWindow(
            _startBlock,
            _endBlock
        );
    }

    /**
     * @dev  Emergency function to withdraw accidentally transferred tokens to a pool contract
     * @param _pool address of the pool to change
     * @param _tokenAddress address of the erc20 token to withdraw
     * @param _amount amount to withdraw. if bigger than balance, it will withdraw everything to owner
     **/
    function withdrawTokens(
        address _pool,
        address _tokenAddress,
        uint256 _amount
    ) external override onlyOwner {
        require(validPools[_pool], "INVALID_POOL");
        IUZV1RewardPool(_pool).withdrawTokens(_tokenAddress, _amount);

        IERC20 _token = IERC20(_tokenAddress);
        uint256 _receivedAmount = (_amount <= _token.balanceOf(address(this)))
            ? _amount
            : _token.balanceOf(address(this));

        SafeERC20.safeTransfer(_token, owner(), _receivedAmount);
    }

    /* === MODIFIERS === */

    modifier onlyRouterOrOwner() {
        require(
            _msgSender() == router || _msgSender() == owner(),
            "ONLY_ROUTER_OR_OWNER"
        );
        _;
    }

    /* === EVENTS === */
    event PoolCreated(
        address indexed _pool,
        address indexed _token,
        uint256 _totalReward,
        uint256 _startBlock,
        uint256 _endBlock
    );
    event PoolUpdated(address indexed _pool);
    event PoolRemoved(address indexed _pool);
}
