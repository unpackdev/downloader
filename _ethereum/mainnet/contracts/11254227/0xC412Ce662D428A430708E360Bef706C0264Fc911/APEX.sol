pragma solidity ^0.5.0;

/*
 * APEX TOKEN, Create a telegram group for the community if you like.
 * I will add the liquidity first, but disable trade(all details see the NOTE) 
 * wish you guys read the contract and promote this before it started, if you like the idea of 100% fair launch.
 
 * 100,000,000 total suply, no mint, 2% burn
 * 2000000 tokens max per transcation
 * no tokens for Dev
 * Dev will keep anonmansy

 * NOTE: I will enbale DEV MODE to make sure no BOT can trade before I lock the liquidity
 * NOTE: I will add 0.5 ETH to the liquidity and locked all 100% tokens at 2020-11-14 14:00 UTC time for 1 month
 * NOTE: Trade will be enbale at UTC time: 2020-11-14 14:10 UTC time
 * NOTE: Unlimit the 2M tokens transaction limitation at 2020-11-14 15:00 UTC time
 * NOTE: I will 100% make sure it will be a fair distribution 
*/

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

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

  uint8 public _Tokendecimals;
  string public _Tokenname;
  string public _Tokensymbol;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
   
    _Tokendecimals = decimals;
    _Tokenname = name;
    _Tokensymbol = symbol;
    
  }

  function name() public view returns(string memory) {
    return _Tokenname;
  }

  function symbol() public view returns(string memory) {
    return _Tokensymbol;
  }

  function decimals() public view returns(uint8) {
    return _Tokendecimals;
  }
}

contract APEX is ERC20Detailed{

using SafeMath for uint256;
mapping (address => uint256) public _outputTokenBalances;
mapping (address => mapping (address => uint256)) public _allowed;
string constant tokenName = "APEXToken";
string constant tokenSymbol = "APEX";
uint8  constant tokenDecimals = 18;
uint256 _totalSupply = 100000000 * 10**18;
address dev_wallet = 0xB966ed9729387D37DCE876aFabD9c33e30a79a62;
bool public LimitMode = true;
bool public DevMode = true;
uint256 _maxTransactionTokens = 2000000 * 10**18;
uint8  constant tokenBurnRate = 50;


  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _outputTokenBalances[owner];
  }


  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _outputTokenBalances[msg.sender]);
    require(to != address(0));
    
    if (DevMode) 
    {
       require(msg.sender==dev_wallet, "Dev Mode is on, nobody could trade");
    }
    
    
    if (LimitMode) 
    {
        require(value<=_maxTransactionTokens, "Amount not authorized, please buy less than 200");
    }

    uint256 OUTTokenDecay = value.div(tokenBurnRate);
    uint256 tokensToTransfer = value.sub(OUTTokenDecay);

    _outputTokenBalances[msg.sender] = _outputTokenBalances[msg.sender].sub(value);
    _outputTokenBalances[to] = _outputTokenBalances[to].add(tokensToTransfer);

    _totalSupply = _totalSupply.sub(OUTTokenDecay);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), OUTTokenDecay);
    return true;
  }
  

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }


  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _outputTokenBalances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));
    
    if (DevMode) 
    {
       require(msg.sender==dev_wallet, "Dev Mode is on, nobody could trade");
    }
    
    
    if (LimitMode) 
    {
        require(value<=_maxTransactionTokens, "Amount not authorized, please buy less than 200");
    }

    _outputTokenBalances[from] = _outputTokenBalances[from].sub(value);

    uint256 OUTTokenDecay = value.div(tokenBurnRate);
    uint256 tokensToTransfer = value.sub(OUTTokenDecay);

    _outputTokenBalances[to] = _outputTokenBalances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(OUTTokenDecay);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), OUTTokenDecay);

    return true;
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

  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _outputTokenBalances[account] = _outputTokenBalances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _outputTokenBalances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _outputTokenBalances[account] = _outputTokenBalances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
  
      function disableLimitMode() public {
    require (msg.sender == dev_wallet);
    LimitMode = false;
  }
  
      function enableLimitMode() public {
    require (msg.sender == dev_wallet);
    LimitMode = true;
  }
  
     function enableDevMode() public {
    require (msg.sender == dev_wallet);
    DevMode = true;
  }
  
     function disableDevMode() public {
    require (msg.sender == dev_wallet);
    DevMode = false;
  } 
  
}