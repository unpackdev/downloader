// SPDX-License-Identifier: MIT

/*

    $REFS is the FIRST EVER On-Chain Referral Community Token

    Website: https://refsharing.com
    Telegram:https://t.me/RefShareToken
    Twitter: https://twitter.com/refsharing


           $$\    
         $$$$$$\      $$$$$$$\   $$$$$$$$\  $$$$$$$$\   $$$$$$\  
        $$  __$$\     $$  __$$\  $$  _____| $$  _____| $$  __$$\ 
        $$ /  \__|    $$ |  $$ | $$ |       $$ |       $$ /  \__|
        \$$$$$$\      $$$$$$$  | $$$$$\     $$$$$\     \$$$$$$\  
         \___ $$\     $$  __$$<  $$  __|    $$  __|     \____$$\ 
        $$\  \$$ |    $$ |  $$ | $$ |       $$ |       $$\   $$ |
        \$$$$$$  |    $$ |  $$ | $$$$$$$$\  $$ |       \$$$$$$  |
        \_$$  _/     \__|  \__| \________| \__|        \______/ 
          \ _/                                         

    A unique ON-CHAIN REFERRAL SYSTEM that let's you earn Ref Shares ($REFS) by recruiting new users to join the Ref Sharing community


    Max Wallet limit 2%, removed after launch.
    Max Transaction limit 2%
*/

pragma solidity ^0.8.18;

abstract contract Context 
{
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}


contract Ownable is Context 
{
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () 
    {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) 
    {
        return _owner;
    }   
    
    modifier onlyOwner() 
    {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner 
    {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner 
    {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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


    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }


    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }


    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }


    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
}



interface IUniswapV2Router01 
{
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}


interface IUniswapV2Router02 is IUniswapV2Router01 
{

}


contract REFShare is Context, IERC20, Ownable 
{
      using SafeMath for uint256;
      mapping (address => uint256) private _balances;
      mapping (address => mapping (address => uint256)) private _allowances;

      mapping (address => address) public _refferer;
      mapping (address =>  bool) public _feeExpempted;
      mapping (address =>  bool) public _limitExpempted;

      uint256 private _totalSupply;
      string private _name;
      string private _symbol;
      uint8 private _decimals;

      address payable public treasuryWallet; 
      address public uniswapV2Pair;
      
      IUniswapV2Router02 public immutable uniswapV2Router;

      uint256 public _maxTxAmount;
      uint256 public _walletMaxLimit;

      uint256 public reffererFee;
      uint256 public treasuryFee;

    constructor() 
    { 

      _name = "REF Share";
      _symbol = "REFS";
      _decimals = 18;


      _mint(msg.sender, 100000000 * 10**18);

      _maxTxAmount = 2000001 * 10**18; // 2%
      _walletMaxLimit = 2000001 * 10**18; // 2%

      treasuryWallet = payable(0x91a4a51463c654D9b1f36F95d8D15CD7A3fA344B);
      
      reffererFee = 3;
      treasuryFee = 1;   

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
    .createPair(address(this), _uniswapV2Router.WETH());
    uniswapV2Router = _uniswapV2Router;

    _feeExpempted[address(this)] = true;
    _feeExpempted[owner()] = true;
    _feeExpempted[treasuryWallet] = true;

    _limitExpempted[address(this)] = true;
    _limitExpempted[owner()] = true;
    _limitExpempted[treasuryWallet] = true;
    _limitExpempted[uniswapV2Pair] = true;
    _limitExpempted[address(_uniswapV2Router)] = true;        

  }



    function name() public view virtual returns (string memory) 
    {
        return _name;
    }

    function symbol() public view virtual returns (string memory) 
    {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) 
    {
        return _decimals;
    }

 
    function totalSupply() public view virtual override returns (uint256) 
    {
        return _totalSupply;
    }


    function balanceOf(address account) public view virtual override returns (uint256) 
    {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) 
    {
        _transferTokens(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) 
    {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) 
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) 
    {
        _transferTokens(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) 
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) 
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function removeWalletMaxLimit() external onlyOwner
    {
        _walletMaxLimit = totalSupply();
    }

    function exemptedFromMaxWalletLimit(address _address, bool _enable) external onlyOwner
    {
        _limitExpempted[_address] = _enable;
    }

    function _transferTokens(address from, address to, uint256 amount) internal virtual 
    {
         if(from != owner() && to != owner()) 
         {
            require(amount <= _maxTxAmount, "Exceeds Max Tx Amount");
         }


         if(!_limitExpempted[to]) 
         {
            require(balanceOf(to).add(amount) <= _walletMaxLimit, "Exceeds Max Wallet Allowed Amount");
         }         


        if(!_feeExpempted[from] && !_feeExpempted[to])
        {
            uint256 reffererFeeTokens = amount.mul(reffererFee).div(100);
            uint256 treasuryFeeTokens = amount.mul(treasuryFee).div(100);

            if(_refferer[to] != address(0) && from==uniswapV2Pair)
            {
                _transfer(from, _refferer[to], reffererFeeTokens);
                _transfer(from, treasuryWallet, treasuryFeeTokens);
            }
            else if(_refferer[from] != address(0) && to==uniswapV2Pair)
            {
                _transfer(from, _refferer[from], reffererFeeTokens);
                _transfer(from, treasuryWallet, treasuryFeeTokens);
            }
            else if(_refferer[from] != address(0) && to != uniswapV2Pair && from != uniswapV2Pair)
            {
                _transfer(from, _refferer[from], reffererFeeTokens);
                _transfer(from, treasuryWallet, treasuryFeeTokens);
            }            
            else  
            {
                _transfer(from, treasuryWallet, reffererFeeTokens+treasuryFeeTokens);
            }
            amount = amount.sub(reffererFeeTokens).sub(treasuryFeeTokens);
        }

        if(_refferer[to]==address(0) && from != uniswapV2Pair && to != uniswapV2Pair)
        {
            _refferer[to] = from;
        }

        _transfer(from, to, amount);

    }


    function _transfer(address sender, address recipient, uint256 amount) internal 
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }



    function _mint(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }



    function _approve(address owner, address spender, uint256 amount) internal virtual 
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}