pragma solidity ^0.5.0;

/**
 * caveat! caveat! caveat!
 * After the game is over, RPPG1 tokens will have no value. We will open the next RPPG2 token game as soon as possible according to the rules.
 * The community management will not answer any questions within 1 hour, and we will answer these questions after processing the lock pool transaction.
*/

/**
 * The only community: https://t.me/RankingPrizePoolGame
*/

/**
 * Token game in progress:
 * Token abbreviation: RPPG1
 * Initial number of tokens: 1000
 * Token burning speed: 10%
 * It is recommended to set transaction slippage: 30%? 49.9%
*/

/**
 * Token game rules:
 * 1. We will lock the Uniswap warehouse within 1 hour, and the lock time is 24 hours.
 * 2. After 24 hours, we will cancel the liquidity of the locked position and the game is over.
 * 3. ETH of this token game reward pool = ETH unlocked at the end of the game-ETH initially locked
*/

/**
 * RPPG1 holder ranking reward distribution:
 * 1. Maintain the first place of RPPG1: reward 10% ETH of the bonus pool
 * 2. Maintain the second place of RPPG1: reward 5% ETH of the prize pool
 * 3. Maintain the third place of RPPG1: reward 3% ETH of the bonus pool
 * 4. Keep RPPG1 1-30: 30% of RPPG2 tokens are distributed proportionally
*/

/**
 * RPPG1 (Uniswap) single purchase reward distribution:
 * 1. The first place for one-time purchase of RPPG1: Reward 10% ETH of the total bonus
 * 2. Second place for one-time purchase of RPPG1: Reward 5% ETH of the total bonus.
 * 3. The third place for one-time purchase of RPPG1: Reward 2% ETH of the total bonus
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

contract RPPG1 is ERC20Detailed {

using SafeMath for uint256;
mapping (address => uint256) public _OUTTokenBalances;
mapping (address => mapping (address => uint256)) public _allowed;
string constant tokenName = "t.me/RankingPrizePoolGame";
string constant tokenSymbol = "RPPG1";
uint8  constant tokenDecimals = 18;
uint256 _totalSupply = 1000000000000000000000;


  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _OUTTokenBalances[owner];
  }


  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _OUTTokenBalances[msg.sender]);
    require(to != address(0));

    uint256 OUTTokenDecay = value.div(10);
    uint256 tokensToTransfer = value.sub(OUTTokenDecay);

    _OUTTokenBalances[msg.sender] = _OUTTokenBalances[msg.sender].sub(value);
    _OUTTokenBalances[to] = _OUTTokenBalances[to].add(tokensToTransfer);

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
    require(value <= _OUTTokenBalances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _OUTTokenBalances[from] = _OUTTokenBalances[from].sub(value);

    uint256 OUTTokenDecay = value.div(10);
    uint256 tokensToTransfer = value.sub(OUTTokenDecay);

    _OUTTokenBalances[to] = _OUTTokenBalances[to].add(tokensToTransfer);
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
    _OUTTokenBalances[account] = _OUTTokenBalances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _OUTTokenBalances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _OUTTokenBalances[account] = _OUTTokenBalances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}