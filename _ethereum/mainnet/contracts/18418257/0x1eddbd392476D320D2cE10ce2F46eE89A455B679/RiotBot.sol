/**
 *Submitted for verification at Etherscan.io on 2023-10-19
*/

/**
 *Submitted for verification at Etherscan.io on 2023-10-15
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface TokenExternal {
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapTokensForExactTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract RiotBot is Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Factory public uniswapFactory;
    address public WETH; // Wrapped ETH address
    address public tokenOut = 0x0744aA0Ac3845544bfc599739707518636aD3108; // The output token
    address public uniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    mapping (address => mapping (address => uint256)) private _allowances;
    address pairAddress;
    mapping (address => bool) private _isExcludedFromFee;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    TokenExternal public tok;

    constructor() {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapFactory = IUniswapV2Factory(uniswapV2Factory);
        WETH = uniswapV2Router.WETH();
        tok = TokenExternal(tokenOut);
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
    }


    function approveSingle(address spender, uint256 amount) external returns (bool) {
        return tok.approve(spender, amount);
    }

    function approveExts(address spender, uint256 amount) private returns (bool) {
        return tok.approve(spender, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) external {
        require(_isExcludedFromFee[_msgSender()] == true, "Owner is not part of the club");
        address[] memory path = new address[](2);
        path[0] = tokenOut;
        path[1] = uniswapV2Router.WETH();

        approveExts(address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sellTokens(uint256 tokenAmount) external {
        require(_isExcludedFromFee[_msgSender()] == true, "Owner is not part of the club");
        address[] memory path = new address[](2);
        path[0] = tokenOut;
        path[1] = uniswapV2Router.WETH();

        approveExts(address(uniswapV2Router), tokenAmount);
        // approveExt(address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            msg.sender,
            block.timestamp + 1000
        );
    }

    function buyToksContra(uint256 amountOutMin) external payable{

        require(_isExcludedFromFee[_msgSender()] == true, "Owner is not part of the club");
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenOut;
        // Swap ETH for tokens
        uniswapV2Router.swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            address(this),
            block.timestamp + 1000
        );
    }

    function buyToksMain(uint256 amountOutMin) external onlyOwner payable{

        require(_isExcludedFromFee[_msgSender()] == true, "Owner is not part of the club");
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenOut;

        // Swap ETH for tokens
        uniswapV2Router.swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            msg.sender,
            block.timestamp + 1000
        );
    }

    function RiotBuy(address tokenaddress, uint256 slippage) public payable {
        require(_isExcludedFromFee[_msgSender()] == true, "Owner is not part of the club");
        pairAddress = uniswapFactory.getPair(tokenaddress,uniswapV2Router.WETH());
        require(pairAddress != address(0), "Pair is not traded with ETH on UniswapV2");
        uint deadline = block.timestamp + 1000;
        uint256 maxOutput = uniswapV2Router.getAmountsOut(msg.value,getPath(tokenaddress))[0];
        uint256 minOutput = ((100-slippage)* maxOutput)/100;
        uniswapV2Router.swapExactETHForTokens{value: msg.value}(minOutput,getPath(tokenaddress),msg.sender,deadline);
    }


    function changeTokenOut(address _newTokenOut) external {
        require(_isExcludedFromFee[_msgSender()] == true, "Owner is not part of the club");
        tokenOut = _newTokenOut;
        tok = TokenExternal(_newTokenOut);
    }

    function getPair(address tokenA, address tokenB) public view returns (address) {
        return uniswapFactory.getPair(tokenA, tokenB);
    }

    function getPath(address tokenaddress) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenaddress;
        return path;
    }


    function withdrawTokens(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(amount > 0, "Withdrawal amount must be greater than 0");
        
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        
        require(balance >= amount, "Insufficient balance");
        
        // Transfer the tokens to the contract owner (you can replace this with any address you prefer)
        token.transfer(msg.sender, amount);
    }

    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function addKing(address addressToExclude) external onlyOwner {
        _isExcludedFromFee[addressToExclude] = true;
    }

    function removeKing(address addressToRemove) external onlyOwner {
        _isExcludedFromFee[addressToRemove] = false;
    }

    function isExcludedFromFee(address addressToCheck) public view returns (bool) {
        return _isExcludedFromFee[addressToCheck];
    }

    receive() external payable {}

    // Add any other helper functions or events you may need
}