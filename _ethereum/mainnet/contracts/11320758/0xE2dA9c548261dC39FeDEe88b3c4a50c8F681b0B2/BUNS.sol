// ------------------------------------------------------------
// ----------------------------------------------------------------------------
// ------------------------------------------------------------
// ----------------------------------------------------------------------------
// ------------------------------------------------------------
//   xxxxxxxxxxx      xxx        xxx     xxxx       xxx     xxxxxxxxxxx
//   xxx         xxx      xxx        xxx     xxxxx     xxx     xxxxxxxxxxx
//   xxx         xx        xxx        xxx     xxx xx    xxx     xxx
//   xxxxxxxx            xxx       xxx     xxx   xx   xxx     xxxxxxxxxxx
//   xxx         xx        xxx        xxx     xxx    xx xxx                    xxx
//   xxx         xxx      xxxxxxxxxxx    xxx     xxxxx      xxxxxxxxxxx
//   xxxxxxxxxxx      xxxxxxxxxxx    xxx       xxxx      xxxxxxxxxxx
// ----------------------------------------------------------------------------
// -------------------------------------------------------------
// ----------------------------------------------------------------------------
// -------------------------------------------------------------
// ----------------------------------------------------------------------------



// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// BUNSWAP is a community owned project and will be one of the best 
// platform in DeFi World. Build with its very own ERC20 Token 
// named BUNSWAP Governance token (BUNS) that aims to provide
// the best services and functionalities, with improved trading
// interface that will satisfy your Trading Experience.
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------



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

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// BUNSWAP is a fully decentralized exchange which was created 
// by Anonymous developers, no owner nor CEO that can manipulate 
// the program. All codes are open source, and no one can modify 
// the smart contract once it was deployed.
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// This is an Owned contract
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------


contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Mathematical Operations
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------


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

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------


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

//   xxxxxxxxxxx      xxx        xxx     xxxx       xxx     xxxxxxxxxxx
//   xxx         xxx      xxx        xxx     xxxxx     xxx     xxxxxxxxxxx
//   xxx         xx        xxx        xxx     xxx xx    xxx     xxx
//   xxxxxxxx            xxx       xxx     xxx   xx   xxx     xxxxxxxxxxx
//   xxx         xx        xxx        xxx     xxx    xx xxx                    xxx
//   xxx         xxx      xxxxxxxxxxx    xxx     xxxxx      xxxxxxxxxxx
//   xxxxxxxxxxx      xxxxxxxxxxx    xxx       xxxx      xxxxxxxxxxx


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// "Hunger Alleviation" - let us alleviate hunger in the World
// Grab a bite now!
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------


contract BUNS is ERC20Detailed ,Owned {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string constant tokenName = "BUNSWAP Governance Token";
  string constant tokenSymbol = "BUNS";
  uint8  constant tokenDecimals = 8;
  uint256 _totalSupply = 5000000000000000;
  uint256 public basePercent = 100;
  
  
  // ----------------------------------------------------------------------------
  // ----------------------------------------------------------------------------
  // All the tokens will be minted to its owner once
  // ----------------------------------------------------------------------------
  // ----------------------------------------------------------------------------
  

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(0x5b9505236aB73Eb80C0D1eAe5aA2baa3d2841eCc, _totalSupply);
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
  
//   xxxxxxxxxxx      xxx        xxx     xxxx       xxx     xxxxxxxxxxx
//   xxx         xxx      xxx        xxx     xxxxx     xxx     xxxxxxxxxxx
//   xxx         xx        xxx        xxx     xxx xx    xxx     xxx
//   xxxxxxxx            xxx       xxx     xxx   xx   xxx     xxxxxxxxxxx
//   xxx         xx        xxx        xxx     xxx    xx xxx                    xxx
//   xxx         xxx      xxxxxxxxxxx    xxx     xxxxx      xxxxxxxxxxx
//   xxxxxxxxxxx      xxxxxxxxxxx    xxx       xxxx      xxxxxxxxxxx  


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// BUNS is a deflationary token that Burns 1% in every transactions
// No mint function after deployment
// No infinite creation of tokens 
// Decreases in realtime
// No Hack Exploit
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------


  function findOnePercent(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 onePercent = roundValue.mul(basePercent).div(10000);
    return onePercent;
  }
  
  function isSupplyLessThanOneMillion() public view returns(bool){
      uint256 oneMillion = 100000000000000;
       if(_totalSupply <= oneMillion){
           return true;
       }
       return false;
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    
    if(isSupplyLessThanOneMillion()){
        _balances[msg.sender] =  _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        
        emit Transfer(msg.sender, to, value);
        return true;
        
    }
    else
    {
    uint256 tokensToBurn = findOnePercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);

    _totalSupply = _totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    return true;
    }


  }
  
//   xxxxxxxxxxx      xxx        xxx     xxxx       xxx     xxxxxxxxxxx
//   xxx         xxx      xxx        xxx     xxxxx     xxx     xxxxxxxxxxx
//   xxx         xx        xxx        xxx     xxx xx    xxx     xxx
//   xxxxxxxx            xxx       xxx     xxx   xx   xxx     xxxxxxxxxxx
//   xxx         xx        xxx        xxx     xxx    xx xxx                    xxx
//   xxx         xxx      xxxxxxxxxxx    xxx     xxxxx      xxxxxxxxxxx
//   xxxxxxxxxxx      xxxxxxxxxxx    xxx       xxxx      xxxxxxxxxxx

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Let us put Multiple Transfer Function
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------


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
    
    if(isSupplyLessThanOneMillion()){
      
    _balances[from] = _balances[from].sub(value);


    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, value);

    return true;
    }
    else
    {

    _balances[from] = _balances[from].sub(value);

    uint256 tokensToBurn = findOnePercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), tokensToBurn);

    return true;
    }


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
  
//   xxxxxxxxxxx      xxx        xxx     xxxx       xxx     xxxxxxxxxxx
//   xxx         xxx      xxx        xxx     xxxxx     xxx     xxxxxxxxxxx
//   xxx         xx        xxx        xxx     xxx xx    xxx     xxx
//   xxxxxxxx            xxx       xxx     xxx   xx   xxx     xxxxxxxxxxx
//   xxx         xx        xxx        xxx     xxx    xx xxx                    xxx
//   xxx         xxx      xxxxxxxxxxx    xxx     xxxxx      xxxxxxxxxxx
//   xxxxxxxxxxx      xxxxxxxxxxx    xxx       xxxx      xxxxxxxxxxx  

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Another Burn Functions
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

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