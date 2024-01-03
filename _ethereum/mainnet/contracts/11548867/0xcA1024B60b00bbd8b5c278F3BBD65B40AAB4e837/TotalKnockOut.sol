//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner = msg.sender;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  modifier onlyOwner {
    if (msg.sender != owner) revert("Sender is not owner");
    _;
  }

  function changeOwner(address _newOwner)public
  onlyOwner
  {
    if(_newOwner == address(0x0)) revert("new owner address is empty");
    emit OwnershipTransferred(owner,_newOwner);
    owner = _newOwner;
  }
}

contract TotalKnockOut is IERC20,Ownable {

    string public constant name = "TotalKnockOut";
    string public constant symbol = "TKO";
    uint8 public constant decimals = 18;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ = (10**8)*(10**18);

    using SafeMath for uint256;

   constructor(address owner) public {
    balances[owner] = totalSupply_;
    changeOwner(owner);
    }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
     function burn(address account,uint amount) public onlyOwner{
            require(account != address(0), "ERC20: burn from the zero address");
            require(balances[account] >= amount);
            balances[account] = balances[account].sub(amount);
            totalSupply_ = totalSupply_.sub(amount);
            emit Transfer(account, address(0), amount);
        }
        
}

library SafeMath {
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