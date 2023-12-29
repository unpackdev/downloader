/**

$$$$$$$\         $$$$$$\        $$$$$$$$\        $$$$$$\  
$$  __$$\       $$  __$$\       \__$$  __|      $$  __$$\ 
$$ |  $$ |      $$ /  $$ |         $$ |         $$ /  \__|
$$$$$$$  |      $$$$$$$$ |         $$ |         \$$$$$$\  
$$  __$$<       $$  __$$ |         $$ |          \____$$\ 
$$ |  $$ |      $$ |  $$ |         $$ |         $$\   $$ |
$$ |  $$ |      $$ |  $$ |         $$ |         \$$$$$$  |
\__|  \__|      \__|  \__|         \__|          \______/ 
                                                          
                                                          
                                                          

 */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IUniswapV2RouterV2 {

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender; 
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Rats is IERC20, Ownable{
    string private _name = "Rats";
    string private _symbol = "Rats"; 
    uint8 private _decimals = 18;    
    uint256 private _totalsupply =1000000000000 * 10 ** 18;   
    uint256 public constant MAX = ~uint256(0);
    uint256 public swapFee;
    uint256 public swapTokensAtAmount;
    

    mapping(address => uint256) private _balances;  
    mapping(address => mapping(address => uint256)) private _allowances;    
    mapping(address => bool) public bot;            
    
    address public fund;
    address public liqManage;

    address public UniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public UniswapV2Router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; 
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;   
    address public pair;
    
    bool inswap;
    bool botTime;

    constructor (
        address _fund,
        address _liqManage,
        uint256 _swapFee,
        bool _botTime
    ){
        fund = _fund;
        liqManage = _liqManage;
        swapFee = _swapFee;
        botTime = _botTime;
        _balances[liqManage] = _totalsupply;
        emit Transfer(address(0), liqManage, _totalsupply);

        (address token0, address token1) = sortTokens(WETH, address(this));

        pair = address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            UniswapV2Factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
        )))));

        swapTokensAtAmount = _totalsupply / 5000;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalsupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

        
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private{
        require(!bot[from],'BOT');
        require(from != to,"Same");
        require(amount >0 ,"Zero");
        uint256 balance = _balances[from];
        require(balance >= amount, "balance Not Enough");
        _balances[from] = _balances[from] - amount;

        if(inswap){ 
            _balances[to] +=amount;
            emit Transfer(from, to, amount);
            return;
        }
        if(balanceOf(pair) ==0 && from == liqManage && to == pair){
            _balances[to] +=amount;
            emit Transfer(from, to, amount);
            return;
        }
        if(botTime && from == pair){
            bot[to] =true;
        }
        uint256 transAmount = amount;
        uint256 feeAmount;
        if(from == pair || to == pair){
            feeAmount = amount* swapFee/100;
            transAmount = amount - feeAmount;

            if(feeAmount>0){
                _balances[address(this)] +=feeAmount;
                emit Transfer(from, address(this), feeAmount); 
            }
        }
        uint256 contractTokenBalance = balanceOf(address(this)); 
        bool overMinTokenBalance = contractTokenBalance >= swapTokensAtAmount;
        if (
            overMinTokenBalance &&
            !inswap &&
            to == pair
        ){
            swapTofund(swapTokensAtAmount);
        }

        _balances[to] +=transAmount;
        emit Transfer(from, to, transAmount); 

        return;
    }

    function swapTofund(uint256 tokenAmount) private{
        require(!inswap,"inSwap");
        inswap =true;
        uint256 swapAmount = tokenAmount;
        IERC20(address(this)).approve(UniswapV2Router02, swapAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        IUniswapV2RouterV2(UniswapV2Router02).swapExactTokensForETHSupportingFeeOnTransferTokens(swapAmount, 0, path, fund, block.timestamp+600);
        inswap =false;
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    function excuteBot(address[] memory _addrList,bool _states) public  onlyOwner{
        for(uint256 i=0;i<_addrList.length;i++){
            bot[_addrList[i]] = _states;
        }
    }

    function setSwapTokenAmounts(uint256 _amounts,uint256 _fee,bool _botTime) public onlyOwner{
        swapTokensAtAmount = _amounts;
        swapFee = _fee;
        botTime = _botTime;
    }

}