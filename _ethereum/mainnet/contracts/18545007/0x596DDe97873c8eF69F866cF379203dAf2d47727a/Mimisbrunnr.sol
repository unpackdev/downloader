// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import "./ERC20.sol";
import  "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./INonfungiblePositionManager.sol";
import "./IUniswapV3Pool.sol";
import "./PoolAddress.sol";
import "./IUniswapV3Factory.sol";
import "./TickMath.sol";
import "./FullMath.sol";
import "./IStaker.sol";
interface IERC20Decimals is IERC20 {
    function decimals() external view returns (uint8);
}


contract Mimisbrunnr is ERC20 {
    address STAKER = address(0);

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
    
    PoolParams MIMISWETH = PoolParams({
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
    address[] public poolAddrs;

    INonfungiblePositionManager public infpm = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    IUniswapV3Factory public factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    uint256 startTime;
    address operator;
    uint128 public totalProtocolOwnedLiquidity;
    uint256 protocolFee;

    constructor() ERC20("Mimisbrunnr", "MIMIS") {
        _mint(msg.sender, 0);
        startTime = block.timestamp;
        protocolFee = 50000; //5%
        operator = msg.sender;

        pools[VITA] = VITAWETH;
        pools[RSC] = RSCWETH;
        pools[LAKE] = LAKEWETH;
        pools[GROW] = GROWWETH;
        pools[HAIR] = HAIRWETH;

        poolAddrs = [VITA, RSC, LAKE, GROW, HAIR];
    }

    function setProtocolFee(uint256 fee) public {
        require(msg.sender == operator, "only callable by owner");
        require (fee <= 50000, "fee must be less than 5%");
        protocolFee = fee;
    }

    function setStakingContract(address staker) public {
        require(msg.sender == operator, "only callable by owner");
        STAKER = staker;
    }

    function setMimisPool(address mimisEthPool) public {
        require(msg.sender == operator);
        IUniswapV3Pool pool = IUniswapV3Pool(mimisEthPool);
        MIMISWETH.fee = pool.fee();
        MIMISWETH.wethIsToken0 = (pool.token0() == WETH);
        MIMISWETH.protocolOwnedLiquidity = 0;
        // it'd be hilarious to make this recursive but no
        //pools[address(this)] = MIMISWETH;
    }

    function addPool(address token, PoolParams calldata poolParams) public {
        require(msg.sender == operator, "only callable by owner");
        pools[token] = poolParams;
        poolAddrs.push(token);
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
        infpm.decreaseLiquidity(decreaseParams);
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
        //deposits[msg.sender][address(pool)] += liquidityAdded;
        pools[(wethIsToken0 ? token1: token0)].protocolOwnedLiquidity += liquidityAdded;
        totalProtocolOwnedLiquidity += liquidityAdded;
        infpm.burn(erc721Id);
        _mint(msg.sender, liquidityAdded);
    }

    function unwrapMimis(
        uint256 amount
    ) public {
       //IUniswapV3Pool mimsPool = IUniswapV3Pool(MIMSWETH.pool);
       uint128 initialProtocolOwnedLiquidity = totalProtocolOwnedLiquidity;
       for (uint i =0; i< poolAddrs.length; i++) {
            PoolParams memory poolParams = pools[poolAddrs[i]];
            uint256 calcedLiquidity = FullMath.mulDiv(amount, uint256(poolParams.protocolOwnedLiquidity), uint256(initialProtocolOwnedLiquidity));
            if (calcedLiquidity == 0) {
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
                totalProtocolOwnedLiquidity -= uint128(calcedLiquidity);
                pools[poolAddrs[i]].protocolOwnedLiquidity -= uint128(calcedLiquidity);
                (poolParams.wethIsToken0 ? IERC20(WETH).transfer(msg.sender, amount0) : IERC20(poolAddrs[i]).transfer(msg.sender, amount0));
                (!poolParams.wethIsToken0 ? IERC20(WETH).transfer(msg.sender, amount1) : IERC20(poolAddrs[i]).transfer(msg.sender, amount1));
                // Mimsbrunnr earns the rewards earned on the LP
                // In current versions it would likely make sense to automatically reinvest a portion of these rewards into the pools
                if (colAmount0 > amount0) {
                    uint256 fee = FullMath.mulDiv(colAmount0 - amount0, protocolFee, 1000000);
                    uint256 amountToReward = colAmount0 - amount0 - fee;
                    if (poolParams.wethIsToken0) {
                        IERC20(WETH).transfer(STAKER, amountToReward);
                        IStaker(STAKER).fundIncentive(WETH, amountToReward);
                    } else {
                        IERC20(poolAddrs[i]).transfer(STAKER, amountToReward);
                        IStaker(STAKER).fundIncentive(poolAddrs[i], amountToReward);
                    }
                }
                if (colAmount1 > amount1) {
                    uint256 fee = FullMath.mulDiv(colAmount1 - amount1, protocolFee, 1000000);
                    uint256 amountToReward = colAmount1 - amount1 - fee;
                    if (poolParams.wethIsToken0) {
                        IERC20(poolAddrs[i]).transfer(STAKER, amountToReward);
                        IStaker(STAKER).fundIncentive(poolAddrs[i], amountToReward);
                    } else {
                        IERC20(WETH).transfer(STAKER, amountToReward);
                        IStaker(STAKER).fundIncentive(WETH, amountToReward);
                    }
                }
            }
       }
        _burn(msg.sender, amount);
    }

    function sweepFees() public { 
        require(msg.sender == operator, 'only operator can call this function'); 
        for (uint i =0; i< poolAddrs.length; i++) {
            IERC20(poolAddrs[i]).transfer(operator, IERC20(poolAddrs[i]).balanceOf(address(this)));
        }

        IERC20(WETH).transfer(operator, IERC20(WETH).balanceOf(address(this)));
    }
}
