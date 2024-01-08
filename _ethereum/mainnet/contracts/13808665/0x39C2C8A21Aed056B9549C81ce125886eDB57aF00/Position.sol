// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.5;
pragma abicoder v2;

import "./PathPrice.sol";
import "./FixedPoint128.sol";
import "./PositionKey.sol";
import "./LowGasSafeMath.sol";
import "./LiquidityAmounts.sol";
import "./ISwapRouter.sol";
import "./SqrtPriceMath.sol";

library Position {
    using LowGasSafeMath for uint;
    using SafeCast for int256;
    // using Path for bytes;

    uint constant DIVISOR = 100 << 128;

    // info stored for each user's position
    struct Info {
        bool isEmpty;
        int24 tickLower;
        int24 tickUpper;
    }

    /// @notice 计算将t0最大化添加到pool的LP时，需要的t0, t1数量
    /// @dev 计算公式：△x0 = △x /( SPu*(SPc - SPl) / (SPc*(SPu - SPc)) + 1)
    function getAmountsForAmount0(
        uint160 sqrtPriceX96, 
        uint160 sqrtPriceL96,
        uint160 sqrtPriceU96,
        uint deltaX
    ) internal pure returns(uint amount0, uint amount1){
        // 全部是t0
        if(sqrtPriceX96 <= sqrtPriceL96){
            amount0 = deltaX;
        }
        // 部分t0
        else if( sqrtPriceX96 < sqrtPriceU96){
            // a = SPu*(SPc - SPl)
            uint a = FullMath.mulDiv(sqrtPriceU96, sqrtPriceX96 - sqrtPriceL96, FixedPoint64.Q64);
            // b = SPc*(SPu - SPc)
            uint b = FullMath.mulDiv(sqrtPriceX96, sqrtPriceU96 - sqrtPriceX96, FixedPoint64.Q64);
            // △x0 = △x/(a/b +1) = △x*b/(a+b)
            amount0 = FullMath.mulDiv(deltaX, b, a + b);
        }
        // 剩余的转成t1
        if(deltaX > amount0){
            amount1 = FullMath.mulDiv(
                deltaX.sub(amount0), 
                FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint64.Q64), 
                FixedPoint128.Q128
            );
        }
    }

    /// @notice 计算最小兑换输出值
    /// @param curSqrtPirceX96 当前价
    /// @param maxPriceImpact 最大价格影响
    /// @param amountIn 输入数里
    function getAmountOutMin(
        uint curSqrtPirceX96, 
        uint maxPriceImpact, 
        uint amountIn
    ) internal pure returns(uint amountOutMin){
        amountOutMin = FullMath.mulDiv(
            FullMath.mulDiv(amountIn, FullMath.mulDiv(curSqrtPirceX96, curSqrtPirceX96, FixedPoint64.Q64), FixedPoint128.Q128), 
            1e4 - maxPriceImpact, // maxPriceImpact最大1e4，不会溢出
            1e4);
    }

    struct SwapParams{
        uint amount;
        uint amount0;
        uint amount1;
        uint160 sqrtPriceX96;
        uint160 sqrtRatioAX96;
        uint160 sqrtRatioBX96;
        address token;
        address token0;
        address token1;
        uint24 fee;
        address uniV3Factory;
        address uniV3Router;
        uint32 maxSqrtSlippage;
        uint32 maxPriceImpact;
    }

    /// @notice 根据基金本币数量以及收集的手续费数量, 计算投资指定头寸两种代币的分布.
    function computeSwapAmounts(
        SwapParams memory params,
        mapping(address => bytes) storage buyPath
    ) internal returns(uint amount0Max, uint amount1Max) {
        uint equalAmount0;
        bytes memory buy0Path;
        bytes memory buy1Path;
        uint buy0SqrtPriceX96;
        uint buy1SqrtPriceX96;
        uint amountIn;

        //将基金本币换算成token0
        if(params.amount > 0){
            if(params.token == params.token0){
                buy1Path = buyPath[params.token1];
                buy1SqrtPriceX96 = PathPrice.verifySlippage(buy1Path, params.uniV3Factory, params.maxSqrtSlippage);
                equalAmount0 = params.amount0.add(params.amount);
            } else {
                buy0Path = buyPath[params.token0];
                buy0SqrtPriceX96 = PathPrice.verifySlippage(buy0Path, params.uniV3Factory, params.maxSqrtSlippage);
                if(params.token != params.token1) {
                    buy1Path = buyPath[params.token1];
                    buy1SqrtPriceX96 = PathPrice.verifySlippage(buy1Path, params.uniV3Factory, params.maxSqrtSlippage);
                }
                equalAmount0 = params.amount0.add((FullMath.mulDiv(
                    params.amount,
                    FullMath.mulDiv(buy0SqrtPriceX96, buy0SqrtPriceX96, FixedPoint64.Q64),
                    FixedPoint128.Q128
                )));
            }
        } 
        else  equalAmount0 = params.amount0;

        //将token1换算成token0
        if(params.amount1 > 0){
            equalAmount0 = equalAmount0.add((FullMath.mulDiv(
                params.amount1,
                FixedPoint128.Q128,
                FullMath.mulDiv(params.sqrtPriceX96, params.sqrtPriceX96, FixedPoint64.Q64)
            )));
        }
        require(equalAmount0 > 0, "EIZ");

        // 计算需要的t0、t1数量
        (amount0Max, amount1Max) = getAmountsForAmount0(params.sqrtPriceX96, params.sqrtRatioAX96, params.sqrtRatioBX96, equalAmount0);

        // t0不够，需要补充
        if(amount0Max > params.amount0) {
            //t1也不够，基金本币需要兑换成t0和t1
            if(amount1Max > params.amount1){
                // 基金本币兑换成token0
                if(params.token0 == params.token){
                    amountIn = amount0Max - params.amount0;
                    if(amountIn > params.amount) amountIn = params.amount;
                    amount0Max = params.amount0.add(amountIn);
                } else {
                    amountIn = FullMath.mulDiv(
                        amount0Max - params.amount0,
                        FixedPoint128.Q128,
                        FullMath.mulDiv(buy0SqrtPriceX96, buy0SqrtPriceX96, FixedPoint64.Q64)
                    );
                    if(amountIn > params.amount) amountIn = params.amount;
                    if(amountIn > 0) {
                        uint amountOutMin = getAmountOutMin(buy0SqrtPriceX96, params.maxPriceImpact, amountIn);
                        amount0Max = params.amount0.add(ISwapRouter(params.uniV3Router).exactInput(ISwapRouter.ExactInputParams({
                            path: buy0Path,
                            recipient: address(this),
                            deadline: block.timestamp,
                            amountIn: amountIn,
                            amountOutMinimum: amountOutMin
                        })));
                    } else amount0Max = params.amount0;
                }
                // 基金本币兑换成token1
                if(params.token1 == params.token){
                    amount1Max = params.amount1.add(params.amount.sub(amountIn));
                } else {
                    if(amountIn < params.amount){
                        amountIn = params.amount.sub(amountIn);
                        uint amountOutMin = getAmountOutMin(buy1SqrtPriceX96, params.maxPriceImpact, amountIn);
                        amount1Max = params.amount1.add(ISwapRouter(params.uniV3Router).exactInput(ISwapRouter.ExactInputParams({
                            path: buy1Path,
                            recipient: address(this),
                            deadline: block.timestamp,
                            amountIn: amountIn,
                            amountOutMinimum: amountOutMin
                        })));
                    } 
                    else amount1Max = params.amount1;
                }
            }
            // t1多了，多余的t1需要兑换成t0，基金本币全部兑换成t0
            else {
                // 基金本币全部兑换成t0
                if (params.amount > 0){
                    if(params.token0 == params.token){
                        amount0Max = params.amount0.add(params.amount);
                    } else{
                        uint amountOutMin = getAmountOutMin(buy0SqrtPriceX96, params.maxPriceImpact, params.amount);
                        amount0Max = params.amount0.add(ISwapRouter(params.uniV3Router).exactInput(ISwapRouter.ExactInputParams({
                            path: buy0Path,
                            recipient: address(this),
                            deadline: block.timestamp,
                            amountIn: params.amount,
                            amountOutMinimum: amountOutMin
                        })));
                    }
                } else amount0Max = params.amount0;

                // 多余的t1兑换成t0
                if(params.amount1 > amount1Max) {
                    amountIn = params.amount1.sub(amount1Max);
                    buy0Path = abi.encodePacked(params.token1, params.fee, params.token0);
                    buy0SqrtPriceX96 = FixedPoint96.Q96 * FixedPoint96.Q96 / params.sqrtPriceX96;// 不会出现溢出
                    uint lastSqrtPriceX96 = PathPrice.getSqrtPriceX96Last(buy0Path, params.uniV3Factory);
                    if(lastSqrtPriceX96 > buy0SqrtPriceX96) 
                        require(buy0SqrtPriceX96 > params.maxSqrtSlippage * lastSqrtPriceX96 / 1e4, "VS");// 不会出现溢出
                    uint amountOutMin = getAmountOutMin(buy0SqrtPriceX96, params.maxPriceImpact, amountIn);
                    amount0Max = amount0Max.add(ISwapRouter(params.uniV3Router).exactInput(ISwapRouter.ExactInputParams({
                        path: buy0Path,
                        recipient: address(this),
                        deadline: block.timestamp,
                        amountIn: amountIn,
                        amountOutMinimum: amountOutMin
                    })));
                }
            }
        }
        // t0多了，多余的t0兑换成t1, 基金本币全部兑换成t1
        else {
            // 基金本币全部兑换成t1
            if(params.amount > 0){
                if(params.token1 == params.token){
                    amount1Max = params.amount1.add(params.amount);
                } else {
                    uint amountOutMin = getAmountOutMin(buy1SqrtPriceX96, params.maxPriceImpact, params.amount);
                    amount1Max = params.amount1.add(ISwapRouter(params.uniV3Router).exactInput(ISwapRouter.ExactInputParams({
                        path: buy1Path,
                        recipient: address(this),
                        deadline: block.timestamp,
                        amountIn: params.amount,
                        amountOutMinimum: amountOutMin
                    })));
                }
            } else amount1Max = params.amount1;

            // 多余的t0兑换成t1
            if(params.amount0 > amount0Max){
                amountIn = params.amount0.sub(amount0Max);
                buy1Path = abi.encodePacked(params.token0, params.fee, params.token1);
                buy1SqrtPriceX96 = params.sqrtPriceX96;
                uint lastSqrtPriceX96 = PathPrice.getSqrtPriceX96Last(buy1Path, params.uniV3Factory);
                if(lastSqrtPriceX96 > buy1SqrtPriceX96) 
                    require(buy1SqrtPriceX96 > params.maxSqrtSlippage * lastSqrtPriceX96 / 1e4, "VS");// 不会出现溢出
                uint amountOutMin = getAmountOutMin(buy1SqrtPriceX96, params.maxPriceImpact, amountIn);
                amount1Max = amount1Max.add(ISwapRouter(params.uniV3Router).exactInput(ISwapRouter.ExactInputParams({
                    path: buy1Path,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMin
                })));
            }
        }
    }

    struct AddParams {
        // pool信息
        uint poolIndex;
        address pool;
        // 要投入的基金本币和数量
        address token;
        uint amount;
        // 要投入的token0、token1数量
        uint amount0Max;
        uint amount1Max;
        //UNISWAP_V3_ROUTER
        address uniV3Router;
        address uniV3Factory;
        uint32 maxSqrtSlippage;
        uint32 maxPriceImpact;
    }

    /// @notice 添加LP到指定Position
    /// @param self Position.Info
    /// @param params 投资信息
    /// @param sellPath sell token路径
    /// @param buyPath buy token路径
    function addLiquidity(
        Info storage self,
        AddParams memory params,
        mapping(address => bytes) storage sellPath,
        mapping(address => bytes) storage buyPath
    ) public returns(uint128 liquidity) {
        (int24 tickLower, int24 tickUpper) = (self.tickLower, self.tickUpper);

        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(params.pool).slot0();

        SwapParams memory swapParams = SwapParams({
            amount: params.amount,
            amount0: params.amount0Max,
            amount1: params.amount1Max,
            sqrtPriceX96: sqrtPriceX96,
            sqrtRatioAX96: TickMath.getSqrtRatioAtTick(tickLower),
            sqrtRatioBX96: TickMath.getSqrtRatioAtTick(tickUpper),
            token: params.token,
            token0: IUniswapV3Pool(params.pool).token0(),
            token1: IUniswapV3Pool(params.pool).token1(),
            fee: IUniswapV3Pool(params.pool).fee(),
            uniV3Router: params.uniV3Router,
            uniV3Factory: params.uniV3Factory,
            maxSqrtSlippage: params.maxSqrtSlippage,
            maxPriceImpact: params.maxPriceImpact
        });
        (params.amount0Max,  params.amount1Max) = computeSwapAmounts(swapParams, buyPath);

        //因为滑点，重新加载sqrtPriceX96
        (sqrtPriceX96,,,,,,) = IUniswapV3Pool(params.pool).slot0();

        //推算实际的liquidity
        liquidity = LiquidityAmounts.getLiquidityForAmounts(sqrtPriceX96, swapParams.sqrtRatioAX96, swapParams.sqrtRatioBX96, params.amount0Max, params.amount1Max);

        require(liquidity > 0, "LIZ");
        (uint amount0, uint amount1) = IUniswapV3Pool(params.pool).mint(
            address(this),// LP recipient
            tickLower,
            tickUpper,
            liquidity,
            abi.encode(params.poolIndex)
        );

        //处理没有添加进LP的token余额，兑换回基金本币
        if(amount0 < params.amount0Max){
            if(swapParams.token0 != params.token){
                ISwapRouter(params.uniV3Router).exactInput(ISwapRouter.ExactInputParams({
                    path: sellPath[swapParams.token0],
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: params.amount0Max - amount0,
                    amountOutMinimum: 0
                }));
            }
        }
        if(amount1 < params.amount1Max){
            if(swapParams.token1 != params.token){
                ISwapRouter(params.uniV3Router).exactInput(ISwapRouter.ExactInputParams({
                    path: sellPath[swapParams.token1],
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: params.amount1Max - amount1,
                    amountOutMinimum: 0
                }));
            }
        }

        if(self.isEmpty) self.isEmpty = false;
    }

    /// @notice brun指定头寸的LP，并取回2种代币
    /// @param pool UniswapV3Pool
    /// @param proportionX128 burn所占份额
    /// @return amount0 获得的token0数量
    /// @return amount1 获得的token1数量
    function burnAndCollect(
        Info storage self,
        address pool,
        uint proportionX128
    ) public returns(uint amount0, uint amount1) {
        require(proportionX128 <= DIVISOR, "PTL");

        // 如果是空头寸，直接返回0,0
        if(self.isEmpty == true) return(amount0, amount1);

        int24 tickLower = self.tickLower;
        int24 tickUpper = self.tickUpper;

        IUniswapV3Pool _pool = IUniswapV3Pool(pool);
        if(proportionX128 > 0) {
            (uint sumLP, , , , ) = _pool.positions(PositionKey.compute(address(this), tickLower, tickUpper));
            uint subLP = FullMath.mulDiv(proportionX128, sumLP, DIVISOR);

            _pool.burn(tickLower, tickUpper, uint128(subLP));
            (amount0, amount1) = _pool.collect(address(this), tickLower,  tickUpper, type(uint128).max, type(uint128).max);

            if(sumLP == subLP) self.isEmpty = true;
        }
        //为0表示只提取手续费
        else {
            _pool.burn(tickLower, tickUpper, 0);
            (amount0, amount1) = _pool.collect(address(this), tickLower,  tickUpper, type(uint128).max, type(uint128).max);
        }
    }

    struct SubParams {
        //pool信息
        address pool;
        //基金本币和移除占比
        address token;
        uint proportionX128;
        //UNISWAP_V3_ROUTER
        address uniV3Router;
        address uniV3Factory;
        uint32 maxSqrtSlippage;
        uint32 maxPriceImpact;
    }

    /// @notice 减少指定头寸LP，并取回本金本币
    /// @param self 指定头寸
    /// @param params 流动池和要减去的数量
    /// @return amount 获取的基金本币数量
    function subLiquidity (
        Info storage self,
        SubParams memory params,
        mapping(address => bytes) storage sellPath
    ) public returns(uint amount) {
        address token0 = IUniswapV3Pool(params.pool).token0();
        address token1 = IUniswapV3Pool(params.pool).token1();
        uint sqrtPriceX96;
        uint sqrtPriceX96Last;
        uint amountOutMin;

        // 验证本池子的滑点
        if(params.maxSqrtSlippage <= 1e4){
            // t0到t1的滑点
            (sqrtPriceX96,,,,,,) = IUniswapV3Pool(params.pool).slot0();
            uint32[] memory secondAges = new uint32[](2);
            secondAges[0] = 0;
            secondAges[1] = 1;
            (int56[] memory tickCumulatives,) = IUniswapV3Pool(params.pool).observe(secondAges);
            sqrtPriceX96Last = TickMath.getSqrtRatioAtTick(int24(tickCumulatives[0] - tickCumulatives[1]));
            if(sqrtPriceX96Last > sqrtPriceX96)
                require(sqrtPriceX96 > params.maxSqrtSlippage * sqrtPriceX96Last / 1e4, "VS");// 不会出现溢出
            
            // t1到t0的滑点
            sqrtPriceX96 = FixedPoint96.Q96 * FixedPoint96.Q96 / sqrtPriceX96; // 不会出现溢出
            sqrtPriceX96Last = FixedPoint96.Q96 * FixedPoint96.Q96 / sqrtPriceX96Last; 
            if(sqrtPriceX96Last > sqrtPriceX96)
                require(sqrtPriceX96 > params.maxSqrtSlippage * sqrtPriceX96Last / 1e4, "VS"); // 不会出现溢出
        }

        // burn & collect
        (uint amount0, uint amount1) = burnAndCollect(self, params.pool, params.proportionX128);

        // t0兑换成基金本币
        if(token0 != params.token){
            if(amount0 > 0){
                bytes memory path = sellPath[token0];
                if(params.maxSqrtSlippage <= 1e4) {
                    sqrtPriceX96 = PathPrice.verifySlippage(path, params.uniV3Factory, params.maxSqrtSlippage);
                    amountOutMin = getAmountOutMin(sqrtPriceX96, params.maxPriceImpact, amount0);    
                }
                amount = ISwapRouter(params.uniV3Router).exactInput(ISwapRouter.ExactInputParams({
                    path: path,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amount0,
                    amountOutMinimum: amountOutMin
                }));
            }
        }

        // t1兑换成基金本币
        if(token1 != params.token){
            if(amount1 > 0){
                bytes memory path = sellPath[token1];
                if(params.maxSqrtSlippage <= 1e4) {
                    sqrtPriceX96 = PathPrice.verifySlippage(path, params.uniV3Factory, params.maxSqrtSlippage);
                    amountOutMin = getAmountOutMin(sqrtPriceX96, params.maxPriceImpact, amount1);    
                }
                amount = amount.add(ISwapRouter(params.uniV3Router).exactInput(ISwapRouter.ExactInputParams({
                    path: path,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amount1,
                    amountOutMinimum: amountOutMin
                })));
            }
        }
    }

    /// @notice 封装成结构体的函数局部变量，避免堆栈过深报错.
    struct AssetsParams {
        address token0;
        address token1;
        uint sqrt0;
        uint sqrt1;
        uint160 sqrtPriceX96;
        int24 tick;
        uint256 feeGrowthGlobal0X128;
        uint256 feeGrowthGlobal1X128;
    }

    /// @notice 获取某个流动池(pool)，以基金本币衡量的所有资产
    /// @param  pool 流动池地址
    /// @return amount 资产数量
    function assetsOfPool(
        Info[] storage self,
        address pool,
        address token,
        mapping(address => bytes) storage sellPath,
        address uniV3Factory
    ) public view returns (uint amount, uint[] memory) {
        uint[] memory amounts = new uint[](self.length);
        // 局部变量都是为了减少ssload消耗.
        AssetsParams memory params;
        // 获取两种token的本币价格.
        params.token0 = IUniswapV3Pool(pool).token0();
        params.token1 = IUniswapV3Pool(pool).token1();
        if(params.token0 != token){
            bytes memory path = sellPath[params.token0];
            if(path.length == 0) return(amount, amounts);
            params.sqrt0 = PathPrice.getSqrtPriceX96Last(path, uniV3Factory);
        }
        if(params.token1 != token){
            bytes memory path = sellPath[params.token1];
            if(path.length == 0) return(amount, amounts);
            params.sqrt1 = PathPrice.getSqrtPriceX96Last(path, uniV3Factory);
        }

        (params.sqrtPriceX96, params.tick, , , , , ) = IUniswapV3Pool(pool).slot0();
        params.feeGrowthGlobal0X128 = IUniswapV3Pool(pool).feeGrowthGlobal0X128();
        params.feeGrowthGlobal1X128 = IUniswapV3Pool(pool).feeGrowthGlobal1X128();

        for(uint i=0; i < self.length; i++){
            Position.Info memory position = self[i];
            if(position.isEmpty) continue;
            bytes32 positionKey = keccak256(abi.encodePacked(address(this), position.tickLower, position.tickUpper));
            // 获取token0, token1的资产数量
            (uint256 _amount0, uint256 _amount1) =
                getAssetsOfSinglePosition(
                    AssetsOfSinglePosition({
                        pool: pool,
                        positionKey: positionKey,
                        tickLower: position.tickLower,
                        tickUpper: position.tickUpper,
                        tickCurrent: params.tick,
                        sqrtPriceX96: params.sqrtPriceX96,
                        feeGrowthGlobal0X128: params.feeGrowthGlobal0X128,
                        feeGrowthGlobal1X128: params.feeGrowthGlobal1X128
                    })
                );

            // 计算成本币资产.
            uint _amount;
            if(params.token0 != token){
                _amount = FullMath.mulDiv(
                    _amount0,
                    FullMath.mulDiv(params.sqrt0, params.sqrt0, FixedPoint64.Q64),
                    FixedPoint128.Q128);
            }
            else
                _amount = _amount0;

            if(params.token1 != token){
                _amount = _amount.add(FullMath.mulDiv(
                    _amount1,
                    FullMath.mulDiv(params.sqrt1, params.sqrt1, FixedPoint64.Q64),
                    FixedPoint128.Q128));
            }
            else
                _amount = _amount.add(_amount1);

            amounts[i] = _amount;
            amount = amount.add(_amount);
        }
        return(amount, amounts);
    }

    /// @notice 获取某个头寸，以基金本币衡量的所有资产
    /// @param pool 交易池索引号
    /// @param token 头寸索引号
    /// @return amount 资产数量
    function assets(
        Info storage self,
        address pool,
        address token,
        mapping(address => bytes) storage sellPath,
        address uniV3Factory
    ) public view returns (uint amount) {
        if(self.isEmpty) return 0;

        // 不需要校验 pool 是否存在
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = IUniswapV3Pool(pool).slot0();

        bytes32 positionKey = keccak256(abi.encodePacked(address(this), self.tickLower, self.tickUpper));

        // 获取token0, token1的资产数量
        (uint256 amount0, uint256 amount1) =
            getAssetsOfSinglePosition(
                AssetsOfSinglePosition({
                    pool: pool,
                    positionKey: positionKey,
                    tickLower: self.tickLower,
                    tickUpper: self.tickUpper,
                    tickCurrent: tick,
                    sqrtPriceX96: sqrtPriceX96,
                    feeGrowthGlobal0X128: IUniswapV3Pool(pool).feeGrowthGlobal0X128(),
                    feeGrowthGlobal1X128: IUniswapV3Pool(pool).feeGrowthGlobal1X128()
                })
            );

        // 计算以本币衡量的资产.
        if(amount0 > 0){
            address token0 = IUniswapV3Pool(pool).token0();
            if(token0 != token){
                uint sqrt0 = PathPrice.getSqrtPriceX96Last(sellPath[token0], uniV3Factory);
                amount = FullMath.mulDiv(
                    amount0,
                    FullMath.mulDiv(sqrt0, sqrt0, FixedPoint64.Q64),
                    FixedPoint128.Q128);
            } else
                amount = amount0;
        }
        if(amount1 > 0){
            address token1 = IUniswapV3Pool(pool).token1();
            if(token1 != token){
                uint sqrt1 = PathPrice.getSqrtPriceX96Last(sellPath[token1], uniV3Factory);
                amount = amount.add(FullMath.mulDiv(
                    amount1,
                    FullMath.mulDiv(sqrt1, sqrt1, FixedPoint64.Q64),
                    FixedPoint128.Q128));
            } else
                amount = amount.add(amount1);
        }
    }

    /// @notice 封装成结构体的函数调用参数.
    struct AssetsOfSinglePosition {
        // 交易对地址.
        address pool;
        // 头寸ID
        bytes32 positionKey;
        // 价格刻度下届
        int24 tickLower;
        // 价格刻度上届
        int24 tickUpper;
        // 当前价格刻度
        int24 tickCurrent;
        // 当前价格
        uint160 sqrtPriceX96;
        // 全局手续费变量(token0)
        uint256 feeGrowthGlobal0X128;
        // 全局手续费变量(token1)
        uint256 feeGrowthGlobal1X128;
    }

    /// @notice 获取某个头寸的全部资产，包括未计算进tokensOwed的手续费.
    /// @param params 封装成结构体的函数调用参数.
    /// @return amount0 token0的数量
    /// @return amount1 token1的数量
    function getAssetsOfSinglePosition(AssetsOfSinglePosition memory params)
        internal
        view
        returns (uint256 amount0, uint256 amount1)
    {
        (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = IUniswapV3Pool(params.pool).positions(params.positionKey);

        // 计算未计入tokensOwed的手续费
        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
            getFeeGrowthInside(
                FeeGrowthInsideParams({
                    pool: params.pool,
                    tickLower: params.tickLower,
                    tickUpper: params.tickUpper,
                    tickCurrent: params.tickCurrent,
                    feeGrowthGlobal0X128: params.feeGrowthGlobal0X128,
                    feeGrowthGlobal1X128: params.feeGrowthGlobal1X128
                })
            );

        // calculate accumulated fees
        amount0 =
            uint256(
                FullMath.mulDiv(
                    feeGrowthInside0X128 - feeGrowthInside0LastX128,
                    liquidity,
                    FixedPoint128.Q128
                )
            );
        amount1 =
            uint256(
                FullMath.mulDiv(
                    feeGrowthInside1X128 - feeGrowthInside1LastX128,
                    liquidity,
                    FixedPoint128.Q128
                )
            );

        // 计算总的手续费.
        // overflow is acceptable, have to withdraw before you hit type(uint128).max fees
        amount0 = amount0.add(tokensOwed0);
        amount1 = amount1.add(tokensOwed1);

        // 计算流动性资产
        if (params.tickCurrent < params.tickLower) {
            // current tick is below the passed range; liquidity can only become in range by crossing from left to
            // right, when we'll need _more_ token0 (it's becoming more valuable) so user must provide it
            amount0 = amount0.add(uint256(
                -SqrtPriceMath.getAmount0Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    -int256(liquidity).toInt128()
                )
            ));
        } else if (params.tickCurrent < params.tickUpper) {
            // current tick is inside the passed range
            amount0 = amount0.add(uint256(
                -SqrtPriceMath.getAmount0Delta(
                    params.sqrtPriceX96,
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    -int256(liquidity).toInt128()
                )
            ));
            amount1 = amount1.add(uint256(
                -SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    params.sqrtPriceX96,
                    -int256(liquidity).toInt128()
                )
            ));
        } else {
            // current tick is above the passed range; liquidity can only become in range by crossing from right to
            // left, when we'll need _more_ token1 (it's becoming more valuable) so user must provide it
            amount1 = amount1.add(uint256(
                -SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    -int256(liquidity).toInt128()
                )
            ));
        }
    }

    /// @notice 封装成结构体的函数调用参数.
    struct FeeGrowthInsideParams {
        // 交易对地址
        address pool;
        // The lower tick boundary of the position
        int24 tickLower;
        // The upper tick boundary of the position
        int24 tickUpper;
        // The current tick
        int24 tickCurrent;
        // The all-time global fee growth, per unit of liquidity, in token0
        uint256 feeGrowthGlobal0X128;
        // The all-time global fee growth, per unit of liquidity, in token1
        uint256 feeGrowthGlobal1X128;
    }

    /// @notice Retrieves fee growth data
    /// @param params 封装成结构体的函数调用参数.
    /// @return feeGrowthInside0X128 The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
    /// @return feeGrowthInside1X128 The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries
    function getFeeGrowthInside(FeeGrowthInsideParams memory params)
        internal
        view
        returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128)
    {
        IUniswapV3Pool _pool = IUniswapV3Pool (params.pool);
        // calculate fee growth below
        uint256 lower_feeGrowthOutside0X128;
        uint256 lower_feeGrowthOutside1X128;
        ( , , lower_feeGrowthOutside0X128, lower_feeGrowthOutside1X128, , , ,)
            = _pool.ticks(params.tickLower);

        uint256 feeGrowthBelow0X128;
        uint256 feeGrowthBelow1X128;
        if (params.tickCurrent >= params.tickLower) {
            feeGrowthBelow0X128 = lower_feeGrowthOutside0X128;
            feeGrowthBelow1X128 = lower_feeGrowthOutside1X128;
        } else {
            feeGrowthBelow0X128 = params.feeGrowthGlobal0X128 - lower_feeGrowthOutside0X128;
            feeGrowthBelow1X128 = params.feeGrowthGlobal1X128 - lower_feeGrowthOutside1X128;
        }

        // calculate fee growth above
        uint256 upper_feeGrowthOutside0X128;
        uint256 upper_feeGrowthOutside1X128;
        ( , , upper_feeGrowthOutside0X128, upper_feeGrowthOutside1X128, , , , ) =
            _pool.ticks(params.tickUpper);

        uint256 feeGrowthAbove0X128;
        uint256 feeGrowthAbove1X128;
        if (params.tickCurrent < params.tickUpper) {
            feeGrowthAbove0X128 = upper_feeGrowthOutside0X128;
            feeGrowthAbove1X128 = upper_feeGrowthOutside1X128;
        } else {
            feeGrowthAbove0X128 = params.feeGrowthGlobal0X128 - upper_feeGrowthOutside0X128;
            feeGrowthAbove1X128 = params.feeGrowthGlobal1X128 - upper_feeGrowthOutside1X128;
        }

        feeGrowthInside0X128 = params.feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
        feeGrowthInside1X128 = params.feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
    }
}
