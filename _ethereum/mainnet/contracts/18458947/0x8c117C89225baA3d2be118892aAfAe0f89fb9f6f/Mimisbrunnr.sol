// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import "./ERC20.sol";
import  "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./INonfungiblePositionManager.sol";
import "./IUniswapV3Pool.sol";
import "./PoolAddress.sol";
import "./IUniswapV3Factory.sol";
import "./RewardMath.sol";
import "./console.sol";
import "./TickMath.sol";
import "./FullMath.sol";
interface IERC20Decimals is IERC20 {
    function decimals() external view returns (uint8);
}


contract Mimisbrunnr is ERC20 {
    //  deposits[owner][Pool] = liquidity;
    mapping (address => mapping (address => uint128)) public deposits;
    mapping(address => uint256) public rewards;

    struct PoolParams  {
        address pool;
        uint24 fee;
        bool wethIsToken0;
        uint128 protocolOwnedLiquidity;
        uint256 mimisPosition;
    }
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 
    //address MIMISWETH;

    address VITA = 0x81f8f0bb1cB2A06649E51913A151F0E7Ef6FA321;
    //address VITAWETH = 0xcBcC3cBaD991eC59204be2963b4a87951E4d292B;

    //address ATH = 0xa4ffdf3208f46898ce063e25c1c43056fa754739;

    address HAIR = 0x9Ce115f0341ae5daBC8B477b74E83db2018A6f42;
    //address HAIRWETH = 0x94DD312F6Cb52C870aACfEEb8bf5E4e28F6952ff;

    address GROW = 0x761A3557184cbC07b7493da0661c41177b2f97fA;
    //address GROWWETH = 0x61847189477150832D658D8f34f84c603Ac269af;

    address LAKE =  0xF9Ca9523E5b5A42C3018C62B084Db8543478C400;
    //address LAKEWETH = 0xeFd69F1FF464Ed673dab856c5b9bCA4D2847a74f;

    address RSC = 0xD101dCC414F310268c37eEb4cD376CcFA507F571;
    //address RSCWETH = 0xeC2061372a02D5e416F5D8905eea64Cab2c10970;

    PoolParams MIMSWETH = PoolParams({
        pool: address(0),
        fee: 10000,
        wethIsToken0: false,
        protocolOwnedLiquidity: 0,
        mimisPosition: 0
    });

    PoolParams VITAWETH = PoolParams({
        pool: 0xcBcC3cBaD991eC59204be2963b4a87951E4d292B,
        fee: 10000,
        wethIsToken0: false,
        protocolOwnedLiquidity: 0,
        mimisPosition: 0
    });

    PoolParams HAIRWETH = PoolParams({
        pool: 0x94DD312F6Cb52C870aACfEEb8bf5E4e28F6952ff,
        fee: 10000,
        wethIsToken0: false,
        protocolOwnedLiquidity: 0,
        mimisPosition: 0
    });

    PoolParams GROWWETH = PoolParams({
        pool: 0x61847189477150832D658D8f34f84c603Ac269af,
        fee: 10000,
        wethIsToken0: false,
        protocolOwnedLiquidity: 0,
        mimisPosition: 0
    });

    PoolParams LAKEWETH = PoolParams({
        pool: 0xeFd69F1FF464Ed673dab856c5b9bCA4D2847a74f,
        fee: 3000,
        wethIsToken0: true,
        protocolOwnedLiquidity: 0,
        mimisPosition: 0
    });

    PoolParams RSCWETH = PoolParams({
        pool: 0xeC2061372a02D5e416F5D8905eea64Cab2c10970,
        fee: 10000,
        wethIsToken0: true,
        protocolOwnedLiquidity: 0,
        mimisPosition: 0
    });

    //address ATH = 0xa4ffdf3208f46898ce063e25c1c43056fa754739;

    mapping (address => PoolParams) public pools;
    

    INonfungiblePositionManager public infpm = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    IUniswapV3Factory public factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    uint256 startTime;
    uint256 rewardMultiplier;
    address operator;
    uint128 totalProtocolOwnedLiquidity;

    constructor() ERC20("Mimisbrunnr", "MIMS") {
        _mint(msg.sender, 0);
        startTime = block.timestamp;
        rewardMultiplier = 1;
        operator = msg.sender;

        pools[VITA] = VITAWETH;
        pools[RSC] = RSCWETH;
        pools[LAKE] = LAKEWETH;
        pools[GROW] = GROWWETH;
        pools[HAIR] = HAIRWETH;
    }

    function setMimsPool(address mimisEthPool) public {
        require(msg.sender == operator);
        IUniswapV3Pool pool = IUniswapV3Pool(mimisEthPool);
        MIMSWETH.fee = pool.fee();
        MIMSWETH.wethIsToken0 = (pool.token0() == WETH);
        MIMSWETH.protocolOwnedLiquidity = 0;
        pools[address(this)] = MIMSWETH;
    }

    function addPool(address token, PoolParams calldata poolParams) public {
        require(msg.sender == operator, "only callable by owner");
        pools[token] = poolParams;
        setMimisPositionForToken(token, poolParams.mimisPosition);
    }

    function setMimisPositionForToken(address token, uint256 tokenId) public {
        require(msg.sender == operator, "only callable by owner");
        pools[token].mimisPosition = tokenId;
        (, , ,,,,, uint128 liquidity, , , , ) = infpm.positions(tokenId);
        pools[token].protocolOwnedLiquidity = liquidity;
        totalProtocolOwnedLiquidity += liquidity;
        _mint(address(this), liquidity);
        IERC20(token).approve(address(infpm), type(uint256).max);
        IERC20(WETH).approve(address(infpm), type(uint256).max);
    }

    function sqrtPriceX96ToUint(uint160 sqrtPriceX96, uint8 decimalsToken0)
        internal
        pure
        returns (uint256)
    {
        uint256 numerator1 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        uint256 numerator2 = 10**decimalsToken0;
        return FullMath.mulDiv(numerator1, numerator2, 1 << 192);
    }

    function onlyValidTokens(address token) internal view {
        require((token == WETH || token == VITA || token == HAIR || token == GROW || token == LAKE || token == RSC), "invalid token");
    }

    /*
    function stakes(uint256 erc721Id)
        public
        view
        returns (uint160 secondsPerLiquidityInsideInitialX128, uint128 liquidity)
    {
        Stake storage stake = _stakes[erc721Id];
        secondsPerLiquidityInsideInitialX128 = stake.secondsPerLiquidityInsideInitialX128;
        liquidity = stake.liquidityNoOverflow;
        if (liquidity == type(uint96).max) {
            liquidity = stake.liquidityIfOverflow;
        }
    }
    */

   function mergeLiquidity(
       uint256 erc721Id,
       uint256 mimisPosition,
       uint128 liquidity
   ) internal returns (uint128 liquidityAdded){
        INonfungiblePositionManager.DecreaseLiquidityParams memory decreaseParams =
        INonfungiblePositionManager.DecreaseLiquidityParams({
            tokenId: erc721Id,
            liquidity: liquidity,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp + 3600
        });
        (uint256 returnedAmount0 , uint256 returnedAmount1 ) = infpm.decreaseLiquidity(decreaseParams);
        INonfungiblePositionManager.CollectParams memory collectParams =
        INonfungiblePositionManager.CollectParams({
            tokenId: erc721Id,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });
        (uint256 collected0, uint256 collected1 ) = infpm.collect(collectParams);
        INonfungiblePositionManager.IncreaseLiquidityParams memory increaseParams =
        INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: mimisPosition,
                amount0Desired: collected0,
                amount1Desired: collected1,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp + 3600
        });
        (liquidityAdded, ,) = infpm.increaseLiquidity(increaseParams);
        console.log('increased');
   }

   //event Tick (int24 indexed tickLower, int24 tickUpper);
    function sellLP(
        uint256 erc721Id
    ) public {
        (, , address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint128 liquidity, , , , ) = infpm.positions(erc721Id);
        // Ensure to Require minimum and maximum tick
        //emit Tick(tickLower, tickUpper);
        require(tickLower <= int24(-887200) , "Mimisbrunnr doesnt support concentrated liquidity");
        require(tickUpper >= int24(887200), "Mimisbrunnr doesnt support concentrated liquidity");
        address owner = infpm.ownerOf(erc721Id);
        require(owner == msg.sender, "must be owner of nft");
        require(liquidity > 0, "must have a liquidity greater than zero");
        bool wethIsToken0 = (token0 == WETH);
        PoolParams memory poolParams = pools[(wethIsToken0 ? token1: token0)];
        require(poolParams.pool != address(0), 'must be a valid pool');
        IUniswapV3Pool pool = IUniswapV3Pool(poolParams.pool);
        
        infpm.transferFrom(msg.sender, address(this), erc721Id);
        uint128 liquidityAdded = mergeLiquidity(
            erc721Id,
            poolParams.mimisPosition,
            liquidity
        );
        deposits[msg.sender][address(pool)] += liquidityAdded;
        pools[(wethIsToken0 ? token1: token0)].protocolOwnedLiquidity += liquidityAdded;
        console.log('sellLP:liquidityAdded', liquidityAdded);
        totalProtocolOwnedLiquidity += liquidityAdded;
        infpm.burn(erc721Id);
        _mint(msg.sender, liquidity);
    }

    function unwrapMims(
        uint256 amount
    ) public {
       address[5] memory poolAddrs = [VITA, RSC, LAKE, GROW, HAIR];
       //IUniswapV3Pool mimsPool = IUniswapV3Pool(MIMSWETH.pool);
       for (uint i =0; i< poolAddrs.length; i++) {
            //console.log('poolAddrs[i]', poolAddrs[i]);
            PoolParams memory poolParams = pools[poolAddrs[i]];
            //IUniswapV3Pool pool = IUniswapV3Pool(poolParams.pool);
            if (poolParams.protocolOwnedLiquidity == 0 || totalProtocolOwnedLiquidity == 0) {
               //console.log('no liquidity for this pair or liquidity left in mimisbrunnr');
            } else {
                uint256 calcedLiquidity = FullMath.mulDiv(amount, uint256(poolParams.protocolOwnedLiquidity), uint256(totalProtocolOwnedLiquidity));
                //console.log('calcledliquidity', calcedLiquidity);
                //console.log('uint128(calcedliquidity)', uint128(calcedLiquidity));
                if (calcedLiquidity == 0) {
                    console.log('liquidity is zero for this pair, skipping');
                } else {
                    INonfungiblePositionManager.DecreaseLiquidityParams memory decreaseParams =
                    INonfungiblePositionManager.DecreaseLiquidityParams({
                        tokenId: poolParams.mimisPosition,
                        liquidity: uint128(calcedLiquidity),
                        amount0Min: 0,
                        amount1Min: 0,
                        deadline: block.timestamp + 3600
                    });
                    (uint256 amount0, uint256 amount1) = infpm.decreaseLiquidity(decreaseParams);
                    INonfungiblePositionManager.CollectParams memory collectParams =
                    INonfungiblePositionManager.CollectParams({
                        tokenId: poolParams.mimisPosition,
                        recipient: address(this),
                        amount0Max: type(uint128).max,
                        amount1Max: type(uint128).max
                    });
                    (uint256 colAmount0, uint256 colAmount1) = infpm.collect(collectParams);
                    if (uint128(calcedLiquidity) > totalProtocolOwnedLiquidity) {
                        totalProtocolOwnedLiquidity = 0;
                    } else {
                        totalProtocolOwnedLiquidity -= uint128(calcedLiquidity);
                    }
                    if (pools[poolAddrs[i]].protocolOwnedLiquidity < uint128(calcedLiquidity)) {
                        pools[poolAddrs[i]].protocolOwnedLiquidity = 0;
                    } else {
                        pools[poolAddrs[i]].protocolOwnedLiquidity -= uint128(calcedLiquidity);
                    }
                    //console.log('liquidity decreased');
                    // unwrappers earn the tokens staked as LP
                    (poolParams.wethIsToken0 ? IERC20(WETH).transfer(msg.sender, amount0) : IERC20(poolAddrs[i]).transfer(msg.sender, amount0));
                    (!poolParams.wethIsToken0 ? IERC20(WETH).transfer(msg.sender, amount1) : IERC20(poolAddrs[i]).transfer(msg.sender, amount1));
                    // Mimsbrunnr earns the rewards earned on the LP 
                    if (colAmount0 > amount0) {
                        (poolParams.wethIsToken0 ? IERC20(WETH).transfer(operator, colAmount0 - amount0) : IERC20(poolAddrs[i]).transfer(msg.sender, colAmount0 - amount0));
                    }
                    if (colAmount1 > amount1) {
                        (!poolParams.wethIsToken0 ? IERC20(WETH).transfer(operator, colAmount1 - amount1) : IERC20(poolAddrs[i]).transfer(msg.sender, colAmount1 - amount1));
                    }
                }
            }
       }
        _burn(msg.sender, amount);
    }
    /*
    function claimReward(
        uint256 erc721Id
    ) external {
        Deposit memory deposit = deposits[erc721Id];
        require(deposit.owner == msg.sender, "sender must own deposit");
        (, , address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint128 liquidity, , , , ) = infpm.positions(erc721Id);
        IUniswapV3Pool pool = IUniswapV3Pool(
            (token0 == WETH ? poolAddresses[token1] : poolAddresses[token0])
        );

        (, uint160 secondsPerLiquidityInsideX128, ) =
            pool.snapshotCumulativesInside(deposit.tickLower, deposit.tickUpper);
        (uint160 secondsPerLiquidityInsideInitialX128,) = stakes(erc721Id);
        (uint256 reward, uint160 secondsInsideX128) =
            RewardMath.computeRewardAmount(
                startTime,
                liquidity,
                secondsPerLiquidityInsideInitialX128,
                secondsPerLiquidityInsideX128,
                block.timestamp,
                rewardMultiplier
            );
        totalSecondsClaimedX128 += secondsInsideX128;

        rewards[msg.sender] -= reward;
        _mint(msg.sender, reward);
        //emit RewardClaimed(to, reward);
    }
    */
}
