pragma solidity =0.4.12;

// This is a contract from AMPLYFI contract suite

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}


interface Amp {
    	function approve(address _spender, uint256 _tokens) external returns (bool);
        function transfer(address _to, uint256 _tokens) external returns (bool);
}

contract Fin {

    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);

    function finishLE() external payable {
	    Amp Am = Amp(msg.sender);
	    Am.approve(UNISWAP_ROUTER_ADDRESS, 21000e18);
	    uint256 _bal = msg.value;
	   uniswapRouter.addLiquidityETH.value(_bal)(
        msg.sender,
        _bal * 4,
        _bal * 4,
        _bal,
        msg.sender,
        block.timestamp + 43200);
     }
}