pragma solidity ^0.6.0;

// SPDX-License-Identifier: UNLICENSED

interface ERC20
{
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
}

interface UniswapRouter
{
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
        
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

interface IUniswapV2Factory
{
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair
{
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
}

library SafeMath
{
    function add(uint256 x, uint256 y) public pure returns (uint256 z)
    {
        require((z = x + y) >= x, 'math-add-overflow');
    }

    function sub(uint256 x, uint256 y) public pure returns (uint256 z)
    {
        require((z = x - y) <= x, 'math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) public pure returns (uint256 z)
    {
        require(y == 0 || (z = x * y) / y == x, 'math-mul-overflow');
    }
}

contract Wrapper
{
    using SafeMath for uint256;
        
    address constant public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    UniswapRouter constant public ROUTER = UniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
	IUniswapV2Factory constant public FACTORY = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
	
    address public owner;
	mapping (address => bool) public allow_list;
	
	modifier onlyOwner
    {
        require(tx.origin == owner, "Only owner");
        _;
    }

    modifier onlyWorker
    {
        require(allow_list[tx.origin], "Only allowed worker");
        _;
    }
    
	constructor() public
    {
        owner = msg.sender;
    }
        
    receive() external payable
    {
        
    }

    function pull_eth(uint256 value) public payable onlyOwner
    {
        msg.sender.transfer(value);
    }
    
    function pull_eth_to(address payable receiver, uint256 value) public payable onlyOwner
    {
        receiver.transfer(value);
    }
    
    function pull_token(address token, uint256 value) public onlyOwner
    {
        ERC20(token).transfer(msg.sender, value);
    }
    
    function pull_token_to(address receiver, address token, uint256 value) public onlyOwner
    {
        ERC20(token).transfer(receiver, value);
    }
    
    function allow_address(address a) public onlyOwner
    {
        allow_list[a] = true;
    }
    
    function allow_addresses(address[] memory array) public onlyOwner
    {
        for(uint256 i = 0; i < array.length; i++) allow_list[array[i]] = true;
    }
    
    function cancel_addresses(address[] memory array) public onlyOwner
    {
        for(uint256 i = 0; i < array.length; i++) delete allow_list[array[i]];
    }
    
    function charge_addresses(uint256 limit, address[] memory array) public payable onlyOwner
    {
        uint256 avail = msg.value;
        
        for(uint256 i = 0; i < array.length; i++)
        {
            if(avail == 0) break;
            
            address payable worker = payable(array[i]);
            if(worker.balance < limit)
            {
                uint256 need = limit - worker.balance;
                if(need > avail) need = avail;
                
                worker.transfer(need);
                
                avail -= need;
            }
        }
        
        if(avail > 0) msg.sender.transfer(avail);
    }
    
    function do_direct_call(uint256 _value, address _target, bytes memory _data) public payable onlyWorker returns (bytes memory response)
    {
        (bool success, bytes memory ret) = _target.call{value: _value}(_data);
        require(success);
        response = ret;
    }
    
    function direct_swap(uint256 swapEth, uint256 swapToken, address token) public payable onlyWorker
    {
        require(address(this).balance >= swapEth, "empty");
        
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = token;
        ROUTER.swapExactETHForTokens{value: swapEth}(swapToken, path, address(this), now + 60 minutes);
    }
    
    function packed_swap(uint256 pack) public payable onlyWorker
    {
        uint256 swapEth = uint256(uint48(pack >> 208))*10e18;
        
        require(address(this).balance >= swapEth, "empty");
        
        uint256 swapToken = uint256(uint48(pack >> 160))*10e18;
        address token = address(uint160(pack));
        
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = token;
        ROUTER.swapExactETHForTokens{value: swapEth}(swapToken, path, address(this), now + 60 minutes);
    }
    
    function swap_eth_token0(address token) public payable
    {
        uint256 swapEth = msg.value;
        
        IUniswapV2Pair pair = IUniswapV2Pair(FACTORY.getPair(WETH, token));
        
        (uint256 reserveToken, uint256 reserveEth, ) = pair.getReserves();
        
        uint amountInWithFee = swapEth.mul(997);
        uint numerator = amountInWithFee.mul(reserveToken);
        uint denominator = reserveEth.mul(1000).add(amountInWithFee);
        uint256 swapToken = numerator / denominator;

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = token;
        ROUTER.swapExactETHForTokens{value: swapEth}(swapToken, path, msg.sender, now + 5 minutes);
    }
    
    function swap_eth_token1(address token) public payable
    {
        uint256 swapEth = msg.value;
        
        IUniswapV2Pair pair = IUniswapV2Pair(FACTORY.getPair(WETH, token));
        
        (uint256 reserveEth, uint256 reserveToken, ) = pair.getReserves();
        
        uint amountInWithFee = swapEth.mul(997);
        uint numerator = amountInWithFee.mul(reserveToken);
        uint denominator = reserveEth.mul(1000).add(amountInWithFee);
        uint256 swapToken = numerator / denominator;
        
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = token;
        ROUTER.swapExactETHForTokens{value: swapEth}(swapToken, path, msg.sender, now + 5 minutes);
    }
    
    function swap_token0_eth(address token, uint256 swapToken) public
    {
        IUniswapV2Pair pair = IUniswapV2Pair(FACTORY.getPair(WETH, token));
        
        (uint256 reserveToken, uint256 reserveEth, ) = pair.getReserves();
        
        uint amountInWithFee = swapToken.mul(997);
        uint numerator = amountInWithFee.mul(reserveEth);
        uint denominator = reserveToken.mul(1000).add(amountInWithFee);
        uint256 swapEth = numerator / denominator;
        
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WETH;
        ROUTER.swapExactTokensForETH(swapToken, swapEth, path, msg.sender, now + 5 minutes);
    }
    
    function swap_token1_eth(address token, uint256 swapToken) public
    {
        IUniswapV2Pair pair = IUniswapV2Pair(FACTORY.getPair(WETH, token));
        
        (uint256 reserveEth, uint256 reserveToken, ) = pair.getReserves();
        
        uint amountInWithFee = swapToken.mul(997);
        uint numerator = amountInWithFee.mul(reserveEth);
        uint denominator = reserveToken.mul(1000).add(amountInWithFee);
        uint256 swapEth = numerator / denominator;
        
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WETH;
        ROUTER.swapExactTokensForETH(swapToken, swapEth, path, msg.sender, now + 5 minutes);
    }
    
    function swap_all_token0_eth(address token) public
    {
        swap_token0_eth(token, ERC20(token).balanceOf(msg.sender));
    }
    
    function swap_all_token1_eth(address token) public
    {
        swap_token1_eth(token, ERC20(token).balanceOf(msg.sender));
    }
}