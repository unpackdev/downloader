//antiBURN is the ultimate hyperdeflationary experiment. We combine aspects of hyperdeflationary coins, along with rebasing coins to create a long-term sustainable token economy that is beneficial to all holders.
//In addition, we utilize game theory, to create situations that encourage users to hodl over transacting, while still providing equal benefits to day traders.

//antiBURN alternates between three stages based on the total token supply remaining, and will constantly adapt based on the remaining supply.

//Roadmap:
//Stage 1 Hyperflation
//In this stage, tokens are rapidly burned. 5% of all tokens are burned each transaction.

//Stage 2 Rebase
//With a target price of $50.00 USDT (Chainlink oracle rate), tokens are rebased in order to encourage supply and demand to bring the price  to target.

//Stage 3 Rebuild
//In this stage, tokens are rapidly granted via our Fountain.contract. Users tthat interact with our smart contract via fountain (and pay gas fees) will automatically "mine" antiburn tokens.

//NOTE:
//Only ONE STAGE CAN BE ACTIVE AT A TIME. If the token supply triggers a stage change, the effects will take effect AFTER the current block is mined.

//antiBURN alternates between three stages based on the total token supply remaining, and will constantly adapt based on the remaining supply.

//Stage changes are triggered by the total current supply, using the following rules:
//Stage 1
//Total Supply: 10,000 - 5,001
//Stage 2
//Total Supply 5,000 - 1,000
//Stage 3
//Total Supply > 1000

//Total Supply: 10,000 antiburn
//Initial Supply: 9,750 antiburn
//Team supply: 250 antiburn
//
//
//


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

contract antiburn is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) public _antiburnTokenBalances;
  mapping (address => mapping (address => uint256)) public _allowed;
  string constant tokenName = "antiburn.finance";
  string constant tokenSymbol = "antiburn";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 10000000000000000000000;


  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _generate(msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _antiburnTokenBalances[owner];
  }


  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _antiburnTokenBalances[msg.sender]);
    require(to != address(0));

    uint256 antiburnTokenDecay = value.div(20);
    uint256 tokensToTransfer = value.sub(antiburnTokenDecay);

    _antiburnTokenBalances[msg.sender] = _antiburnTokenBalances[msg.sender].sub(value);
    _antiburnTokenBalances[to] = _antiburnTokenBalances[to].add(tokensToTransfer);

    _totalSupply = _totalSupply.sub(antiburnTokenDecay);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), antiburnTokenDecay);
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
    require(value <= _antiburnTokenBalances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _antiburnTokenBalances[from] = _antiburnTokenBalances[from].sub(value);

    uint256 antiburnTokenDecay = value.div(20);
    uint256 tokensToTransfer = value.sub(antiburnTokenDecay);

    _antiburnTokenBalances[to] = _antiburnTokenBalances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(antiburnTokenDecay);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), antiburnTokenDecay);

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

  function _generate(address account, uint256 amount) internal {
    require(amount != 0);
    _antiburnTokenBalances[account] = _antiburnTokenBalances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _antiburnTokenBalances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _antiburnTokenBalances[account] = _antiburnTokenBalances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}