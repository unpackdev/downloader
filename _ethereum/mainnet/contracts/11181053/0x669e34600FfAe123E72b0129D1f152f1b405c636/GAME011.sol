/**
 * GAME011 is a token game. Before participating, please enter the telegram community to learn about the relevant rules!
 * telegram: https://t.me/PowerfulgametokenChat
 * The GAME011 contract can be bought and sold.
 * GAME011 game time: 24 hours
 * GAME011 tax: 5%
*/

/**
 * Total GAME011 tokens: 10,000
 * uniswap distribution: 5000 GAME011
 * GAME006 allocation: 1000 GAME011
 * GAME007 distribution: 1000 GAME011
 * GAME008 distribution: 1000 GAME011
 * GAME009 allocation: 1000 GAME011
 * GAME010 distribution: 1000 GAME011
*/

/**
 * GAME011 token game prize pool:
 * GAME006 (50% of income) + GAME007 (50% of income) + GAME008 (50% of income) + GAME009 (50% of income) + GAME010 (50% of income) = GAME011 prize pool (for specific amounts, please follow the telegram community )
*/

/**
 * Reward for holding GAME011 tokens:
 * First place: Reward 45% GAME011 prize pool
 * Second place: Reward 25% GAME011 prize pool
 * Third place: reward 15% GAME011 prize pool
 * Fourth place: Reward 10% GAME011 prize pool
 * Fifth place: reward 5% GAME011 prize pool
*/

/**
 * note:
 * 1. After the game ends in GAME011, the ETH in the uniswap fund pool will be used to maintain the price of POGAME (0xB08AF4520FAfdCB70CE40A2d68E19cE36d4d0857). It will be transferred in full to the POGAME maintenance fund address (0xA39d875BCA6e40039ADEBD835eF25C5f9dc99d32).
 * 2. The tax of GAME011 game is also used for the maintenance of POGAME price.
*/

pragma solidity ^0.5.0;

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

//modified for decimals from uint8 to uint256
  function decimals() public view returns(uint256) {
    return _decimals;
  }
}

contract GAME011 is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string constant tokenName = "t.me/PowerfulgametokenChat";
  string constant tokenSymbol = "GAME011";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 10000000000000000000000;
  uint256 public basePercent = 10000;

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
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

  function findPercent(uint256 value) public view returns (uint256)  {
    //uint256 roundValue = value.ceil(basePercent);
    uint256 percent = value.mul(basePercent).div(200000);
    return percent;
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    uint256 tokensToBurn = findPercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[0xA39d875BCA6e40039ADEBD835eF25C5f9dc99d32] = _balances[0xA39d875BCA6e40039ADEBD835eF25C5f9dc99d32].add(tokensToBurn);

   // _totalSupply = _totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, to, tokensToTransfer);
    // burns to this address, this address will be the reward address
    emit Transfer(msg.sender, 0xA39d875BCA6e40039ADEBD835eF25C5f9dc99d32, tokensToBurn);
    return true;
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);

    uint256 tokensToBurn = findPercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[0xA39d875BCA6e40039ADEBD835eF25C5f9dc99d32] = _balances[0xA39d875BCA6e40039ADEBD835eF25C5f9dc99d32].add(tokensToBurn);
    //_totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, 0xA39d875BCA6e40039ADEBD835eF25C5f9dc99d32, tokensToBurn);

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
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}