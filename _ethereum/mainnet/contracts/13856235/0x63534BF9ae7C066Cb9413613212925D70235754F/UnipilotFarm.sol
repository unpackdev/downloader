//SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

/// @title Unipilot Yield Farming
/// @author Asim Raza
/// @notice You can use this contract for earn reward on staking nft
/// @dev All function calls are currently implemented without side effects

//Utility imports
import "./IUnipilotFarm.sol";
import "./IUniswapLiquidityManager.sol";
import "./IUnipilot.sol";
import "./IFarmV1.sol";
import "./IUnipilotStake.sol";

//Uniswap v3 core imports
import "./FullMath.sol";

//Openzeppelin imports
import "./SafeMath.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ReentrancyGuard.sol";

contract UnipilotFarm is IUnipilotFarm, ReentrancyGuard, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public isFarmingActive;
    bool public backwardCompatible;
    address public governance;
    uint256 public pilotPerBlock = 1e18;
    uint256 public farmingGrowthBlockLimit;
    uint256 public totalRewardSent;

    address private ulm;
    address private stakeContract;
    address[2] private deprecated;

    address private constant PILOT_TOKEN = 0x37C997B35C619C21323F3518B9357914E8B99525; 
    address private constant UNIPILOT = 0xde5bF92E3372AA59C73Ca7dFc6CEc599E1B2b08C;

    address[] public poolListed;

    // farming status --> tokenId => bool
    mapping(uint256 => bool) public farmingActive;

    // exist in whitelist or not --> pool address => bool
    mapping(address => bool) public poolWhitelist;

    // poolinfo address =>Poolinfo struct
    mapping(address => PoolInfo) public poolInfo;

    // poolAltInfo address => PoolAltInfo struct
    mapping(address => PoolAltInfo) public poolAltInfo;

    // userinfo user --> tokenId nft => userInfo struct
    mapping(uint256 => UserInfo) public userInfo;

    //user address => pool address => tokenId[]
    mapping(address => mapping(address => uint256[])) public userToPoolToTokenIds;
    modifier onlyGovernance() {
        require(msg.sender == governance, "NA");
        _;
    }

    modifier isActive() {
        require(isFarmingActive, "FNA");
        _;
    }

    modifier isLimitActive() {
        require(farmingGrowthBlockLimit == 0, "LA");
        _;
    }

    modifier onlyOwner(uint256 _tokenId) {
        require(IERC721(UNIPILOT).ownerOf(_tokenId) == msg.sender, "NO");
        _;
    }

    modifier isPoolRewardActive(address pool) {
        require(poolInfo[pool].isRewardActive, "RNA");
        _;
    }

    modifier onlyStake() {
        require(msg.sender == stakeContract, "NS");
        _;
    }

    constructor(
        address _ulm,
        address _governance,
        address[2] memory _deprecated
    ) {
        governance = _governance;

        ulm = _ulm;

        isFarmingActive = true;

        deprecated = _deprecated;

        backwardCompatible = true;
    }

    /// @notice withdraw NFT with reward
    /// @dev only owner of nft can withdraw
    /// @param _tokenId unstake tokenID
    function withdrawNFT(uint256 _tokenId) external override {
        UserInfo storage userState = userInfo[_tokenId];

        PoolInfo storage poolState = poolInfo[userState.pool];

        PoolAltInfo storage poolAltState = poolAltInfo[userState.pool];

        withdrawReward(_tokenId);

        poolState.totalLockedLiquidity = poolState.totalLockedLiquidity.sub(
            userState.liquidity
        );

        IERC721(UNIPILOT).safeTransferFrom(address(this), msg.sender, _tokenId);

        farmingActive[_tokenId] = false;

        emit WithdrawNFT(
            userState.pool,
            userState.user,
            _tokenId,
            poolState.totalLockedLiquidity
        );

        if (poolState.totalLockedLiquidity == 0) {
            poolState.startBlock = block.number;
            poolState.lastRewardBlock = block.number;
            poolState.globalReward = 0;

            poolAltState.startBlock = block.number;
            poolAltState.lastRewardBlock = block.number;
            poolAltState.globalReward = 0;
        }

        uint256 index = callIndex(userState.pool, _tokenId);

        updateNFTList(index, userState.user, userState.pool);

        delete userInfo[_tokenId];
    }

    /// @notice withdraw NFT without reward claiming
    /// @param _tokenId unstake this tokenID
    function emergencyNFTWithdraw(uint256 _tokenId) external {
        UserInfo storage userState = userInfo[_tokenId];

        require(userState.user == msg.sender, "NOO");

        PoolInfo storage poolState = poolInfo[userState.pool];

        PoolAltInfo storage poolAltState = poolAltInfo[userState.pool];

        poolState.totalLockedLiquidity = poolState.totalLockedLiquidity.sub(
            userState.liquidity
        );

        IERC721(UNIPILOT).safeTransferFrom(address(this), userState.user, _tokenId);

        if (poolState.totalLockedLiquidity == 0) {
            poolState.startBlock = block.number;
            poolState.lastRewardBlock = block.number;
            poolState.globalReward = 0;

            poolAltState.startBlock = block.number;
            poolAltState.lastRewardBlock = block.number;
            poolAltState.globalReward = 0;
        }
        uint256 index = callIndex(userState.pool, _tokenId);
        updateNFTList(index, userState.user, userState.pool);
        delete userInfo[_tokenId];
    }

    /// @notice Migrate funds to Governance address or in new Contract
    /// @dev only governance can call this
    /// @param _newContract address of new contract or wallet address
    /// @param _tokenAddress address of token which want to migrate
    /// @param _amount withdraw that amount which are required
    function migrateFunds(
        address _newContract,
        address _tokenAddress,
        uint256 _amount
    ) external onlyGovernance {
        require(_newContract != address(0), "CNE");
        IERC20(_tokenAddress).safeTransfer(_newContract, _amount);
        emit MigrateFunds(_newContract, _tokenAddress, _amount);
    }

    /// @notice Use to blacklist pools
    /// @dev only governance can call this
    /// @param _pools addresses to be blacklisted
    function blacklistPools(address[] memory _pools) external override onlyGovernance {
        for (uint256 i = 0; i < _pools.length; i++) {
            poolWhitelist[_pools[i]] = false;
            poolInfo[_pools[i]].rewardMultiplier = 0;    
            emit BlacklistPool(_pools[i], poolWhitelist[_pools[i]], block.timestamp);
        }
    }

    /// @notice Use to update ULM address
    /// @dev only governance can call this
    /// @param _ulm new address of ULM
    function updateULM(address _ulm) external override onlyGovernance {
        emit UpdateULM(ulm, ulm = _ulm, block.timestamp);
    }

    /// @notice Updating pilot per block for every pool
    /// @dev only governance can call this
    /// @param _value new value of pilot per block
    function updatePilotPerBlock(uint256 _value) external override onlyGovernance {
        address[] memory pools = poolListed;
        pilotPerBlock = _value;
        for (uint256 i = 0; i < pools.length; i++) {
            if (poolWhitelist[pools[i]]) {
                if (poolInfo[pools[i]].totalLockedLiquidity != 0) {
                    updatePoolState(pools[i]);
                }
                emit UpdatePilotPerBlock(pools[i], pilotPerBlock);
            }
        }
    }

    /// @notice Updating multiplier for single pool
    /// @dev only governance can call this
    /// @param _pool pool address
    /// @param _value new value of multiplier of pool
    function updateMultiplier(address _pool, uint256 _value)
        external
        override
        onlyGovernance
    {
        updatePoolState(_pool);

        emit UpdateMultiplier(
            _pool,
            poolInfo[_pool].rewardMultiplier,
            poolInfo[_pool].rewardMultiplier = _value
        );
    }

    /// @notice User total nft(s) with respect to pool
    /// @param _user particular user address
    /// @param _pool particular pool address
    /// @return tokenCount count of nft(s)
    /// @return tokenIds array of tokenID
    function totalUserNftWRTPool(address _user, address _pool)
        external
        view
        override
        returns (uint256 tokenCount, uint256[] memory tokenIds)
    {
        tokenCount = userToPoolToTokenIds[_user][_pool].length;
        tokenIds = userToPoolToTokenIds[_user][_pool];
    }

    /// @notice NFT token ID farming status
    /// @param _tokenId particular tokenId
    function nftStatus(uint256 _tokenId) external view override returns (bool) {
        return farmingActive[_tokenId];
    }

    /// @notice User can call tx to deposit nft
    /// @dev pool address must be exist in whitelisted pools
    /// @param _tokenId tokenID which want to deposit
    /// @return status of farming is active for particular tokenID
    function depositNFT(uint256 _tokenId)
        external
        override
        isActive
        isLimitActive
        onlyOwner(_tokenId)
        returns (bool)
    {
        address sender = msg.sender;
        IUniswapLiquidityManager.Position memory positions = IUniswapLiquidityManager(ulm)
            .userPositions(_tokenId);

        (address pool, uint256 liquidity) = (positions.pool, positions.liquidity);

        require(poolWhitelist[pool], "PNW");

        IUniswapLiquidityManager.LiquidityPosition
            memory liquidityPositions = IUniswapLiquidityManager(ulm).poolPositions(pool);

        uint256 totalLiquidity = liquidityPositions.totalLiquidity;

        require(totalLiquidity >= liquidity && liquidity > 0, "IL");

        PoolInfo storage poolState = poolInfo[pool];

        if (poolState.lastRewardBlock != poolState.startBlock) {
            uint256 blockDifference = (block.number).sub(poolState.lastRewardBlock);

            poolState.globalReward = getGlobalReward(
                pool,
                blockDifference,
                pilotPerBlock,
                poolState.rewardMultiplier,
                poolState.globalReward
            );
        }

        poolState.totalLockedLiquidity = poolState.totalLockedLiquidity.add(liquidity);

        userInfo[_tokenId] = UserInfo({
            pool: pool,
            liquidity: liquidity,
            user: sender,
            reward: poolState.globalReward,
            altReward: userInfo[_tokenId].altReward,
            boosterActive: false
        });
        userToPoolToTokenIds[sender][pool].push(_tokenId);

        farmingActive[_tokenId] = true; // user's farming active

        IERC721(UNIPILOT).safeTransferFrom(sender, address(this), _tokenId);

        if (poolState.isAltActive) {
            altGR(pool, _tokenId);
        }

        poolState.lastRewardBlock = block.number;

        emit Deposit(
            pool,
            _tokenId,
            userInfo[_tokenId].liquidity,
            poolState.totalLockedLiquidity,
            poolState.globalReward,
            poolState.rewardMultiplier,
            pilotPerBlock
        );
        return farmingActive[_tokenId];
    }

    /// @notice toggle alt token state on pool
    /// @dev only governance can call this
    /// @param _pool pool address for alt token
    function toggleActiveAlt(address _pool) external onlyGovernance returns (bool) {
        require(poolAltInfo[_pool].altToken != address(0), "TNE");
        emit UpdateAltState(
            poolInfo[_pool].isAltActive,
            poolInfo[_pool].isAltActive = !poolInfo[_pool].isAltActive,
            _pool
        );

        if (poolInfo[_pool].isAltActive) {
            updateAltPoolState(_pool);
        } else {
            poolAltInfo[_pool].lastRewardBlock = block.number;
        }

        return poolInfo[_pool].isAltActive;
    }

    ///@notice Updating address of alt token
    ///@dev only Governance can call this
    function updateAltToken(address _pool, address _altToken) external onlyGovernance {
        emit UpdateActiveAlt(
            poolAltInfo[_pool].altToken,
            poolAltInfo[_pool].altToken = _altToken,
            _pool
        );

        PoolAltInfo memory poolAltState = poolAltInfo[_pool];
        poolAltState = PoolAltInfo({
            globalReward: 0,
            lastRewardBlock: block.number,
            altToken: poolAltInfo[_pool].altToken,
            startBlock: block.number
        });

        poolAltInfo[_pool] = poolAltState;
    }

    /// @dev onlyGovernance can call this
    /// @param _pools The pools to make whitelist or initialize
    /// @param _multipliers multiplier of pools
    function initializer(address[] memory _pools, uint256[] memory _multipliers)
        public
        override
        onlyGovernance
    {
        require(_pools.length == _multipliers.length, "LNS");
        for (uint256 i = 0; i < _pools.length; i++) {
            if (
                !poolWhitelist[_pools[i]] && poolInfo[_pools[i]].startBlock == 0
            ) {
                insertPool(_pools[i], _multipliers[i]);
            } else {
                poolWhitelist[_pools[i]] = true;
                poolInfo[_pools[i]].rewardMultiplier = _multipliers[i];
            }
        }
    }

    /// @notice Generic function to calculating global reward
    /// @param pool pool address
    /// @param blockDifference difference of block from current block to last reward block
    /// @param rewardPerBlock reward on per block
    /// @param multiplier multiplier value
    /// @return globalReward calculating global reward
    function getGlobalReward(
        address pool,
        uint256 blockDifference,
        uint256 rewardPerBlock,
        uint256 multiplier,
        uint256 _globalReward
    ) public view returns (uint256 globalReward) {
        uint256 tvl;
        if (backwardCompatible) {
            for(uint i = 0; i < deprecated.length; i++){
               uint256 prevTvl=(IUnipilotFarmV1(deprecated[i]).poolInfo(pool).totalLockedLiquidity);
               tvl=tvl.add(prevTvl); 
            }
            tvl = tvl.add(poolInfo[pool].totalLockedLiquidity);
        } else {
            tvl = poolInfo[pool].totalLockedLiquidity;
        }
        uint256 temp = FullMath.mulDiv(rewardPerBlock, multiplier, 1e18);
        globalReward = FullMath.mulDiv(blockDifference.mul(temp), 1e18, tvl).add(
            _globalReward
        );
    }

    /// @notice Generic function to calculating reward of tokenId
    /// @param _tokenId find current reward of tokenID
    /// @return pilotReward calculate pilot reward
    /// @return globalReward calculate global reward
    /// @return globalAltReward calculate global reward of alt token
    /// @return altReward calculate reward of alt token
    function currentReward(uint256 _tokenId)
        public
        view
        override
        returns (
            uint256 pilotReward,
            uint256 globalReward,
            uint256 globalAltReward,
            uint256 altReward
        )
    {
        UserInfo memory userState = userInfo[_tokenId];
        PoolInfo memory poolState = poolInfo[userState.pool];
        PoolAltInfo memory poolAltState = poolAltInfo[userState.pool];

        DirectTo check = DirectTo.GRforPilot;

        if (isFarmingActive) {
            globalReward = checkLimit(_tokenId, check);

            if (poolState.isAltActive) {
                check = DirectTo.GRforAlt;
                globalAltReward = checkLimit(_tokenId, check);
            } else {
                globalAltReward = poolAltState.globalReward;
            }
        } else {
            globalReward = poolState.globalReward;
            globalAltReward = poolAltState.globalReward;
        }

        uint256 userReward = globalReward.sub(userState.reward);
        uint256 _reward = (userReward.mul(userState.liquidity)).div(1e18);
        if (userState.boosterActive) {
            uint256 multiplier = IUnipilotStake(stakeContract).getBoostMultiplier(
                userState.user,
                userState.pool,
                _tokenId
            );
            uint256 boostedReward = (_reward.mul(multiplier)).div(1e18);
            pilotReward = _reward.add((boostedReward));
        } else {
            pilotReward = _reward;
        }

        _reward = globalAltReward.sub(userState.altReward);
        altReward = (_reward.mul(userState.liquidity)).div(1e18);
    }

    /// @notice Generic function to check limit of global reward of token Id
    function checkLimit(uint256 _tokenId, DirectTo _check)
        internal
        view
        returns (uint256 globalReward)
    {
        address pool = userInfo[_tokenId].pool;

        TempInfo memory poolState;

        if (_check == DirectTo.GRforPilot) {
            poolState = TempInfo({
                globalReward: poolInfo[pool].globalReward,
                lastRewardBlock: poolInfo[pool].lastRewardBlock,
                rewardMultiplier: poolInfo[pool].rewardMultiplier
            });
        } else if (_check == DirectTo.GRforAlt) {
            poolState = TempInfo({
                globalReward: poolAltInfo[pool].globalReward,
                lastRewardBlock: poolAltInfo[pool].lastRewardBlock,
                rewardMultiplier: poolInfo[pool].rewardMultiplier
            });
        }

        if (
            poolState.lastRewardBlock < farmingGrowthBlockLimit &&
            block.number > farmingGrowthBlockLimit
        ) {
            globalReward = getGlobalReward(
                pool,
                farmingGrowthBlockLimit.sub(poolState.lastRewardBlock),
                pilotPerBlock,
                poolState.rewardMultiplier,
                poolState.globalReward
            );
        } else if (
            poolState.lastRewardBlock > farmingGrowthBlockLimit &&
            farmingGrowthBlockLimit > 0
        ) {
            globalReward = poolState.globalReward;
        } else {
            uint256 blockDifference = (block.number).sub(poolState.lastRewardBlock);
            globalReward = getGlobalReward(
                pool,
                blockDifference,
                pilotPerBlock,
                poolState.rewardMultiplier,
                poolState.globalReward
            );
        }
    }

    /// @notice Withdraw reward of token Id
    /// @dev only owner of nft can withdraw
    /// @param _tokenId withdraw reward of this tokenID
    function withdrawReward(uint256 _tokenId)
        public
        override
        nonReentrant
        isPoolRewardActive(userInfo[_tokenId].pool)
    {
        UserInfo storage userState = userInfo[_tokenId];
        PoolInfo storage poolState = poolInfo[userState.pool];

        require(userState.user == msg.sender, "NO");
        (
            uint256 pilotReward,
            uint256 globalReward,
            uint256 globalAltReward,
            uint256 altReward
        ) = currentReward(_tokenId);

        require(IERC20(PILOT_TOKEN).balanceOf(address(this)) >= pilotReward, "IF");

        poolState.globalReward = globalReward;
        poolState.lastRewardBlock = block.number;
        userState.reward = globalReward;

        totalRewardSent += pilotReward;

        IERC20(PILOT_TOKEN).safeTransfer(userInfo[_tokenId].user, pilotReward);

        if (poolState.isAltActive) {
            altWithdraw(_tokenId, globalAltReward, altReward);
        }

        emit WithdrawReward(
            userState.pool,
            _tokenId,
            userState.liquidity,
            userState.reward,
            poolState.globalReward,
            poolState.totalLockedLiquidity,
            pilotReward
        );
    }

    /// @notice internal function use for initialize struct values of single pool
    /// @dev generalFunction to add pools
    /// @param _pool pool address
    function insertPool(address _pool, uint256 _multiplier) internal {
        poolWhitelist[_pool] = true;
        poolListed.push(_pool);
        poolInfo[_pool] = PoolInfo({
            startBlock: block.number,
            globalReward: 0,
            lastRewardBlock: block.number,
            totalLockedLiquidity: 0,
            rewardMultiplier: _multiplier,
            isRewardActive: true,
            isAltActive: poolInfo[_pool].isAltActive
        });

        emit NewPool(
            _pool,
            pilotPerBlock,
            poolInfo[_pool].rewardMultiplier,
            poolInfo[_pool].lastRewardBlock,
            poolWhitelist[_pool]
        );
    }

    /// @notice Use to update state of alt token
    function altGR(address _pool, uint256 _tokenId) internal {
        PoolAltInfo storage poolAltState = poolAltInfo[_pool];

        if (poolAltState.lastRewardBlock != poolAltState.startBlock) {
            uint256 blockDifference = (block.number).sub(poolAltState.lastRewardBlock);

            poolAltState.globalReward = getGlobalReward(
                _pool,
                blockDifference,
                pilotPerBlock,
                poolInfo[_pool].rewardMultiplier,
                poolAltState.globalReward
            );
        }

        poolAltState.lastRewardBlock = block.number;

        userInfo[_tokenId].altReward = poolAltState.globalReward;
    }

    /// @notice Use for pool tokenId to find its index
    function callIndex(address pool, uint256 _tokenId)
        internal
        view
        returns (uint256 index)
    {
        uint256[] memory tokens = userToPoolToTokenIds[msg.sender][pool];
        for (uint256 i = 0; i <= tokens.length; i++) {
            if (_tokenId == userToPoolToTokenIds[msg.sender][pool][i]) {
                index = i;
                break;
            }
        }
        return index;
    }

    /// @notice Use to update list of NFT(s)
    function updateNFTList(
        uint256 _index,
        address user,
        address pool
    ) internal {
        require(_index < userToPoolToTokenIds[user][pool].length, "IOB");
        uint256 temp = userToPoolToTokenIds[user][pool][
            userToPoolToTokenIds[user][pool].length.sub(1)
        ];
        userToPoolToTokenIds[user][pool][_index] = temp;
        userToPoolToTokenIds[user][pool].pop();
    }

    /// @notice Use to toggle farming state of contract
    function toggleFarmingActive() external override onlyGovernance {
        emit FarmingStatus(
            isFarmingActive,
            isFarmingActive = !isFarmingActive,
            block.timestamp
        );
    }

    /// @notice Use to withdraw alt tokens of token Id (internal)
    function altWithdraw(
        uint256 _tokenId,
        uint256 altGlobalReward,
        uint256 altReward
    ) internal {
        PoolAltInfo storage poolAltState = poolAltInfo[userInfo[_tokenId].pool];
        require(
            IERC20(poolAltState.altToken).balanceOf(address(this)) >= altReward,
            "IF"
        );
        poolAltState.lastRewardBlock = block.number;
        poolAltState.globalReward = altGlobalReward;
        userInfo[_tokenId].altReward = altGlobalReward;
        IERC20(poolAltState.altToken).safeTransfer(userInfo[_tokenId].user, altReward);
    }

    /// @notice Use to toggle state of reward of pool
    function toggleRewardStatus(address _pool) external override onlyGovernance {
        if (poolInfo[_pool].isRewardActive) {
            updatePoolState(_pool);
        } else {
            poolInfo[_pool].lastRewardBlock = block.number;
        }

        emit RewardStatus(
            _pool,
            poolInfo[_pool].isRewardActive,
            poolInfo[_pool].isRewardActive = !poolInfo[_pool].isRewardActive
        );
    }

    /// @notice Use to update pool state (internal)
    function updatePoolState(address _pool) internal {
        PoolInfo storage poolState = poolInfo[_pool];
        if (poolState.totalLockedLiquidity > 0) {
            uint256 currentGlobalReward = getGlobalReward(
                _pool,
                (block.number).sub(poolState.lastRewardBlock),
                pilotPerBlock,
                poolState.rewardMultiplier,
                poolState.globalReward
            );

            poolState.globalReward = currentGlobalReward;
            poolState.lastRewardBlock = block.number;
        }
    }

    /// @notice Use to update alt token state (internal)
    function updateAltPoolState(address _pool) internal {
        PoolAltInfo storage poolAltState = poolAltInfo[_pool];
        if (poolInfo[_pool].totalLockedLiquidity > 0) {
            uint256 currentGlobalReward = getGlobalReward(
                _pool,
                (block.number).sub(poolAltState.lastRewardBlock),
                pilotPerBlock,
                poolInfo[_pool].rewardMultiplier,
                poolAltState.globalReward
            );

            poolAltState.globalReward = currentGlobalReward;
            poolAltState.lastRewardBlock = block.number;
        }
    }

    /// @notice Use to stop staking NFT(s) in contract after block limit
    function updateFarmingLimit(uint256 _blockNumber) external onlyGovernance {
        emit UpdateFarmingLimit(
            farmingGrowthBlockLimit,
            farmingGrowthBlockLimit = _blockNumber
        );
    }

    /// @notice toggle booster status of token Id
    function toggleBooster(uint256 tokenId) external onlyStake {
        emit ToggleBooster(
            tokenId,
            userInfo[tokenId].boosterActive,
            userInfo[tokenId].boosterActive = !userInfo[tokenId].boosterActive
        );
    }

    /// @notice set stake contract address
    function setStake(address _stakeContract) external onlyGovernance {
        emit Stake(stakeContract, stakeContract = _stakeContract);
    }

    /// @notice toggle backward compayibility status of FarmingV1
    function toggleBackwardCompatibility() external onlyGovernance {
        emit BackwardCompatible(
            backwardCompatible,
            backwardCompatible = !backwardCompatible
        );
    }

    /// @notice governance can update new address of governance
    function updateGovernance(address _governance) external onlyGovernance {
        emit GovernanceUpdated(governance, governance = _governance);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {
        //payable
    }
}
