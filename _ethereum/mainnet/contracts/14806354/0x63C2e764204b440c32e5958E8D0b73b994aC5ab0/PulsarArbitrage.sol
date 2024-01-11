pragma solidity ^0.8.0;

import "./console.sol";

import "./IERC20.sol";

import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";

import "./IPulsarArbitrage.sol";
import "./FlashLoanReceiverBase.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPool.sol";



interface DepositableERC20 is IERC20 {
    function deposit() external payable;
}

contract test is FlashLoanReceiverBaseV1, IPulsarArbitrage {

    using SafeMath for uint256;
    uint timeout; // timeout

    address public uniswapRouterV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    DepositableERC20 wethToken = DepositableERC20(wethAddress);

    constructor(address _addressProvider) FlashLoanReceiverBaseV1(_addressProvider) public{
       
    }

    function getTime() public view returns (uint) {
        console.log("Time: ", timeout);
        return timeout;
    }

    function executeArbitrage(address fromToken, uint256 amountIn, address[] calldata pools) public override returns (uint256){
        console.log("Executing Arbitrage function of the smart contract");
        timeout = block.timestamp + 100;
        bytes memory params = abi.encode(pools);

        ILendingPoolV1 lendingPool = ILendingPoolV1(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), fromToken, amountIn, params);
        return 0;
    }

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    )
        external
        override
    {
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");
        console.log("Executing operation function of the smart contract");

        address[] memory pools = abi.decode(_params, (address[]));

        uint256 nbrOfSwaps = pools.length;

        address toSwap = _reserve;
        uint256 amountToSwap = _amount;


        for (uint8 i = 0; i < nbrOfSwaps; i++) {

            IERC20 sellToken = IERC20(toSwap);
            require(sellToken.approve(address(uniswapRouterV2), amountToSwap),"token to sell approve failed"
            );


            address token0 = IUniswapV2Pair(pools[i]).token0();
            address token1 = IUniswapV2Pair(pools[i]).token1();
            // address dest = i+1 == nbrOfSwaps ? address(this) : pools[i+1];



            address[] memory path = new address[](2);
            path[0] = toSwap == token0 ? token0 : token1;
            path[1] = toSwap == token0 ? token1 : token0;

            uint zero = 0;
            IUniswapV2Router01(uniswapRouterV2).swapExactTokensForTokens(amountToSwap,zero,path,address(this),timeout);
            // console.log("path: ", path[0], " ", path[1]);
            // console.log("Swapping ",amountToSwap );
            // uint256 amountOut = IUniswapV2Router01(uniswapRouterV2).getAmountsOut(amountToSwap, path)[1];

            // console.log("amountOut: ", amountOut);
            // console.log("Swapping ",amountToSwap );
            // console.log("Sell Token ",toSwap );
            // console.log(" pool ",pools[i]);
            console.log(" token0 ",token0);
            console.log(" token1 ",token1);
            // console.log("toSwap == token0",toSwap == token0);
            // console.log("toSwap == token1",toSwap == token1);
            // console.log("dest ",dest);
            // console.log("reserve0 ",_reserve0);
            // console.log("reserve1 ",_reserve1);
            // (uint112 _reserve0, uint112 _reserve1,) = IUniswapV2Pair(pools[i]).getReserves();
            // console.log("Checking first assumption ",(toSwap == token0 ? amountOut : 0 ) < _reserve0 );

        //      ProviderError: Error: VM Exception while processing transaction: reverted with reason string 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT'


            // IUniswapV2Pair(pools[i]).swap(
            //     toSwap == token0 ? 0 : amountToSwap,
            //     toSwap == token1 ? 0 : amountToSwap,
            //     address(this), bytes(""));


            toSwap = toSwap == token0 ? token1 : token0;
            amountToSwap = getBalanceInternal(address(this), toSwap);
        }

        uint totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    function wrapETH() public {
        uint ethBalance = address(this).balance;
        require(ethBalance > 0, "No ETH available to wrap");
        wethToken.deposit{ value: ethBalance }();
    }

}