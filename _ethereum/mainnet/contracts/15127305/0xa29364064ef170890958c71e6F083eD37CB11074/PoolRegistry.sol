// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

// Libraries
import "./Address.sol";
import "./IERC20.sol";

// Interfaces
import "./IGemGlobalConfig.sol";
import "./IPoolFactory.sol";
import "./IDefaultTokenRegistry.sol";
import "./ITokenRegistry.sol";
import "./ISavingAccount.sol";
import "./IGlobalConfig.sol";
import "./IBank.sol";

// Imports
import "./FixedPriceOracleNative.sol";

enum PoolStatus {
    None,
    Cloned,
    Initialized,
    Configured
}

contract PoolRegistry {
    using Address for address;

    // constants
    address public constant NATIVE_TOKEN = 0x000000000000000000000000000000000000000E;
    uint256 public constant ONE_YEAR = 365 days;
    uint256 public constant MAX_MATURITY_DATE = 10 * ONE_YEAR; // 10 years
    uint256 public constant MIN_APR = 3; // 3%
    uint256 public constant MAX_APR = 300; // 300%

    // immutable
    IPoolFactory public immutable poolFactory;
    IGemGlobalConfig public gemGlobalConfig;

    // storage variables
    uint256 public nextPoolId;
    IDefaultTokenRegistry public defaultTokenRegistry;

    // <poolID> => <Pool>
    mapping(uint256 => Pool) public pools;

    // <creator> => <PoolIdsArray>
    // to maintain the pool-ids a creator has created
    mapping(address => uint256[]) public creatorToPools;

    struct Pool {
        address poolCreator; // Pool Creator
        address baseToken; // Base Token provided by pool-creator
        address globalConfig; // Savings - GlobalConfig.sol
        address savingAccount; // Savings - SavingAccount.sol
        address bank; // Savings - Bank.sol
        address accounts; // Savings - Accounts.sol
        address tokenRegistry; // Savings - TokenRegistry.sol
        address claim; // Savings - Claim.sol
        address fixedPriceOracle; // Fixed Price Oracle for Base Token
        PoolStatus poolStatus; // Pool Status, Clone=1 / Initialized=2 / Configured=3
        uint256 maturesOn; // Pool maturity date after that withdrawals allowed
    }

    // EVENTS
    event NewPoolCloned(uint256 indexed _poolId);
    event NewPoolInitialized(uint256 indexed _poolId);
    event NewPoolConfigured(uint256 indexed _poolId);

    constructor(
        IGemGlobalConfig _gemGlobalConfig,
        IPoolFactory _poolFactory,
        IDefaultTokenRegistry _defaultTokenRegistry
    ) {
        gemGlobalConfig = _gemGlobalConfig;
        poolFactory = _poolFactory;
        defaultTokenRegistry = _defaultTokenRegistry;
    }

    function createNewPoolStep1()
        external
        returns (
            uint256 newPoolId,
            address globalConfig,
            address savingAccount,
            address bank,
            address accounts,
            address tokenRegistry,
            address claim
        )
    {
        newPoolId = nextPoolId;
        (globalConfig, savingAccount, bank, accounts, tokenRegistry, claim) = poolFactory.createNewPool(newPoolId);
        pools[newPoolId] = Pool(
            msg.sender, // pool creator
            address(0), // zero baseToken
            globalConfig,
            savingAccount,
            bank,
            accounts,
            tokenRegistry,
            claim,
            address(0), // FixedPriceOracle, initiaized in step-2
            PoolStatus.Cloned,
            0 // maturityDate
        );
        nextPoolId++;

        // add poolId for creator
        creatorToPools[msg.sender].push(newPoolId);

        emit NewPoolCloned(newPoolId);
    }

    function createNewPoolStep2(
        uint256 _poolId,
        address _baseToken,
        uint256 _initTokenPriceInUSD8,
        uint256 _borrowLTV
    ) external payable {
        Pool storage pool = pools[_poolId];
        require(msg.sender == pool.poolCreator, "not a pool creator");
        require(_baseToken != address(0), "base token address is zero");
        require(pool.poolStatus == PoolStatus.Cloned, "pool should be Cloned");
        require(_baseToken.isContract(), "baseToken is not a contract");
        // avoid checking for FIN tokens while deploying DeFiner default pool
        if (_poolId != 0) {
            // ensure that the pool creator has some tokens of the given `_token`
            require(IERC20(_baseToken).balanceOf(pool.poolCreator) > 0, "pool creator not have tokens");
        }

        // 1. add all default token
        uint256 tokensLength = defaultTokenRegistry.getTokensLength();
        for (uint256 i = 0; i < tokensLength; i++) {
            address token = defaultTokenRegistry.tokens(i);
            (
                ,
                ,
                bool isSupportedOnCompound,
                address cToken,
                address chainLinkOracle,
                uint256 borrowLTV
            ) = defaultTokenRegistry.tokenInfo(token);
            // add token
            ITokenRegistry(pool.tokenRegistry).addTokenByPoolRegistry(
                token,
                isSupportedOnCompound,
                cToken,
                chainLinkOracle,
                borrowLTV
            );
            // approve token
            if (cToken != address(0) && token != NATIVE_TOKEN) {
                ISavingAccount(pool.savingAccount).approveAll(token);
            }
        }

        // 2. Create Fixed price oracle for token
        FixedPriceOracleNative fixedPriceOracleNative = new FixedPriceOracleNative(
            address(gemGlobalConfig),
            _baseToken,
            _initTokenPriceInUSD8
        );
        pool.fixedPriceOracle = address(fixedPriceOracleNative);

        // 3. add user's collateral token
        ITokenRegistry(pool.tokenRegistry).addTokenByPoolRegistry(
            _baseToken,
            false, // token is not supported on Compound
            address(0), // cToken address is zero as its not supported on Compound
            address(fixedPriceOracleNative),
            _borrowLTV
        );

        pool.baseToken = _baseToken;
        pool.poolStatus = PoolStatus.Initialized;

        // avoid taking fee when deploying DeFiner default pool with poolId=0
        if (_poolId != 0) {
            uint256 poolCreationFeeInNative = gemGlobalConfig.getPoolCreationFeeInNative();
            require(msg.value >= poolCreationFeeInNative, "insuffecient fee");
            uint256 extraAmt = msg.value - poolCreationFeeInNative;

            // send pool creation fee to deFinerCommunityFund
            gemGlobalConfig.deFinerCommunityFund().transfer(poolCreationFeeInNative);
            // send extra fee to the sender
            payable(msg.sender).transfer(extraAmt);
        }

        emit NewPoolInitialized(_poolId);
    }

    /**
     * @param _poolId pool id of the pool
     * @param _maturesOn maturity date when the pool matures (date time in epoch format)
     * @param _minBorrowAPRInPercent minimum borrow APR in percentage. ex: 3 for 3%
     * @param _maxBorrowAPRInPercent maximum borrow APR in percentage. ex: 150 for 150%
     * @param _tokens array of tokens for which mining speeds to be configured.
     * @param _depositMiningSpeeds deposit mining speeds of the tokens.
     * @param _borrowMiningSpeeds borrow mining speeds of the tokens.
     */
    function createNewPoolStep3(
        uint256 _poolId,
        uint256 _maturesOn,
        uint256 _minBorrowAPRInPercent,
        uint256 _maxBorrowAPRInPercent,
        address[] calldata _tokens,
        uint256[] calldata _depositMiningSpeeds,
        uint256[] calldata _borrowMiningSpeeds
    ) external {
        Pool storage pool = pools[_poolId];
        require(msg.sender == pool.poolCreator, "not a pool creator");
        require(pool.poolStatus == PoolStatus.Initialized, "pool should be Initialized");

        // _maturesOn == 0 (NONE) || _maturesOn > currentTime
        require(_maturesOn == 0 || _maturesOn > block.timestamp, "past maturity date");
        // _maturesOn must be less than 10 years from today
        require(_maturesOn <= block.timestamp + MAX_MATURITY_DATE, "invalid maturity");

        // arrays
        require(_tokens.length == _depositMiningSpeeds.length, "array length not match");
        require(_depositMiningSpeeds.length == _borrowMiningSpeeds.length, "array length not match");

        // borrowAPR
        require(_minBorrowAPRInPercent <= _maxBorrowAPRInPercent, "_minBorrowAPRInPercent > _maxBorrowAPRInPercent");
        require(_minBorrowAPRInPercent >= MIN_APR, "_minBorrowAPRInPercent is out-of-bound");
        require(_maxBorrowAPRInPercent <= MAX_APR, "_maxBorrowAPRInPercent is out-of-bound");

        pool.maturesOn = _maturesOn;

        // configure SavingAccount
        // -----------------------
        // baseToken is treated as miningToken
        ISavingAccount(pool.savingAccount).configure(pool.baseToken, pool.baseToken, _maturesOn);

        // Configure loan APR
        // -------------------
        uint256 rateCurveConstant = _minBorrowAPRInPercent * 10**16; // because 10^18 = 100%
        IGlobalConfig(pool.globalConfig).updateRateCurveConstant(rateCurveConstant);
        uint256 _maxBorrowAPR = _maxBorrowAPRInPercent * 10**16;
        IBank(pool.bank).configureMaxUtilToCalcBorrowAPR(_maxBorrowAPR);

        // update deposit/borrow mining speeds
        // ------------------------------------
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            uint256 depositMiningSpeed = _depositMiningSpeeds[i];
            uint256 borrowMiningSpeed = _borrowMiningSpeeds[i];
            ITokenRegistry(pool.tokenRegistry).updateMiningSpeed(token, depositMiningSpeed, borrowMiningSpeed);
        }

        pool.poolStatus = PoolStatus.Configured;
        emit NewPoolConfigured(_poolId);
    }

    function isAnyPoolUninitialized(address _creator) public view returns (uint256[] memory unInitPools) {
        uint256[] memory poolIds = creatorToPools[_creator];
        uint256 len = poolIds.length;
        uint256 unInitPoolsCount = 0;
        for (uint256 i = 0; i < len; i++) {
            if (pools[poolIds[i]].poolStatus == PoolStatus.Configured) continue;
            unInitPoolsCount++;
        }

        unInitPools = new uint256[](unInitPoolsCount);

        uint256 j = 0;
        for (uint256 i = 0; i < len; i++) {
            if (pools[poolIds[i]].poolStatus == PoolStatus.Configured) continue;
            unInitPools[j++] = poolIds[i];
        }
    }

    function isPoolConfigured(uint256 _poolId) public view returns (bool) {
        Pool memory pool = pools[_poolId];
        return (pool.poolStatus == PoolStatus.Configured);
    }

    function getPoolStatus(uint256 _poolId) external view returns (uint8) {
        return uint8(pools[_poolId].poolStatus);
    }

    function getPoolsByCreator(address _creator) external view returns (uint256[] memory) {
        return creatorToPools[_creator];
    }
}
