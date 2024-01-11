//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";
import "./INonfungiblePositionManager.sol";
import "./IInitialLiquidityVaultEvent.sol";
import "./IInitialLiquidityVaultAction.sol";
import "./IEventLog.sol";

import "./TickMath.sol";

import "./SafeERC20.sol";
import "./InitialLiquidityVaultStorage.sol";

import "./VaultStorage.sol";
import "./ProxyAccessCommon.sol";

//import "./console.sol";

contract InitialLiquidityVault is
    InitialLiquidityVaultStorage,
    VaultStorage,
    ProxyAccessCommon,
    IInitialLiquidityVaultEvent,
    IInitialLiquidityVaultAction
{
    using SafeERC20 for IERC20;

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "Vault: zero address");
        _;
    }

    modifier nonZero(uint256 _value) {
        require(_value > 0, "Vault: zero value");
        _;
    }

    modifier readyToCreatePool() {
        require(boolReadyToCreatePool, "Vault: not ready to CreatePool");
        _;
    }

    modifier beforeSetReadyToCreatePool() {
        require(!boolReadyToCreatePool, "Vault: already ready to CreatePool");
        _;
    }

    modifier afterSetUniswap() {
        require(
            address(UniswapV3Factory) != address(0)
            && address(NonfungiblePositionManager) != address(0)
            && address(TOS) != address(0)
            ,
            "Vault: before setUniswap");
        _;
    }

    ///@dev constructor
    constructor() {
    }

    /// @inheritdoc IInitialLiquidityVaultAction
    function setBaseInfo(
        string memory _name,
        address _token,
        address _owner
        )
        external override
        onlyOwner beforeSetReadyToCreatePool
    {
        require(bytes(name).length == 0,"already set");
        name = _name;
        token = IERC20(_token);
        if(!isAdmin(_owner)){
            _setupRole(PROJECT_ADMIN_ROLE, _owner);
        }

        emit SetBaseInfo(_name, _token, _owner);
    }

    /// @inheritdoc IInitialLiquidityVaultAction
    function setBoolReadyToCreatePool(
        bool _boolReadyToCreatePool
        )
        public override
        onlyOwner
    {
        require(boolReadyToCreatePool != _boolReadyToCreatePool, "same boolReadyToCreatePool");
        boolReadyToCreatePool = _boolReadyToCreatePool;

        emit SetBoolReadyToCreatePool(_boolReadyToCreatePool);
    }

    /// @inheritdoc IInitialLiquidityVaultAction
    function setInitialPrice(
        uint256 tosPrice,
        uint256 tokenPrice,
        uint160 initSqrtPrice
        )
        public override
        onlyOwner beforeSetReadyToCreatePool
    {
        initialTosPrice = tosPrice;
        initialTokenPrice = tokenPrice;
        initSqrtPriceX96 = initSqrtPrice;

        emit SetInitialPrice(tosPrice, tokenPrice, initSqrtPrice);
    }

    /// @inheritdoc IInitialLiquidityVaultAction
    function initialize(
        uint256 _totalAllocatedAmount
    )
        external override onlyOwner afterSetUniswap
    {
        require(_totalAllocatedAmount <= token.balanceOf(address(this)), "need to input the token");
        totalAllocatedAmount = _totalAllocatedAmount;

        emit Initialized(_totalAllocatedAmount);
    }

    /// @inheritdoc IInitialLiquidityVaultAction
    function setUniswapInfo(
        address poolfactory,
        address npm
        )
        external override
        onlyProxyOwner
    {
        require(poolfactory != address(0) && poolfactory != address(UniswapV3Factory), "zero or same UniswapV3Factory");
        require(npm != address(0) && npm != address(NonfungiblePositionManager), "zero or same npm");

        UniswapV3Factory = IUniswapV3Factory(poolfactory);
        NonfungiblePositionManager = INonfungiblePositionManager(npm);

        emit SetUniswapInfo(poolfactory, npm);
    }

    /// @inheritdoc IInitialLiquidityVaultAction
    function setTokens(
            address tos,
            uint24 _fee
        )
        external override
        onlyProxyOwner beforeSetReadyToCreatePool
    {
        require(tos != address(0) && tos != address(TOS), "same tos");

        TOS = IERC20(tos);
        fee = _fee;

        if(fee == 500) tickSpacings = 10;
        else if(fee == 3000) tickSpacings = 60;
        else if(fee == 10000) tickSpacings = 200;

        emit SetTokens(tos, _fee, tickSpacings);
    }

    /// @inheritdoc IInitialLiquidityVaultAction
    function changeToken(address _token) external override onlyOwner beforeSetReadyToCreatePool
    {
        token = IERC20(_token);

        emit ChangedToken(_token);
    }

    /// @inheritdoc IInitialLiquidityVaultAction
    function setInitialPriceAndCreatePool(
        uint256 tosPrice,
        uint256 tokenPrice,
        uint160 initSqrtPrice
    ) external override onlyOwner beforeSetReadyToCreatePool
    {
        setInitialPrice(tosPrice, tokenPrice, initSqrtPrice);
        setBoolReadyToCreatePool(true);
        setPool();

        address getPool = UniswapV3Factory.getPool(address(TOS), address(token), fee);
        require(getPool == address(pool), "different pool address");
        (uint160 sqrtPriceX96,,,,,,) =  pool.slot0();
        require(sqrtPriceX96 > 0, "price is zero");
    }


    /// @inheritdoc IInitialLiquidityVaultAction
    function setPool()
        public override afterSetUniswap readyToCreatePool
    {
        address getPool = UniswapV3Factory.getPool(address(TOS), address(token), fee);
        if(getPool == address(0)){
            address _pool = UniswapV3Factory.createPool(address(TOS), address(token), fee);
            require(_pool != address(0), "createPool fail");
            getPool = _pool;
        }
        pool = IUniswapV3Pool(getPool);
        token0Address = pool.token0();
        token1Address = pool.token1();

        if(initSqrtPriceX96 > 0){
            setPoolInitialize(initSqrtPriceX96);
        }

        emit SetPool(address(pool), token0Address, token1Address);
    }

    /// @inheritdoc IInitialLiquidityVaultAction
    function setPoolInitialize(uint160 inSqrtPriceX96)
        public nonZeroAddress(address(pool)) override readyToCreatePool
    {
        (uint160 sqrtPriceX96,,,,,,) =  pool.slot0();
        if(sqrtPriceX96 == 0){
            pool.initialize(inSqrtPriceX96);

            emit SetPoolInitialized(inSqrtPriceX96);
        }
    }

    /// @inheritdoc IInitialLiquidityVaultAction
    function computePoolAddress(address tokenA, address tokenB, uint24 _fee)
        public view override returns (address pool, address token0, address token1)
    {
        bytes32  POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

        token0 = tokenA;
        token1 = tokenB;

        if(token0 > token1) {
            token0 = tokenB;
            token1 = tokenA;
        }

        pool = address( uint160(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        address(UniswapV3Factory),
                        keccak256(abi.encode(token0, token1, _fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            ))
        );

    }

    /// @inheritdoc IInitialLiquidityVaultAction
    function getMinTick() public view override returns (int24){
           return (TickMath.MIN_TICK / tickSpacings) * tickSpacings ;
    }

    /// @inheritdoc IInitialLiquidityVaultAction
    function getMaxTick() public view override  returns (int24){
           return (TickMath.MAX_TICK / tickSpacings) * tickSpacings ;
    }

    function getSqrtRatioAtTick(int24 tick) public pure returns (uint160) {
        return TickMath.getSqrtRatioAtTick(tick);
    }

    function getTickAtSqrtRatio(uint160 sqrtPriceX96) public pure  returns (int24) {
        return TickMath.getTickAtSqrtRatio(sqrtPriceX96);
    }

    function checkBalance(uint256 tosBalance, uint256 tokenBalance) internal  {
        require(TOS.balanceOf(address(this)) >= tosBalance, "tos is insufficient.");
        require(token.balanceOf(address(this)) >= tokenBalance, "token is insufficient.");
         if(tosBalance > TOS.allowance(address(this), address(NonfungiblePositionManager)) ) {
                require(TOS.approve(address(NonfungiblePositionManager),TOS.totalSupply()),"TOS approve fail");
        }

        if(tokenBalance > token.allowance(address(this), address(NonfungiblePositionManager)) ) {
            require(token.approve(address(NonfungiblePositionManager),token.totalSupply()),"token approve fail");
        }
    }

     /// @inheritdoc IInitialLiquidityVaultAction
    function mint()
        external override readyToCreatePool nonReentrant
        nonZeroAddress(address(pool))
        nonZeroAddress(token0Address)
        nonZeroAddress(token1Address)
    {
        (uint160 sqrtPriceX96,,,,,,) =  pool.slot0();
        require(sqrtPriceX96 > 0, "pool is not initialized");

        if(lpToken == 0)  initialMint();
        else increaseLiquidity();
    }

    function initialMint() internal
    {
        require(lpToken == 0, "already minted");

        uint256 tosBalance =  TOS.balanceOf(address(this));
        uint256 tokenBalance =  token.balanceOf(address(this));

        require(tosBalance > 1 ether && tokenBalance > 1 ether, "balance is insufficient");
        checkBalance(tosBalance, tokenBalance);

        int24 tickLower = getMinTick();
        int24 tickUpper = getMaxTick();

        uint256 amount0Desired = tosBalance;
        uint256 amount1Desired = tokenBalance;

        if(token0Address != address(TOS)){
            amount0Desired = tokenBalance;
            amount1Desired = tosBalance;
        }

        (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        ) = NonfungiblePositionManager.mint(INonfungiblePositionManager.MintParams(
                token0Address, token1Address, fee, tickLower, tickUpper,
                amount0Desired, amount1Desired, 0, 0,
                address(this), block.timestamp + 100000
            )
        );

        require(tokenId > 0, "tokenId is zero");
        lpToken = tokenId;
        //LogEvent("MintedInVault", abi.encode(msg.sender, tokenId, liquidity, amount0, amount1));
        emit MintedInVault(msg.sender, tokenId, liquidity, amount0, amount1);
    }


    function increaseLiquidity() internal
    {
        require(lpToken > 0, "It is not minted yet");
        uint256 tosBalance =  TOS.balanceOf(address(this));
        uint256 tokenBalance =  token.balanceOf(address(this));

        require(tosBalance > 1 ether || tokenBalance > 1 ether, "balance is insufficient");
        checkBalance(tosBalance, tokenBalance);

        uint256 amount0Desired = tosBalance;
        uint256 amount1Desired = tokenBalance;

        if(token0Address != address(TOS)){
            amount0Desired = tokenBalance;
            amount1Desired = tosBalance;
        }

        (uint128 liquidity, uint256 amount0, uint256 amount1) = NonfungiblePositionManager.increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams(
                lpToken, amount0Desired, amount1Desired, 0, 0, block.timestamp + 100000));

        //LogEvent("IncreaseLiquidityInVault", abi.encode(lpToken, liquidity, amount0, amount1));
        emit IncreaseLiquidityInVault(lpToken, liquidity, amount0, amount1);
    }

    /// @inheritdoc IInitialLiquidityVaultAction
    function collect()
        external override
        nonZeroAddress(address(pool))
        nonReentrant
    {
        require(lpToken > 0, "It is not minted yet");
        (,,,,,,,,,,uint128 tokensOwed0, uint128 tokensOwed1) = NonfungiblePositionManager.positions(lpToken);
        require(tokensOwed0 > 0 || tokensOwed1 > 0, "there is no collectable amount");

        (
            uint256 amount0,
            uint256 amount1
        ) = NonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(
                lpToken, address(this), tokensOwed0, tokensOwed1
            )
        );

        emit CollectInVault(lpToken, amount0, amount1);
    }

    /*
    /// @inheritdoc IInitialLiquidityVaultAction
    function withdraw(address _token, address _account, uint256 _amount)
        external override nonReentrant
        onlyOwner
    {
        if(_token == address(TOS)) require(lpToken > 0, "It is not minted yet");
        require(token.balanceOf(address(this)) < 1 ether, "Has project tokens");
        require(_token != address(token), "project token can not withdraw");
        require(_amount <= IERC20(_token).balanceOf(address(this)), "balance is insufficient");

        IERC20(_token).safeTransfer(_account, _amount);

        emit WithdrawalInVault(msg.sender, _token, _account, _amount);
    }
    */

}
