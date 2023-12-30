pragma solidity > 0.6.5;

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

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function mint(address account, uint256 amount) external;
  function burn(address account, uint256 amount) external;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SYNairdrop is Owned {

  event SignUpForAirdrop(address account);

  address[] public airdroplist;
  mapping(address => bool) public signedup;

  function signUpForAirdrop() public {
    require(signedup[msg.sender] == false, "error: Account already signed up for airdrop");
    airdroplist.push(msg.sender);
    signedup[msg.sender] = true;
    emit SignUpForAirdrop(msg.sender);
  }

  function sendAirdrop(IERC20 token, address[] memory account, uint256[] memory amount) public onlyOwner() {
    for( uint k = 0; k < account.length; k++) {
      token.transfer(account[k], amount[k]);
    }
  }

  function clearETH() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  function adminwithdrawtokens(IERC20 token, uint256 amount) public onlyOwner() {
    token.transfer(msg.sender, amount);
  }

  fallback() external payable{
}
  receive() external payable {
}


}