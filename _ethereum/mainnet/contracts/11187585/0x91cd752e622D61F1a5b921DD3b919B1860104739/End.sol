/**
 *Submitted for verification at Etherscan.io on 2020-11-03
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-01
*/

pragma solidity =0.4.24;

// This is a contract from the FinalCore contract suite

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


interface FCore {
    	function approve(address _spender, uint256 _tokens) external returns (bool);
        function transfer(address _to, uint256 _tokens) external returns (bool);
}

contract End {

    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);

    function finishLE() external payable {
	    FCore fm = FCore(msg.sender);
	    fm.approve(UNISWAP_ROUTER_ADDRESS, 11001e18);
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
}