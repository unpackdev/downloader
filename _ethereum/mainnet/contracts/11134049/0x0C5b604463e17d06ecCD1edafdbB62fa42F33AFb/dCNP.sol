pragma solidity ^0.4.24;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}


contract dCNP is ERC20Interface {
  using SafeMath for uint256;
    string public symbol;
    string public  name;
    uint8 public decimals;
    address public _owner;
    uint256 private _totalSupply;
    uint256 private _rate;
    uint256 private _minAmount;
    uint256 private _maxAmount;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    event TokensPurchased(address indexed purchaser, uint256 value, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
       symbol = "dCNP";
       name = "deCyberNetwork Protocol";
       decimals = 8;
       _owner =  0xb1eb1C820FE48c0550077A7c3678d347843dB287;
       _totalSupply = 28000000 * 10 ** uint256(decimals);
       _balances[address(this)] = _totalSupply;
       _allowed[address(this)][_owner] = _totalSupply;
       _rate = 500;
       _minAmount = 100000000000000000;
       _maxAmount = 200000000000000000000;

    }


  function owner() public view returns(address) {
    return _owner;
  }


  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    require (newOwner != address(this));
    _owner = newOwner;
    emit OwnershipTransferred(_owner, newOwner);

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

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
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
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }


  function _forwardFunds() external onlyOwner {
    require (address(this).balance > 0);
    _owner.transfer(address(this).balance);
  }


  function () external payable {
    require(msg.value >= _minAmount);
    require(msg.value <= _maxAmount);
    uint256 tokenAmount = msg.value.mul(_rate).div(10000000000);
    require (_balances[address(this)] >= tokenAmount);
    _balances[address(this)] = _balances[address(this)].sub(tokenAmount);
    _balances[msg.sender] = _balances[msg.sender].add(tokenAmount);
    emit Transfer(address(this), msg.sender, tokenAmount);
    emit TokensPurchased(msg.sender,  msg.value, tokenAmount);

  }

}