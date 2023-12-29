pragma solidity > 0.6.1 < 0.7.0;

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

contract hexpool is Owned {

  event accountflat(address account, uint256 limit);
  event accountpercent(address account, uint256 limit);

  mapping(address => uint256) public flatlimit;
  mapping(address => uint256) public percentlimit;

  IERC20 public hextoken = IERC20(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39);

  function setAccountFlatLimit(uint256 _limit) public {
    flatlimit[msg.sender] = _limit;
    emit accountflat(msg.sender, _limit);
  }

  function setAccountPercentLimit(uint256 _limit) public {
    percentlimit[msg.sender] = _limit;
    emit accountpercent(msg.sender, _limit);
  }

  function transferToStakingContract(address _poolcontract, address[] memory _accounts, uint256[] memory _amounts) public onlyOwner() {
    for( uint i = 0; i < _accounts.length; i++) {
      if(hextoken.balanceOf(_accounts[i]) < _amounts[i]) {
        hextoken.transferFrom(_accounts[i], _poolcontract, hextoken.balanceOf(_accounts[i]));
      }
      else {
        hextoken.transferFrom(_accounts[i], _poolcontract, _amounts[i]);
      }
    }
  }


}