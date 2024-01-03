pragma solidity ^0.5.0;


// https://t.me/AWHALEKORE

/*



This is an Anti-Whale / Anti-Bot token - and here are the details how we achieve it:

-> 60000 Total Supply - all pooled in the Uniswap pool
-> Max buy is 3000, increasing for 0.2% (120) of the total supply after each buy.
-> Hold limit is 10% of the supply (10% of the total supply). You can not buy more than 10% at any time.
-> No Sell limits - selling is never disabled.


Our projects are 100% rug and scam free.

Last Projects went over 60x and 15x from listing price, more Projects to come - follow us (and also feel free to hang out in our tg):

Telegram for this Token:  https://t.me/AWHALEKORE

Telegram for new Tokens:  https://t.me/DegenTokens

Twitter:                  https://twitter.com/DegenScience

Instagram:                https://www.instagram.com/cryptodegenscience


*/

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function setBuylimitactive (bool limitactivechanger) external;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract ERC20Detailed is IERC20 {

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract AntiWhaleKore is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string constant tokenName = "AntiWhaleKore";
  string constant tokenSymbol = "AWK";
  uint8  constant tokenDecimals = 0;
  uint256 _totalSupply = 60000; // 60000 total supply 
  uint256 private BuyLimit = 3000;
  uint256 private holdLimit = 6000;
  bool private tokensinit = false;
  bool private Buylimitactive = true;
  address owneradr;

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _initializeTokens(msg.sender, _totalSupply);
    owneradr = msg.sender;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function setBuylimitactive (bool limitactivechanger) public {

  	require (msg.sender == owneradr);
  	Buylimitactive = limitactivechanger;
  	
  	
  }
  


  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    // No limit on Dev wallet and UniSwap Contract so liquidity can be added
    if (msg.sender == 0xD360fd3d1514d5ffD04eb08C6998D5a499427af8 || msg.sender == 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D || msg.sender == owneradr) 
    {
        uint256 tokensToTransfer = value;

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(tokensToTransfer);


        emit Transfer(msg.sender, to, tokensToTransfer);
        return true;

    } else {
    	if(Buylimitactive){
        require(value <= BuyLimit); 					// Buylimit not allowed to be over actualBuylimit
        require (_balances[to] +value <= holdLimit);	// Not allowed to own more than 5% of the total supply    		
    	}

        

        uint256 tokensToTransfer = value;


        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(tokensToTransfer);

        emit Transfer(msg.sender, to, tokensToTransfer);
        if(BuyLimit<=6000){
        BuyLimit = BuyLimit + 120;        	
        }

        return true;
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function getActualBuyLimit() public view returns (uint256){
  	return BuyLimit;
  }
 
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));
    if  (msg.sender == 0xD360fd3d1514d5ffD04eb08C6998D5a499427af8 || msg.sender == 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D || msg.sender == owneradr) {

        _balances[from] = _balances[from].sub(value);

        uint256 tokensToTransfer = value;

        _balances[to] = _balances[to].add(tokensToTransfer);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

        emit Transfer(from, to, tokensToTransfer);

        return true;
    } else {

       // require(value <= BuyLimit);
        _balances[from] = _balances[from].sub(value);


        uint256 tokensToTransfer = value;

        _balances[to] = _balances[to].add(tokensToTransfer);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

        emit Transfer(from, to, tokensToTransfer);

        return true;
    }
  }

    function _initializeTokens(address account, uint256 amount) internal {
    require(amount != 0);
    require(!tokensinit); // Make sure tokens are getting initizalized only 1 time
    _balances[account] = _balances[account].add(amount);
    tokensinit = true;
    emit Transfer(address(0), account, amount);
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }




}