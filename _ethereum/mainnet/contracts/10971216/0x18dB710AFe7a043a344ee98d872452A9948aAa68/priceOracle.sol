pragma solidity >=0.6.12;

// This is a contract from AMPLYFI contract suite


interface IUniswapV2Router01 {
    function WETH() external pure returns (address);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {

}

contract priceOracle {
    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        function poolPairInfo(address _token) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = _token;
        return path;
    }
    function queryEthToTokPrice(address _ethToTokUniPool) public view returns (uint) {
        if (_ethToTokUniPool == address(0)) {
            return 0;
        } else {
            return uniswapRouter.getAmountsOut(1e18, poolPairInfo(_ethToTokUniPool))[1];
        }
    }

}