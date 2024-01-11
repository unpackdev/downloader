// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma abicoder v2;

/// @title BetterFund contract to handle BETTER CLIMATE FUND. 

import "./IERC20.sol";
import "./TransferHelper.sol";
import "./ISwapRouter.sol";
import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract BetterFund is Ownable, ReentrancyGuard, Pausable{
    using SafeMath for uint;
  
    address public better;
    uint24 public feeTierBetter;
    uint24 public feeTier2;
    uint public priceImpactBasisPoints;
    uint public MaxTokensAllowed;
    uint public nextRelease ;
    uint public nextReleaseGapTime;
    uint amountOutMinUSDC;
    uint v3DeadlineTimeInSec;
 
    address public baseToken;
    address public USDC;
    address constant UNI_V3FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant UNI_ROUTER_V3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    IERC20 public betterToken;
    IERC20 public USDCToken;

    bool private initDone;

    IUniswapV3Factory public uniswapFactoryV3;
    ISwapRouter public swapRouter;

    event BetterReleased(address indexed releaser, uint betterOut, uint USDCIn, uint timestamp);
    
    /** @dev init function used instead of constructor to initialize state variables, 
      * Can be called only once. 
      */
    function init(address _betterAddress, address _USDC, address _baseToken,uint _basisPoints, uint24 _feeTierBetter, 
        uint24 _feeTier2, uint _amountOutMinUSDC, uint _v3DeadlineTimeInSec) public {

        require(!initDone, "init done");

        MaxTokensAllowed = 1000000 * 10 ** 18;
        nextRelease = block.timestamp;
        nextReleaseGapTime = 86400;
        better = _betterAddress;
        betterToken = IERC20(_betterAddress);
        USDC = _USDC;
        USDCToken = IERC20(USDC);
        baseToken = _baseToken;
        priceImpactBasisPoints = _basisPoints;
        feeTierBetter = _feeTierBetter;
        feeTier2 = _feeTier2;
        amountOutMinUSDC = _amountOutMinUSDC;
        v3DeadlineTimeInSec = _v3DeadlineTimeInSec;

        uniswapFactoryV3 = IUniswapV3Factory(UNI_V3FACTORY);
        swapRouter = ISwapRouter(UNI_ROUTER_V3);

        // initialize the imported contracts by calling their init() function. 
        _Ownable_init(msg.sender);
        _reentrancyGuard_init();
        _pausable_init();

        initDone = true;
    }

    /** @dev releaseBetter() function swaps better tokens against usdc, using the path better > basetoken -> usdc
      * Can be called only once in 24 hours. 
      * emits BetterReleased event.
      */
    function releaseBetter() public nonReentrant whenNotPaused{ 
        require(block.timestamp >= nextRelease);
        nextRelease = block.timestamp.add(nextReleaseGapTime);

        address betterPoolAddress = uniswapFactoryV3.getPool(better, baseToken, feeTierBetter);
        IUniswapV3PoolState betterPoolState = IUniswapV3PoolState(betterPoolAddress);
            
        uint betterPoolLiquidity = (betterPoolState.liquidity()); 
        (
                uint160 sqrtPriceX96,
                ,
                ,
                ,
                ,
                ,
                
            ) = betterPoolState.slot0(); 
        uint betterPoolVirtualBetter = (betterPoolLiquidity.mul(2**96)).div((sqrtPriceX96)); 
        uint numerator = betterPoolVirtualBetter.mul(sqrt(10**22) - sqrt(10**22-priceImpactBasisPoints.mul(10**18)));
        uint denominator = sqrt(10**22-priceImpactBasisPoints.mul(10**18));
        uint tokensToSell = numerator.div(denominator);  
        if (tokensToSell > MaxTokensAllowed){
            tokensToSell = MaxTokensAllowed;
        }
        
        require(tokensToSell > 0 , "BetterFund: Token amount should be greater than zero");
        require(betterToken.balanceOf(address(this)) >= tokensToSell, "BetterFund: Not enough Tokens");
        TransferHelper.safeApprove(better, UNI_ROUTER_V3, tokensToSell);
        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(better, feeTierBetter, baseToken, feeTier2, USDC),
                recipient: address(this),
                deadline: block.timestamp+v3DeadlineTimeInSec,
                amountIn: tokensToSell,
                amountOutMinimum: amountOutMinUSDC
            });
        uint amountOut = swapRouter.exactInput(params);
        emit BetterReleased(msg.sender, tokensToSell, amountOut, block.timestamp);
    }

    // ================== Admin functions ==================
    
    function setPriceImpactBasisPoints (uint _basisPoints) public onlyOwner{
        require(_basisPoints > 0, "BetterFund: Basis points should be greater than zero");
        priceImpactBasisPoints = _basisPoints;
    }
    function updateFeeTierBetter(uint24 _fee) public onlyOwner{
        require(_fee > 0, "BetterFund: fee should be greater than zero");
        feeTierBetter = _fee;
    }
    function updateFeeTier2(uint24 _fee) public onlyOwner{
        require(_fee > 0, "BetterFund: fee should be greater than zero");
        feeTier2 = _fee;
    }
    function updateAmountOutMinUSDC(uint _amountOutMinUSDC) public onlyOwner{
        amountOutMinUSDC = _amountOutMinUSDC;
    }
    function updateV3DeadlineTimeInSec(uint _v3DeadlineTimeInSec) public onlyOwner{
        v3DeadlineTimeInSec = _v3DeadlineTimeInSec;
    }
    function setMaxTokensAllowed(uint tokensAllowed) public onlyOwner{
        MaxTokensAllowed = tokensAllowed;
    }
    function updateGapTime(uint256 time) public onlyOwner{ 
        nextReleaseGapTime = time;
    }

    // ================== Functions to pause and unpause contract ==================
    
    function PauseContract()public anyAdmin{
        _pause();
    }
    function UnPauseContract()public anyAdmin{
        _unpause();
    }

    // ================== Helper functions ==================
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

}
