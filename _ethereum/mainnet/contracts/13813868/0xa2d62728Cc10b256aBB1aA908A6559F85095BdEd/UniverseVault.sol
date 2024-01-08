// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

/*
 *        _   _   _  _     ___   __   __   ___     ___     ___     ___
 *       | | | | | \| |   |_ _|  \ \ / /  | __|   | _ \   / __|   | __|
 *       | |_| | | .` |    | |    \ V /   | _|    |   /   \__ \   | _|
 *        \___/  |_|\_|   |___|   _\_/_   |___|   |_|_\   |___/   |___|
 *      _|"""""|_|"""""|_|"""""|_| """"|_|"""""|_|"""""|_|"""""|_|"""""|
 *      "`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'
 *
 */

import "./Ownable.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./FixedPoint96.sol";
import "./IUniswapV3Pool.sol";
import "./FullMath.sol";
import "./PoolAddress.sol";
import "./PositionHelper.sol";
import "./IUniverseVault.sol";
import "./IERC20Detail.sol";
import "./UToken.sol";

contract UniverseVault is IUniverseVault, Ownable {

    using SafeERC20 for IERC20Detail;
    using SafeMath for uint256;
    using PositionHelper for PositionHelper.Position;

    // Uni POOL
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    // Important Addresses
    address immutable uniFactory;
    address operator;
    /// @inheritdoc IUniverseVault
    IERC20Detail public immutable override token0;
    /// @inheritdoc IUniverseVault
    IERC20Detail public immutable override token1;
    mapping(address => bool) poolMap;

    // @dev UNIVERSE VERSION   1 - Single Share Token   2 - Double Share Token
    uint8 public constant UNIVERSE_VAULT_VERSION = 2;

    // Core Params
    address swapPool;
    uint8 performanceFee;
    /// @dev For Safety, maximum tick bias from decision
    uint24 diffTick;
    /// @dev Profit distribution ratio, 50%-150% param for rate of Token0
    uint8 profitScale = 100;
    /// @dev control maximum lost for the current position, prevent attack by price manipulate; param <= 1e5
    uint32 safetyParam = 95000;

    struct SafeAddLiq {
        int24 positionTick;
        int24 depositMaxOffsetTick;
        int24 tickBias0; // level0 safe tick bias
        int24 tickBias1; // level1 safe tick bias
        uint24 pct0; // level0 safe pct (principal / pct0 = deposit)
        uint24 pct1; // level1 safe pct (principal / pct1 = deposit)
    }
    /// @inheritdoc IUniverseVault
    SafeAddLiq public override safeAddLiq = SafeAddLiq({
        positionTick: 0, // record position Tick When last time reBalance
        depositMaxOffsetTick: 1600,
        tickBias0: 100,
        tickBias1: 300,
        pct0: 50, // 2%
        pct1: 20 // 5%
    });

    struct MaxShares {
        uint256 maxToken0Amt;
        uint256 maxToken1Amt;
        uint256 maxSingeDepositAmt0;
        uint256 maxSingeDepositAmt1;
    }

    /// @inheritdoc IUniverseVault
    MaxShares public override maxShares;

    /// @dev Amount of Token0 & Token1 belongs to protocol
    struct ProtocolFees {
        uint128 fee0;
        uint128 fee1;
    }
    /// @inheritdoc IUniverseVault
    ProtocolFees public override protocolFees;

    /// @inheritdoc IUniverseVault
    PositionHelper.Position public override position;

    /// @dev Share Token for Token0
    UToken public immutable override uToken0;
    /// @dev Share Token for Token1
    UToken public immutable override uToken1;

    /// @dev White list of contract address
    mapping(address => bool) contractWhiteLists;

    constructor(
        address _uniFactory,
        address _poolAddress,
        address _operator,
        address _swapPool,
        uint8 _performanceFee,
        uint24 _diffTick,
        uint256 _maxToken0,
        uint256 _maxToken1,
        uint256 _maxSingeDepositAmt0,
        uint256 _maxSingeDepositAmt1
    ) {
        uniFactory = _uniFactory;
        // pool info
        IUniswapV3Pool pool = IUniswapV3Pool(_poolAddress);
        IERC20Detail _token0 = IERC20Detail(pool.token0());
        IERC20Detail _token1 = IERC20Detail(pool.token1());
        poolMap[_poolAddress] = true;
        poolMap[_swapPool] = true;
        // variable
        operator = _operator;
        swapPool = _swapPool;
        performanceFee = _performanceFee;
        diffTick = _diffTick;
        // Share Token
        uToken0 = new UToken(string(abi.encodePacked('u', _token0.symbol())), _token0.decimals());
        uToken1 = new UToken(string(abi.encodePacked('u', _token1.symbol())), _token1.decimals());
        token0 = _token0;
        token1 = _token1;
        // Control Param
        maxShares = MaxShares({
            maxToken0Amt : _maxToken0,
            maxToken1Amt : _maxToken1,
            maxSingeDepositAmt0 : _maxSingeDepositAmt0,
            maxSingeDepositAmt1 : _maxSingeDepositAmt1
        });
    }

    /* ========== MODIFIERS ========== */

    /// @dev Only be called by the Operator
    modifier onlyManager {
        require(tx.origin == operator, "OM");
        _;
    }

    /* ========== ONLY OWNER ========== */

    /// @inheritdoc IVaultOwnerActions
    function changeManager(address _operator) external override onlyOwner {
        // require(_operator != address(0), "ZA");
        operator = _operator;
        emit ChangeManger(_operator);
    }

    /// @inheritdoc IVaultOwnerActions
    function updateWhiteList(address _address, bool status) external override onlyOwner {
        // require(_address != address(0), "ar");
        contractWhiteLists[_address] = status;
        emit UpdateWhiteList(_address, status);
    }

    /// @inheritdoc IVaultOwnerActions
    function withdrawPerformanceFee(address to) external override onlyOwner {
        require(to != address(0), "ZA");
        ProtocolFees memory pf = protocolFees;
        if(pf.fee0 > 1){
            token0.transfer(to, pf.fee0 - 1);
            pf.fee0 = 1;
        }
        if(pf.fee1 > 1){
            token1.transfer(to, pf.fee1 - 1);
            pf.fee1 = 1;
        }
        protocolFees = pf;
    }

    /* ========== PURE ========== */

    /// @dev Safe Math For uint128
    function _add128(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /// @dev Uint256 to Uint128, check overflow
    function _toUint128(uint256 x) internal pure returns (uint128) {
        assert(x <= type(uint128).max);
        return uint128(x);
    }

    /// @dev Calculate totalValue on Token1
    function netValueToken1(
        uint256 amount0,
        uint256 amount1,
        uint256 priceX96
    ) internal pure returns (uint256 netValue) {
        netValue = FullMath.mulDiv(amount0, priceX96, FixedPoint96.Q96).add(amount1);
    }

    /// @dev Get effective Tick Values
    function tickRegulate(
        int24 _lowerTick,
        int24 _upperTick,
        int24 tickSpacing
    ) internal pure returns (int24 lowerTick, int24 upperTick) {
        lowerTick = PositionHelper._floor(_lowerTick, tickSpacing);
        upperTick = PositionHelper._floor(_upperTick, tickSpacing);
        require(_upperTick > _lowerTick, "Bad Ticks");
    }

    /// @dev amt * totalShare / totalAmt
    function _quantityTransform(
        uint256 newAmt,
        uint256 totalShare,
        uint256 totalAmt
    ) internal pure returns(uint256 newShare){
        if (newAmt != 0) {
            if (totalShare == 0) {
                newShare = newAmt;
            } else {
                newShare = FullMath.mulDiv(newAmt, totalShare, totalAmt);
            }
        }
    }

    /* ========== VIEW ========== */

    /// @dev 50% - 150%, only can change this when reBalance
    function _changeProfitScale(uint8 _profitScale) internal {
        if (_profitScale >= 50 && _profitScale <= 150) {
            profitScale = _profitScale;
        }
    }

    /// @dev Calculate UniswapV3 Pool Address
    function _computeAddress(uint24 fee) internal view returns (address pool) {
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        uniFactory,
                        keccak256(abi.encode(address(token0), address(token1), fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }

    /// @dev Get the pool's balance of token0 Belong to the user
    function _balance0() internal view returns (uint256) {
        return token0.balanceOf(address(this)) - protocolFees.fee0;
    }

    /// @dev Get the pool's balance of token1 Belong to the user
    function _balance1() internal view returns (uint256) {
        return token1.balanceOf(address(this)) - protocolFees.fee1;
    }

    /// @dev Amount to Share. Make Sure All mint and burn after this
    function _calcShare(
        uint256 amount0Desired,
        uint256 amount1Desired
    ) internal view returns (uint256 share0, uint256 share1, uint256 total0, uint256 total1) {
        // read Current Status
        (total0, total1, , ) = _getTotalAmounts(true);
        uint256 ts0 = uToken0.totalSupply();
        uint256 ts1 = uToken1.totalSupply();
        share0 = _quantityTransform(amount0Desired, ts0, total0);
        share1 = _quantityTransform(amount1Desired, ts1, total1);
    }

    /// @dev Share To Amount. Make Sure All mint and burn after this
    function _calcBal(
        uint256 share0,
        uint256 share1
    ) internal view returns (
        uint256 bal0,
        uint256 bal1,
        uint256 free0,
        uint256 free1,
        uint256 rate,
        bool zeroBig
    ) {
        uint256 total0;
        uint256 total1;
        // read Current Status
        (total0, total1, free0, free1) = _getTotalAmounts(false);
        // Calculate the amount to withdraw
        bal0 = _quantityTransform(share0, total0, uToken0.totalSupply());
        bal1 = _quantityTransform(share1, total1, uToken1.totalSupply());
        // calc burn liq rate
        uint256 rate0;
        uint256 rate1;
        if(bal0 > free0){
            rate0 = FullMath.mulDiv(bal0.sub(free0), 1e5, total0.sub(free0));
        }
        if(bal1 > free1){
            rate1 = FullMath.mulDiv(bal1.sub(free1), 1e5, total1.sub(free1));
        }
        if(rate0 >= rate1){
            zeroBig = true;
        }
        rate = Math.max(rate0, rate1);
    }

    function _getTotalAmounts(bool forDeposit) internal view returns (
        uint256 total0,
        uint256 total1,
        uint256 free0,
        uint256 free1
    ) {
        // read in memory
        PositionHelper.Position memory pos = position;
        free0 = _balance0();
        free1 = _balance1();
        total0 = free0;
        total1 = free1;
        if (pos.status) {
            // get amount in Uniswap
            (uint256 now0, uint256 now1) = pos._getTotalAmounts(performanceFee);
            if(now0 > 0 || now1 > 0){ //
                // profit distribution
                uint256 priceX96 = _priceX96(pos.poolAddress);
                (now0, now1) = _getTargetToken(pos.principal0, pos.principal1, now0, now1, priceX96, forDeposit);
                // get Total
                total0 = total0.add(now0);
                total1 = total1.add(now1);
            }
        }
    }

    /// @inheritdoc IUniverseVault
    /// @dev For Frontend
    function getTotalAmounts() external view override returns (
        uint256 total0,
        uint256 total1,
        uint256 free0,
        uint256 free1,
        uint256 utilizationRate0,
        uint256 utilizationRate1
    ) {
        (total0, total1, free0, free1) = _getTotalAmounts(false);
        if (total0 > 0) {utilizationRate0 = 1e5 - free0.mul(1e5).div(total0);}
        if (total1 > 0) {utilizationRate1 = 1e5 - free1.mul(1e5).div(total1);}
    }

    /// @inheritdoc IUniverseVault
    /// @dev For Frontend
    function getPNL() external view override returns (uint256 rate, uint256 param) {
        param = safetyParam;
        // read in memory
        PositionHelper.Position memory pos = position;
        if (pos.status) {
            // total in v3
            (uint256 total0, uint256 total1) = pos._getTotalAmounts(performanceFee);
            // _priceX96
            uint256 priceX96 = _priceX96(pos.poolAddress);
            // calculate rate
            uint256 start_nv = netValueToken1(pos.principal0, pos.principal1, priceX96);
            uint256 end_nv = netValueToken1(total0, total1, priceX96);
            rate = end_nv.mul(1e5).div(start_nv);
        }
    }

    /// @inheritdoc IUniverseVault
    /// @dev For Frontend serving deposit
    function getShares(
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external view override returns (uint256 share0, uint256 share1) {
        (share0, share1, , ) = _calcShare(amount0Desired, amount1Desired);
    }

    /// @inheritdoc IUniverseVault
    /// @dev For Frontend serving withdraw
    function getBals(
        uint256 share0,
        uint256 share1
    ) external view override returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1, , , ,) = _calcBal(share0, share1);
    }

    /// @inheritdoc IUniverseVault
    /// @dev For Frontend
    function getUserShares(address user) external view override returns (uint256 share0, uint256 share1) {
        share0 = uToken0.balanceOf(user);
        share1 = uToken1.balanceOf(user);
    }

    /// @inheritdoc IUniverseVault
    /// @dev For Frontend
    function getUserBals(address user) external view override returns (uint256 amount0, uint256 amount1) {
        uint256 share0 = uToken0.balanceOf(user);
        uint256 share1 = uToken1.balanceOf(user);
        (amount0, amount1, , , ,) = _calcBal(share0, share1);
    }

    /// @inheritdoc IUniverseVault
    /// @dev For Frontend
    function totalShare0() external view override returns (uint256) {
        return uToken0.totalSupply();
    }

    /// @inheritdoc IUniverseVault
    /// @dev For Frontend
    function totalShare1() external view override returns (uint256) {
        return uToken1.totalSupply();
    }

    /* ========== INTERNAL ========== */

    /// @dev if position out of range, don't add liquidity; Add liquidity, always update principal
    /// @dev Make Sure pos.status is alwasy True | Always update the principals
    function _addAll(
        PositionHelper.Position memory pos,
        bool ifCheck
    ) internal {
        // Read Fee Token Amount
        uint256 add0 = _balance0();
        uint256 add1 = _balance1();
        bool ifAdd;
        if(add0 > 0 && add1 > 0){
            // Read Current Tick
            int24 currentTick = _currentTick(pos.poolAddress);
            // Check For User deposit
            if (ifCheck) {
                // Read Param
                SafeAddLiq memory safeP = safeAddLiq;
                // price change
                if (currentTick - safeP.positionTick < safeP.tickBias0 && safeP.positionTick - currentTick < safeP.tickBias0) { // Check tick bias
                    ifAdd = true;
                } else if (add0.mul(safeP.pct0) < pos.principal0 || add1.mul(safeP.pct0) < pos.principal1) { // Check Invest Amount
                    ifAdd = true;
                } else if (currentTick - safeP.positionTick < safeP.tickBias1 && safeP.positionTick - currentTick < safeP.tickBias1) {
                    // Check Other Situation
                    add0 = Math.min(add0, uint256(pos.principal0).div(safeP.pct1));
                    add1 = Math.min(add1, uint256(pos.principal1).div(safeP.pct1));
                    ifAdd = true;
                }
            } else {
                ifAdd = true;
                safeAddLiq.positionTick = currentTick;
            }
        }
        if (ifAdd) {
            // add liquidity
            (add0, add1) = pos._addAll(add0, add1);
            // increase principal
            pos.principal0 = _add128(pos.principal0, _toUint128(add0));
            pos.principal1 = _add128(pos.principal1, _toUint128(add1));
            // update Status
            pos.status = true;
        }
        // upadate position
        position = pos;
    }

    /// @dev BurnAll Liquidity | CollectAll | Profit Distribution
    function _stopAll() internal {
        // burn all liquidity
        (uint256 collect0, uint256 collect1, uint256 fee0, uint256 fee1) = position._burnAll();
        // collect fee
        (uint256 feesToProtocol0, uint256 feesToProtocol1) = _collectPerformanceFee(fee0, fee1);
        // fund distribution
        _trim(collect0.sub(feesToProtocol0), collect1.sub(feesToProtocol1), 0, true);
    }

    /// @dev BurnPart Liquidity | CollectAll | Profit Distribution | Return Cost
    function _stopPart(uint128 liq, bool withdrawZero) internal returns(int256 amtSelfDiff) {
        // burn liquidity
        (uint256 collect0, uint256 collect1, uint256 fee0, uint256 fee1) = position._burn(liq);
        // collect fee
        (uint256 feesToProtocol0, uint256 feesToProtocol1) = _collectPerformanceFee(fee0, fee1);
        // fund distribution
        (amtSelfDiff) = _trim(collect0.sub(feesToProtocol0), collect1.sub(feesToProtocol1), liq, withdrawZero);
    }

    /// @dev Fund Distribution Based on Param
    function _trim(
        uint256 stop0,
        uint256 stop1,
        uint128 liq,
        bool withdrawZero
    ) internal returns(int256 amtSelfDiff) {
        if(stop0 == 0 && stop1 == 0) return (0); //
        // read position in memory
        PositionHelper.Position memory pos = position;
        // calculate
        uint256 priceX96 = _priceX96(pos.poolAddress);
        uint256 start0 = pos.principal0;
        uint256 start1 = pos.principal1;
        if (liq != 0) { // Liquidate Part, Update Principal
            (uint128 total_liq, , , , ) = pos._positionInfo();
            start0 = FullMath.mulDiv(start0, liq, total_liq + liq);
            start1 = FullMath.mulDiv(start1, liq, total_liq + liq);
            pos.principal0 = pos.principal0 - _toUint128(start0);
            pos.principal1 = pos.principal1 - _toUint128(start1);
            position = pos;
        }
        (uint256 target0 , uint256 target1) = _getTargetToken(start0, start1, stop0, stop1, priceX96, false); // Use if always for withdraw
        int256 amt;
        bool zeroForOne;
        if(withdrawZero) {
            amt = int256(stop1) - int256(target1);
            if (amt < 0) zeroForOne = true;
            amtSelfDiff = int256(stop0) - int256(target0) ;
        }else{
            amt = int256(stop0) - int256(target0);
            if (amt > 0) zeroForOne = true;
            amtSelfDiff = int256(stop1) - int(target1) ;
        }
        if(amt != 0){
            uint160 sqrtPriceLimitX96 = (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1);
            (int256 amount0, int256 amount1) = IUniswapV3Pool(swapPool).swap(address(this), zeroForOne, amt, sqrtPriceLimitX96, '');
            amtSelfDiff = amtSelfDiff - (withdrawZero ? amount0 : amount1);
        }
    }

    /// @dev Profit Distribution Based on Param | Return target Amount after distribution
    function _getTargetToken(
        uint256 start0,
        uint256 start1,
        uint256 end0,
        uint256 end1,
        uint256 priceX96,
        bool forDeposit
    ) internal view returns (uint256 target0, uint256 target1){
        uint256 start_nv = netValueToken1(start0, start1, priceX96);
        uint256 end_nv = netValueToken1(end0, end1, priceX96);
        uint256 rate = end_nv.mul(1e5).div(start_nv);
        // For safe when deposit
        if (forDeposit && rate < safetyParam) {
            rate = safetyParam;
        }
        // profit distribution
        if (rate > 1e5 && profitScale != 100) {
            rate = rate.sub(1e5).mul(profitScale).div(1e2).add(1e5);
            target0 = FullMath.mulDiv(start0, rate, 1e5);
            target1 = end_nv.sub(FullMath.mulDiv(target0, priceX96, FixedPoint96.Q96));
        } else {
            target0 = FullMath.mulDiv(start0, rate, 1e5);
            target1 = FullMath.mulDiv(start1, rate, 1e5);
        }
    }

    function _collectPerformanceFee(
        uint256 feesFromPool0,
        uint256 feesFromPool1
    ) internal returns (uint256 feesToProtocol0, uint256 feesToProtocol1){
        uint256 rate = performanceFee;
        if (rate != 0) {
            ProtocolFees memory pf = protocolFees;
            if (feesFromPool0 > 0) {
                feesToProtocol0 = feesFromPool0.div(rate);
                pf.fee0 = _add128(pf.fee0, _toUint128(feesToProtocol0));
            }
            if (feesFromPool1 > 0) {
                feesToProtocol1 = feesFromPool1.div(rate);
                pf.fee1 = _add128(pf.fee1, _toUint128(feesToProtocol1));
            }
            protocolFees = pf;
            emit CollectFees(feesFromPool0, feesFromPool1);
        }
    }

    function _priceX96(address poolAddress) internal view returns(uint256 priceX96){
        (uint160 sqrtRatioX96, , , , , , ) = IUniswapV3Pool(poolAddress).slot0();
        priceX96 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, FixedPoint96.Q96);
    }

    function _currentTick(address poolAddress) internal view returns(int24 currentTick){
        ( , currentTick, , , , , ) = IUniswapV3Pool(poolAddress).slot0();
    }

    /// @dev Money From Msg.sender, Share to 'to'
    function _deposit(
        uint256 amount0Desired,
        uint256 amount1Desired,
        address to
    ) internal returns(uint256 share0, uint256 share1) {
        // Check Params
        require(amount0Desired > 0 || amount1Desired > 0, "Deposit Zero!");
        PositionHelper.Position memory pos = position;
        if(pos.status){
            int24 currentTick = _currentTick(pos.poolAddress);
            SafeAddLiq memory _safeAddLiq = safeAddLiq;
            require(currentTick - _safeAddLiq.positionTick < _safeAddLiq.depositMaxOffsetTick &&
            _safeAddLiq.positionTick - currentTick < _safeAddLiq.depositMaxOffsetTick, "Not Time!");
        }
        // Read Control Param
        MaxShares memory _maxShares = maxShares;
        require(amount0Desired <= _maxShares.maxSingeDepositAmt0 && amount1Desired <= _maxShares.maxSingeDepositAmt1, "Too Much Deposit!");
        uint256 total0;
        uint256 total1;
        // Cal Share
        (share0, share1, total0, total1) = _calcShare(amount0Desired, amount1Desired);
        // check max share
        require(total0.add(amount0Desired) <= _maxShares.maxToken0Amt
                && total1.add(amount1Desired) <= _maxShares.maxToken1Amt, "exceed total limit");
        // transfer
        if (amount0Desired > 0) token0.safeTransferFrom(msg.sender, address(this), amount0Desired);
        if (amount1Desired > 0) token1.safeTransferFrom(msg.sender, address(this), amount1Desired);
        // add share
        if (share0 > 0) {
            uToken0.mint(to, share0);
        }
        if (share1 > 0) {
            uToken1.mint(to, share1);
        }
        // Invest All
        if (pos.status) {
            _addAll(pos, true);
        }
        // EVENT
        emit Deposit(to, share0, share1, amount0Desired, amount1Desired);
    }

    /* ========== EXTERNAL ========== */

    /// @inheritdoc IUniverseVault
    /// @dev For EOA and Contract User
    function deposit(
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external override returns(uint256, uint256) {
        require(tx.origin == msg.sender || contractWhiteLists[msg.sender], "only for verified contract!");
        return _deposit(amount0Desired, amount1Desired, msg.sender);
    }

    /// @inheritdoc IUniverseVault
    /// @dev For Router
    function deposit(
        uint256 amount0Desired,
        uint256 amount1Desired,
        address to
    ) external override returns(uint256, uint256) {
        require(contractWhiteLists[msg.sender], "only for verified contract!");
        return _deposit(amount0Desired, amount1Desired, to);
    }

    /// @inheritdoc IUniverseVault
    function withdraw(uint256 share0, uint256 share1) external override returns(uint256, uint256){
        require(share0 !=0 || share1 !=0, "Withdraw Zero Share!");
        if (share0 > 0) {
            share0 = Math.min(share0, uToken0.balanceOf(msg.sender));
        }
        if (share1 > 0) {
            share1 = Math.min(share1, uToken1.balanceOf(msg.sender));
        }
        (uint256 withdraw0, uint256 withdraw1, , , uint256 rate, bool withdrawZero) = _calcBal(share0, share1);
        // Burn
        if (share0 > 0) {uToken0.burn(msg.sender, share0);}
        if (share1 > 0) {uToken1.burn(msg.sender, share1);}
        // swap
        if (rate > 0 && position.status) {
            (uint128 liq, , , , ) = position._positionInfo();
            if (rate < 1e5) {liq = (liq * _toUint128(rate) / 1e5);}
            // all fees related to transaction
            (int256 amtSelfDiff) = _stopPart(liq, withdrawZero);
            if(amtSelfDiff < 0){
                if(withdrawZero){
                    withdraw0 = withdraw0.sub(uint(-amtSelfDiff));
                }else{
                    withdraw1 = withdraw1.sub(uint(-amtSelfDiff));
                }
            }
        }
        if (withdraw0 > 0) {
            withdraw0 = Math.min(withdraw0, _balance0());
            token0.safeTransfer(msg.sender, withdraw0);
        }
        if (withdraw1 > 0) {
            withdraw1 = Math.min(withdraw1, _balance1());
            token1.safeTransfer(msg.sender, withdraw1);
        }

        emit Withdraw(msg.sender, share0, share1, withdraw0, withdraw1);

        return (withdraw0, withdraw1);
    }

    /* ========== ONLY MANAGER ========== */

    /// @inheritdoc IVaultOperatorActions
    function initPosition(
        address _poolAddress,
        int24 _lowerTick,
        int24 _upperTick
    ) external override onlyManager {
        require(poolMap[_poolAddress], 'add Pool First');
        require(!position.status, 'position is working, cannot init!');
        IUniswapV3Pool pool = IUniswapV3Pool(_poolAddress);
        int24 tickSpacing = pool.tickSpacing();
        (_lowerTick, _upperTick) = tickRegulate(_lowerTick, _upperTick, tickSpacing);
        PositionHelper.Position memory pos = PositionHelper.Position({
            principal0 : 0,
            principal1 : 0,
            poolAddress : _poolAddress,
            tickSpacing : tickSpacing,
            lowerTick : _lowerTick,
            upperTick : _upperTick,
            status: true
        });
        // add liquidity
        _addAll(pos, false);
    }

    /// @inheritdoc IVaultOperatorActions
    function addPool(uint24 _poolFee) external override onlyManager {
        // require(_poolFee == 3000 || _poolFee == 500 || _poolFee == 10000, "Wrong poolFee!");
        address poolAddress = _computeAddress(_poolFee);
        poolMap[poolAddress] = true;
    }

    /// @inheritdoc IVaultOperatorActions
    function changeConfig(
        address _swapPool,
        uint8 _performanceFee,
        uint24 _diffTick,
        uint32 _safetyParam
    ) external override onlyManager {
        require(_performanceFee == 0 || _performanceFee > 4, "20Percent MAX!");
        require(_safetyParam <= 1e5, 'Wrong safety param!');
        if (_swapPool != address(0) && poolMap[_swapPool]) {swapPool = _swapPool;}
        performanceFee = _performanceFee;
        diffTick = _diffTick;
        safetyParam = _safetyParam;
    }

    /// @inheritdoc IVaultOperatorActions
    function changeMaxShare(
        uint256 _maxShare0,
        uint256 _maxShare1,
        uint256 _maxSingeDepositAmt0,
        uint256 _maxSingeDepositAmt1
    ) external override onlyManager {
        MaxShares memory _maxShares = maxShares;
        _maxShares.maxToken0Amt = _maxShare0;
        _maxShares.maxToken1Amt = _maxShare1;
        _maxShares.maxSingeDepositAmt0 = _maxSingeDepositAmt0;
        _maxShares.maxSingeDepositAmt1 = _maxSingeDepositAmt1;
        maxShares = _maxShares;
    }

    /// @inheritdoc IVaultOperatorActions
    function changeSafeAddLiq(
        int24 _depositMaxOffsetTick,
        int24 _tickBias0,
        int24 _tickBias1,
        uint24 _pct0,
        uint24 _pct1
    ) external override onlyManager {
        SafeAddLiq memory _safeDeposit = safeAddLiq;
        _safeDeposit.depositMaxOffsetTick = _depositMaxOffsetTick;
        _safeDeposit.tickBias0 = _tickBias0;
        _safeDeposit.tickBias1 = _tickBias1;
        _safeDeposit.pct0 = _pct0;
        _safeDeposit.pct1 = _pct1;
        safeAddLiq = _safeDeposit;
    }

    /// @inheritdoc IVaultOperatorActions
    function avoidRisk(uint8 _profitScale) external override onlyManager {
        if (position.status) {
            _stopAll();
            position.status = false;
        }
        _changeProfitScale(_profitScale);
    }

    /// @inheritdoc IVaultOperatorActions
    function changePool(
        address newPoolAddress,
        int24 _lowerTick,
        int24 _upperTick,
        int24 _spotTick, // the tick when decide to send the transaction
        uint8 _profitScale
    ) external override onlyManager {
        // Check
        require(poolMap[newPoolAddress], 'Add Pool First!');
        // read in memory
        PositionHelper.Position memory pos = position;
        // check attack
        pos.checkDiffTick(_spotTick, diffTick);
        require(pos.status && pos.poolAddress != newPoolAddress, "CAN NOT CHANGE POOL!");
        // stop current pool & change profit config
        _stopAll();
        pos.status = false;
        _changeProfitScale(_profitScale);
        // new pool info
        int24 tickSpacing = IUniswapV3Pool(newPoolAddress).tickSpacing();
        (_lowerTick, _upperTick) = tickRegulate(_lowerTick, _upperTick, tickSpacing);
        pos.principal0 = 0;
        pos.principal1 = 0;
        pos.poolAddress = newPoolAddress;
        pos.tickSpacing = tickSpacing;
        pos.upperTick = _upperTick;
        pos.lowerTick = _lowerTick;
        // add liquidity
        _addAll(pos, false);
    }

    /// @inheritdoc IVaultOperatorActions
    function forceReBalance(
        int24 _lowerTick,
        int24 _upperTick,
        int24 _spotTick,
        uint8 _profitScale
    ) public override onlyManager{
        // read in memory
        PositionHelper.Position memory pos = position;
        // Check Status
        (_lowerTick, _upperTick) = tickRegulate(_lowerTick, _upperTick, pos.tickSpacing);
        pos.checkDiffTick(_spotTick, diffTick);
        // stopAll & change profit config
        if (pos.status) {
            _stopAll();
            pos.status = false;
        }
        _changeProfitScale(_profitScale);
        // new pool info
        pos.principal0 = 0;
        pos.principal1 = 0;
        pos.upperTick = _upperTick;
        pos.lowerTick = _lowerTick;
        // add liquidity
        _addAll(pos, false);
    }

    /// @inheritdoc IVaultOperatorActions
    function reBalance(
        int24 reBalanceThreshold,
        int24 band,
        int24 _spotTick,
        uint8 _profitScale
    ) external override onlyManager {
        require(band > 0 && reBalanceThreshold > 0, "Bad params!");
        (bool status, int24 lowerTick, int24 upperTick) = position._getReBalanceTicks(reBalanceThreshold, band);
        if (status) {
            forceReBalance(lowerTick, upperTick, _spotTick, _profitScale);
        }
    }

    /* ========== CALL BACK ========== */

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0, 'Zero');
        require(swapPool == msg.sender, "wrong address");
        if (amount0Delta > 0) {
            token0.transfer(msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            token1.transfer(msg.sender, uint256(amount1Delta));
        }
    }

    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata
    ) external override {
        require(poolMap[msg.sender], "wrong address");
        // transfer
        if (amount0 > 0) {token0.safeTransfer(msg.sender, amount0);}
        if (amount1 > 0) {token1.safeTransfer(msg.sender, amount1);}
    }

}
