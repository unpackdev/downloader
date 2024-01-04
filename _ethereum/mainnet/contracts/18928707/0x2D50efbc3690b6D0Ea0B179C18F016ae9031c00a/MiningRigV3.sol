// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./UpInterfaces.sol";
import "./ReentrancyGuard.sol";
import "./ISpawnManager.sol";
import "./IActiveChecker.sol";
import "./IUniswapV3Pool.sol";
import "./IUniswapV3Factory.sol";
import "./MerkleProof.sol";
import "./MathHelpers.sol";
import "./ExecutorManager.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint amount) external;
}

contract MiningClaims {
    event ClaimBooster(address indexed claimer, uint256 boosterId);

    error CannotClaimUserBooster();
    error InvalidUserBooster();
    error BoosterInactive();

    struct UserAddedBooster {
        bytes32 merkleRoot;
        string treeDataURI;
        uint256 boosterRate;
        uint256 boostType;
        bool active;
    }

    mapping(uint256 => mapping(address => bool)) private _claimedByAddress;
    uint256 internal _currentUserBoostID = 0;
    mapping(uint256 => UserAddedBooster) private _userBoosters;

    modifier _validUserBoosterId(uint256 id) {
        if (_currentUserBoostID == 0 || id > _currentUserBoostID) revert InvalidUserBooster();
        if (_userBoosters[id].active != true) revert BoosterInactive();
        _;
    }

    function _addUserBoostTree(bytes32 _merkleRoot, string calldata _treeDataURI, uint256 _boosterRate, uint256 _boostType) internal {
        _userBoosters[++_currentUserBoostID] = UserAddedBooster({
            merkleRoot: _merkleRoot,
            active: true,
            treeDataURI: _treeDataURI,
            boosterRate: _boosterRate,
            boostType: _boostType
        });
    }

    function _inactivateBooster(uint256 _id) _validUserBoosterId(_id) internal {
        _userBoosters[_id].active = false;
    }

    function _readUserBoosterTree(uint256 _id) internal view _validUserBoosterId(_id) returns (UserAddedBooster memory) {
        return _userBoosters[_id];
    }

    function _canClaimUserBoost(
        address _address,
        uint256 _userBoostId,
        bytes32[] calldata merkleProof
    ) _validUserBoosterId(_userBoostId) internal view returns (bool) {
        if (_claimedByAddress[_userBoostId][_address]) {
            return(false);
        }

        return(MerkleProof.verify(
            merkleProof,
            _userBoosters[_userBoostId].merkleRoot,
            keccak256(bytes.concat(keccak256(abi.encode(_address))))
        ));
    }

    function _claimUserBoost(
        address _address,
        uint256 _boosterId,
        bytes32[] calldata _merkleProof
    ) _validUserBoosterId(_boosterId) internal returns(uint256) {
        if (_canClaimUserBoost(_address, _boosterId, _merkleProof) != true) revert CannotClaimUserBooster();
        _claimedByAddress[_boosterId][_address] = true;
        return(_userBoosters[_boosterId].boosterRate);
    }

    function _claimMultipleUserBoosts(
        address _address,
        uint256[] calldata _boosterIDs,
        bytes32[][] calldata _merkleProofs
    ) internal returns(uint256 sum) {
        require(_boosterIDs.length == _merkleProofs.length, 'Length Mismatch');

        for (uint256 i = 0; i < _boosterIDs.length; i++) {
            sum += _claimUserBoost(_address, _boosterIDs[i], _merkleProofs[i]);
        }

        return(sum);
    }
}

contract RigTokenBoosterManager is MathHelpers {
    error BoosterOverMaxCycle();
    error BoosterDepositLimitReached();
    error BoosterEnded();
    error BoosterDoesNotExist(uint256 boosterId);

    struct TokenBoosterParams {
        IERC20 token;
        uint256 multiplier;
        uint256 boosterLastsFor; // Zero is infinite
        uint256 maxDepositAmount;
        uint256 maxCycles;
        uint256 usesPerCycle;
    }

    struct TokenBooster {
        IERC20 token;
        uint256 multiplier;
        uint256 boosterStartTime;
        uint256 boosterEndTime; // Zero is infinite
        bool ended;
        uint256 useCount;
        uint256 totalDeposited;
        uint256 maxDepositAmount;
        uint256 maxCycles;
        uint256 usesPerCycle;
    }

    mapping(uint256 => TokenBooster) internal _tokenBoosters;
    uint256 private _nextTokenBoosterId;

    modifier validTokenBoosterId(uint256 boosterId) {
        if (boosterId == 0 || _nextTokenBoosterId < boosterId) revert BoosterDoesNotExist(boosterId);
        if (_tokenBoosters[boosterId].ended) revert BoosterEnded();
        _;
    }

    function _addTokenBooster(TokenBoosterParams calldata params) internal {
        uint256 boosterEndTime;

        if (params.boosterLastsFor != 0) {
            boosterEndTime = block.timestamp + params.boosterLastsFor;
        }

        _tokenBoosters[++_nextTokenBoosterId] = TokenBooster({
            token: params.token,
            multiplier: params.multiplier,
            boosterStartTime: block.timestamp,
            useCount: 0,
            ended: false,
            boosterEndTime: boosterEndTime,
            totalDeposited: 0,
            maxDepositAmount: params.maxDepositAmount,
            usesPerCycle: params.usesPerCycle,
            maxCycles: params.maxCycles
        });
    }

    function _getCurrentTokenBoosterId() internal view returns (uint256) {
        return(_nextTokenBoosterId);
    }

    function _getTokenBooster(uint256 boosterId) validTokenBoosterId(boosterId) internal view returns (TokenBooster memory) {
        return(_tokenBoosters[boosterId]);
    }

    function _endBooster(uint256 boosterId) internal {
        require(_tokenBoosters[boosterId].boosterEndTime < block.timestamp, 'Not Ended');
        _tokenBoosters[boosterId].ended = true;
    }

    function _computeTokenBoosterCycleState(uint256 uses, uint256 usesPerCycle, uint256 multiplier) internal pure returns (uint256 currentCycle, uint256 newMultiplier) {
        currentCycle = uses / usesPerCycle;
        newMultiplier = multiplier - ((multiplier * (uses - (currentCycle * usesPerCycle))) / usesPerCycle) + divisionDenominator;
        return(currentCycle, newMultiplier);
    }

    function _incrementBoosterCycleAndGetMultiplier(uint256 _tokenBoosterId) internal returns(uint256) {
        (uint256 boosterCycle, uint256 newMultiplier) = _computeTokenBoosterCycleState(++_tokenBoosters[_tokenBoosterId].useCount, _tokenBoosters[_tokenBoosterId].usesPerCycle, _tokenBoosters[_tokenBoosterId].multiplier);
        if (boosterCycle > _tokenBoosters[_tokenBoosterId].maxCycles) revert BoosterOverMaxCycle();
        return(newMultiplier);
    }

    function _updateBoosterTotalDeposited(uint256 _tokenBoosterId, uint256 _amount) internal {
        // Add the new amount to totalDeposited and check if it is over the max amount
        if ((_tokenBoosters[_tokenBoosterId].totalDeposited += _amount) > _tokenBoosters[_tokenBoosterId].maxDepositAmount) {
            revert BoosterDepositLimitReached();
        }
    }
}

contract MiningRigV3 is ReentrancyGuard, IActiveChecker, MiningClaims, MathHelpers, RigTokenBoosterManager, ExecutorManager {
    event Mine(address indexed miner, uint256 inputAmount, uint256 boosterId, uint256 outputAmount);

    error LPNotInitalized();
    error MiningInvalidValue();
    error BoosterNotWETH();
    error ExceedsMax();
    error UpdateUsedToInvalid();
    error InvalidUseCount();
    error InitialLPAlreadyCreated();

    enum VirtualWeight { LOW, MEDIUM, HIGH }

    IWETH public wethContract;
    IERC20 public pepeContract;
    IERC20 public pondContract;


    uint256 public divisionLP = 20;
    uint24 public poolFee = 3000;
    int24 public delta = 1111;
    IUniswapV3Factory public uniswapFactory;
    ISwapRouter public uniswapRouter;
    INonfungiblePositionManager public nonfungiblePositionManager;

    address public distilleryAddress;

    uint256[] lpTokenIDs;
    uint256 additionalSwapDeadline = 0 seconds;

    uint256 public cycleIndex = 0;
    mapping(address => mapping(uint256 => uint256)) public minedPerCycle;

    uint256 public activeMinedThreshold = 1 ** 18;

    uint256 public usesToOpenSpawn = 5000;
    uint256 public usesLeftForSpawn = 5000;

    uint256 public rateNumerator = 0;

    ISpawnManager public spawnManager;
    
    constructor(
        IWETH _wethContract,
        IERC20 _pepeContract,
        IERC20 _pondContract,
        ISwapRouter _uniswapRouter,
        INonfungiblePositionManager _nonfungiblePositionManager,
        address _distilleryAddress,
        ISpawnManager _spawnManager,
        IUniswapV3Factory _uniswapFactory
    ) {
        _addExecutor(msg.sender);
        _addExecutor(_distilleryAddress);

        wethContract = _wethContract;
        pepeContract = _pepeContract;
        pondContract = _pondContract;
        uniswapRouter = _uniswapRouter;
        distilleryAddress = _distilleryAddress;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        spawnManager = _spawnManager;
        uniswapFactory = _uniswapFactory;

        wethContract.approve(address(uniswapRouter), type(uint256).max);
        wethContract.approve(address(nonfungiblePositionManager), type(uint256).max);
        pepeContract.approve(address(nonfungiblePositionManager), type(uint256).max);
        pepeContract.approve(address(uniswapRouter), type(uint256).max);
        pepeContract.approve(address(spawnManager), type(uint256).max);
    }

    function updateSpawnManager(ISpawnManager _spawnManager) onlyExecutor() external {
        spawnManager = _spawnManager;
    }

    function updateDelta(int24 _delta) onlyExecutor() external {
        delta = _delta;
    }

    function updatePoolFee(uint24 _poolFee) onlyExecutor() external {
        poolFee = _poolFee;
    }

    function updateUniswapFactory(IUniswapV3Factory _uniswapFactory) onlyExecutor() external {
        uniswapFactory = _uniswapFactory;
    }

    function updateSpawnValue(uint256 _usesToOpenSpawn, bool updateUsed, uint256 updateUsedTo) onlyExecutor() external {
        usesToOpenSpawn = _usesToOpenSpawn;

        if ((updateUsedTo == 0) == updateUsed) revert UpdateUsedToInvalid(); 

        if (updateUsed) {
            usesLeftForSpawn = updateUsedTo;
        }
    }

    
    function addTokenBooster(TokenBoosterParams calldata params) onlyExecutor() external {
        params.token.approve(address(uniswapRouter), type(uint256).max);
        _addTokenBooster(params);
    }

    function getTokenBooster(uint256 tokenBoosterId) external view returns (TokenBooster memory) {
        return(_getTokenBooster(tokenBoosterId));
    }

    function _updateMinedForCurrentCycle(address _address, uint256 additionalAmount) private {
        minedPerCycle[_address][cycleIndex] += additionalAmount;
    }

    function isActive(address toCheck) external view returns (bool) {
        return(minedPerCycle[toCheck][cycleIndex] > activeMinedThreshold);
    }

    function latestLPToken() public view returns (uint256) {
        if (lpTokenIDs.length == 0) revert LPNotInitalized();
        return lpTokenIDs[lpTokenIDs.length - 1];
    }

    function readLPTokens() external view returns (uint256[] memory) {
        return(lpTokenIDs);
    }

    function _mintLiquidityPosition(uint desiredPepeAmount, uint desiredWethAmount) internal returns (uint256 tokenId, uint128 liquidity, uint256 pepeAmount, uint256 wethAmount) {
        int24 tickSpacing = 60;

        // (, int24 tick) = sqrt96Tick(pepeContract);
        int24 tick = _getTick(pepeContract);

        (tokenId, liquidity, pepeAmount, wethAmount) = nonfungiblePositionManager.mint(INonfungiblePositionManager.MintParams({
            token0: address(pepeContract),
            token1: address(wethContract),
            fee: poolFee,
            tickLower: ((tick - delta) / tickSpacing) * tickSpacing,
            tickUpper: ((tick + delta) / tickSpacing) * tickSpacing,
            amount0Desired: desiredPepeAmount,
            amount1Desired: desiredWethAmount,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp
        }));

        lpTokenIDs.push(tokenId);

        return (tokenId, liquidity, pepeAmount, wethAmount);
    }

    function virtualWeightCast(VirtualWeight _weight) internal pure returns (uint256){
        return 16 * (16 + uint(_weight));
    }

    function _decreaseAndDistill(uint256 tokenId) internal returns(uint256 pepeAmount, uint256 wethAmount) {
        (,,,,,,,uint128 liquidity,,,,) = nonfungiblePositionManager.positions(tokenId);

        (pepeAmount, wethAmount) = nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams({
            tokenId: tokenId,
            liquidity: liquidity,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        }));
    }

    function createInitialLP(uint256 pepeAmount, uint256 wethAmount) external onlyExecutor() {
        if(lpTokenIDs.length != 0) revert InitialLPAlreadyCreated();

        require(wethContract.transferFrom(msg.sender, address(this), wethAmount), "Could not transfer WETH");
        require(pepeContract.transferFrom(msg.sender, address(this), pepeAmount), "Could not transfer pepe");

        (,,uint256 addedPepe, uint256 addedWeth) = _mintLiquidityPosition(pepeAmount, wethAmount);

        if (addedPepe < pepeAmount) {
            require(pepeContract.transfer(msg.sender, pepeAmount - addedPepe), "Could not return pepe");
        }

        if (addedWeth < wethAmount) {
            require(wethContract.transfer(msg.sender, wethAmount - addedWeth), "Could not return weth");
        }
    }

    function _addLiquidity(uint256 pepeAmount, uint256 wethAmount) internal returns (uint128 liquidity, uint256 pepeValue, uint256 weight) {
        return nonfungiblePositionManager.increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams({
            tokenId: latestLPToken(),
            // virtualWeightCast move to earlier
            amount0Desired: pepeAmount,
            amount1Desired: wethAmount,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp + additionalSwapDeadline
        }));
    }

    function _collectLPFees(uint256 _lpTokenId, address recipient) internal returns (uint256, uint256) {
        return nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams({
            tokenId: _lpTokenId,
            recipient: recipient,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        }));
    }

    function collectLPFees(uint256 _lpTokenId) external {
        _collectLPFees(_lpTokenId, distilleryAddress);
    }

    function _swapTokens(IERC20 from, IERC20 to, uint256 amountIn) internal returns (uint256) {
        return uniswapRouter.exactInputSingle(ISwapRouter.ExactInputSingleParams({
            tokenIn: address(from),
            tokenOut: address(to),
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp + additionalSwapDeadline,
            amountIn: amountIn,
            amountOutMinimum: 2,
            sqrtPriceLimitX96: 0
        }));
    }

    function _weightLPDown(uint256 amount) internal pure returns (uint256) {
        return amount / virtualWeightCast(VirtualWeight.LOW);
    }

    function updateRateNumerator(uint256 _rateNumerator) onlyExecutor() external {
        rateNumerator = _rateNumerator;
    }

    function updateDivisionLP(uint256 _divisionLP) onlyExecutor() external {
        divisionLP = _divisionLP;
    }

    function updateActiveMinedThreshold(uint256 _activeMinedThreshold) onlyExecutor() external {
        activeMinedThreshold = _activeMinedThreshold;
    }

    function computeBoosterCycleState(uint256 uses, uint256 usesPerCycle, uint256 multiplier) external pure returns (uint256 currentCycle, uint256 newMultiplier) {
        return(_computeTokenBoosterCycleState(uses, usesPerCycle, multiplier));
    }

    function _getTick(IERC20 _token) internal view returns (int24) {
        IUniswapV3Pool _pool = IUniswapV3Pool(uniswapFactory.getPool(address(_token), address(wethContract), poolFee));
        (,int24 tick,,,,,) = _pool.slot0();
        return (tick);
    }

    function _remint() internal {
        (uint256 distilledPepe, uint256 distilledWETH) = _decreaseAndDistill(latestLPToken());

        _mintLiquidityPosition(distilledPepe / divisionLP, distilledWETH / divisionLP);

        uint256 spawnAmount = pepeContract.balanceOf(address(this));
        spawnManager.createSpawn(spawnAmount);
        pepeContract.transfer(address(spawnManager), spawnAmount);
    }

    function _swapToWETHIfNeeded(IERC20 _inToken, uint256 _inAmount) private returns (uint256 wethOut) {
        if (address(_inToken) == address(wethContract)) {
            return(_inAmount);
        } else {
            return(_swapTokens(_inToken, wethContract, _inAmount));
        }
    }

    function _mine(
        address _miner,
        uint256 _tokenBoosterId,
        uint256 _amount,
        uint256[] calldata _userBoostIDs,
        bytes32[][] calldata _userBoostMerkleProofs
    ) private returns(uint256 pndcAmount, uint256 boosterMultiplier) {
        _updateBoosterTotalDeposited(_tokenBoosterId, _amount);

        uint256 wethValue = _amount;
        if (address(_tokenBoosters[_tokenBoosterId].token) != address(wethContract)) {
            wethValue = _swapTokens(_tokenBoosters[_tokenBoosterId].token, wethContract, _amount);
        }

        _updateMinedForCurrentCycle(_miner, wethValue);

        uint256 toConvertWeth = wethValue >> 1;
        uint256 recievedPepe = _swapTokens(wethContract, pepeContract, toConvertWeth);

        (,,uint256 liquidity) = _addLiquidity(_weightLPDown(recievedPepe), _weightLPDown(wethValue - toConvertWeth));

        uint256 additionalBoosterWeight = 0;
        if ((_userBoostIDs.length + _userBoostMerkleProofs.length) > 0) {
            additionalBoosterWeight = _claimMultipleUserBoosts(_miner, _userBoostIDs, _userBoostMerkleProofs);
        }

        boosterMultiplier = _incrementBoosterCycleAndGetMultiplier(_tokenBoosterId);

        // Perform rewards calc here
        pndcAmount = _multiplyWithNumerator(_multiplyWithNumerator(liquidity, rateNumerator), boosterMultiplier + additionalBoosterWeight);

        if (pndcAmount == 0) revert MiningInvalidValue();

        require(pondContract.transfer(_miner, pndcAmount));

        if (--usesLeftForSpawn == 0) {
            _remint();

            if (++cycleIndex < 5) {
                usesToOpenSpawn = 5000 - (cycleIndex * 1000);
            }

            usesLeftForSpawn = usesToOpenSpawn;
        }

        emit Mine(_miner, _amount, _tokenBoosterId, pndcAmount);

        return(pndcAmount, boosterMultiplier);
    }

    function mine(
        uint256 _tokenBoosterId,
        uint256 _amount,
        uint256[] calldata _userBoostIDs,
        bytes32[][] calldata _userBoostMerkleProofs
    ) nonReentrant validTokenBoosterId(_tokenBoosterId) external payable returns(uint256 pndcAmount, uint256 boosterMultiplier) {
        if (_amount == 0) revert MiningInvalidValue();

        if (msg.value != 0) {
            if (msg.value != _amount) revert MiningInvalidValue();
            if (address(_tokenBoosters[_tokenBoosterId].token) != address(wethContract)) revert BoosterNotWETH();
            wethContract.deposit{ value: msg.value }();
        } else {
            SafeERC20.safeTransferFrom(_tokenBoosters[_tokenBoosterId].token, msg.sender, address(this), _amount);
        }

        return(_mine(msg.sender, _tokenBoosterId, _amount, _userBoostIDs, _userBoostMerkleProofs));
    }

    function depositWeth() external payable {
        wethContract.deposit{ value: address(this).balance }();
    }

    function deposit(IERC20 token, uint256 amount) external onlyExecutor() {
        token.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(IERC20 token, uint256 amount) external onlyExecutor() {
        token.transfer(msg.sender, amount);
    }

    function addUserBoostTree(bytes32 _merkleRoot, string calldata _treeDataURI, uint256 _boosterRate, uint256 _boosterType) external onlyExecutor() {
        _addUserBoostTree(_merkleRoot, _treeDataURI, _boosterRate, _boosterType);
    }

    function readUserBoosterTree(uint256 id) external view returns (UserAddedBooster memory) {
        return(_readUserBoosterTree(id));
    }

    function canClaimUserBoost(
        address _address,
        uint256 _event,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        return(_canClaimUserBoost(_address, _event, merkleProof));
    }

    function currentUserBoostID() external view returns(uint256) {
        return(_currentUserBoostID);
    }

    function getCurrentTokenBoosterId() external view returns (uint256 currentTokenBoosterId){
        return(_getCurrentTokenBoosterId());
    }

    function addExecutor(address _toAdd) onlyExecutor external override {
        pepeContract.approve(_toAdd, type(uint256).max);
        wethContract.approve(_toAdd, type(uint256).max);
        pondContract.approve(_toAdd, type(uint256).max);
        _addExecutor(_toAdd);
    }

    function removeExecutor(address _toRemove) onlyExecutor external override {
        pepeContract.approve(_toRemove, 0);
        wethContract.approve(_toRemove, 0);
        pondContract.approve(_toRemove, 0);
        _removeExecutor(_toRemove);
    }

    function endTokenBooster(uint256 tokenBoosterId) onlyExecutor() external {
        _endBooster(tokenBoosterId);
    }
}
