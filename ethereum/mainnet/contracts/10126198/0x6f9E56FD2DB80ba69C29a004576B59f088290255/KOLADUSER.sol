pragma solidity ^0.4.23;
/*
 *             ╔═╗┌─┐┌─┐┬┌─┐┬┌─┐┬   ┌─────────────────────────┐ ╦ ╦┌─┐┌┐ ╔═╗┬┌┬┐┌─┐
 *             ║ ║├┤ ├┤ ││  │├─┤│   │ KOL Community Foundation│ │ ║║║├┤ ├┴┐╚═╗│ │ ├┤
 *             ╚═╝└  └  ┴└─┘┴┴ ┴┴─┘ └─┬─────────────────────┬─┘ ╚╩╝└─┘└─┘╚═╝┴ ┴ └─┘
 *   ┌────────────────────────────────┘                     └──────────────────────────────┐
 *   │    ┌─────────────────────────────────────────────────────────────────────────────┐  │
 *   └────┤ Dev:Jack Koe ├─────────────┤ Special for: KOL  ├───────────────┤ 20200524   ├──┘
 *        └─────────────────────────────────────────────────────────────────────────────┘
 */

 library SafeMath {
   function mul(uint a, uint b) internal pure  returns (uint) {
     uint c = a * b;
     require(a == 0 || c / a == b);
     return c;
   }
   function div(uint a, uint b) internal pure returns (uint) {
     require(b > 0);
     uint c = a / b;
     require(a == b * c + a % b);
     return c;
   }
   function sub(uint a, uint b) internal pure returns (uint) {
     require(b <= a);
     return a - b;
   }
   function add(uint a, uint b) internal pure returns (uint) {
     uint c = a + b;
     require(c >= a);
     return c;
   }
   function max64(uint64 a, uint64 b) internal  pure returns (uint64) {
     return a >= b ? a : b;
   }
   function min64(uint64 a, uint64 b) internal  pure returns (uint64) {
     return a < b ? a : b;
   }
   function max256(uint256 a, uint256 b) internal  pure returns (uint256) {
     return a >= b ? a : b;
   }
   function min256(uint256 a, uint256 b) internal  pure returns (uint256) {
     return a < b ? a : b;
   }
 }

 /**
  * title KOL USER DEV ONCHAIN PRECISION ADVERTISING SYSTEM
  * dev visit: https://github.com/jackoelv/KOL/
 */

 contract ERC20Basic {
   uint public totalSupply;
   function balanceOf(address who) public constant returns (uint);
   function transfer(address to, uint value) public;
   event Transfer(address indexed from, address indexed to, uint value);
 }

 contract ERC20 is ERC20Basic {
   function allowance(address owner, address spender) public constant returns (uint);
   function transferFrom(address from, address to, uint value) public;
   function approve(address spender, uint value) public;
   event Approval(address indexed owner, address indexed spender, uint value);
 }

 /**
  * title KOL USER DEV ONCHAIN PRECISION ADVERTISING SYSTEM
  * dev visit: https://github.com/jackoelv/KOL/
 */

 contract BasicToken is ERC20Basic {

   using SafeMath for uint;

   mapping(address => uint) balances;

   function transfer(address _to, uint _value) public{
     balances[msg.sender] = balances[msg.sender].sub(_value);
     balances[_to] = balances[_to].add(_value);
     emit Transfer(msg.sender, _to, _value);
   }

   function balanceOf(address _owner) public constant returns (uint balance) {
     return balances[_owner];
   }
 }

 /**
  * title KOL USER DEV ONCHAIN PRECISION ADVERTISING SYSTEM
  * dev visit: https://github.com/jackoelv/KOL/
 */

 contract StandardToken is BasicToken, ERC20 {
   mapping (address => mapping (address => uint)) allowed;
   uint256 public userSupplyed;

   function transferFrom(address _from, address _to, uint _value) public {
     balances[_to] = balances[_to].add(_value);
     balances[_from] = balances[_from].sub(_value);
     allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
     emit Transfer(_from, _to, _value);
   }

   function approve(address _spender, uint _value) public{
     require((_value == 0) || (allowed[msg.sender][_spender] == 0)) ;
     allowed[msg.sender][_spender] = _value;
     emit Approval(msg.sender, _spender, _value);
   }

   function allowance(address _owner, address _spender) public constant returns (uint remaining) {
     return allowed[_owner][_spender];
   }
 }
 contract KOL is StandardToken {
 }

 /**
  * title KOL USER DEV ONCHAIN PRECISION ADVERTISING SYSTEM
  * dev visit: https://github.com/jackoelv/KOL/
 */

 contract Ownable {
     address public owner;

     constructor() public{
         owner = msg.sender;
     }

     modifier onlyOwner {
         require(msg.sender == owner);
         _;
     }
     function transferOwnership(address newOwner) onlyOwner public{
         if (newOwner != address(0)) {
             owner = newOwner;
         }
     }
 }
 /**
  * title KOL USER DEV ONCHAIN PRECISION ADVERTISING SYSTEM
  * dev visit: https://github.com/jackoelv/KOL/
 */
contract KOLADUSER is Ownable{
  using SafeMath for uint256;
  string public name = "KOL USER DEV ONCHAIN PRECISION ADVERTISING SYSTEM";
  KOL public kol;
  address private receiver;

  uint256 public iCode;
  uint256 public totalRegister;
  uint256 public unit = 50 * (10 ** 18);
  uint256 public etherFee = 0.002 ether;
  uint256 public minAmount = 50 * (10 ** 18);

  uint8 public maxlevel = 9;
  uint8 public fee = 5;
  bool public going = true;

  mapping (address => address[]) public InviteList;
  mapping (address => address[]) public ChildAddrs;
  mapping (uint256 => address) public InviteCode;
  mapping (address => uint256) public RInviteCode;

  mapping (address => uint8) public UserLevel;
  mapping (address => uint256) public UserBalance;
  mapping (address => uint256) public UserDrawedBalance;

  mapping (address => uint256) public TotalUsers;
  mapping (address => uint8) public maxDeep;

  event Registed(address indexed _user,uint256 indexed inviteCode);
  event Joined(address indexed _user,uint256 _realUnit,uint8 _userLevel);
  event WithDrawed(address indexed _user,uint256 _amount);
  event GradeChanged(address _user,uint8 _newLevel);

  constructor(address _tokenAddress,address _receiver) public {
    kol = KOL(_tokenAddress);
    receiver = _receiver;
    InviteCode[0] = owner;
    UserLevel[owner] = 9;
  }

  function reg(address _addr,uint256 _fInviteCode) private {
    require(InviteCode[_fInviteCode] != address(0));
    uint256 random = uint256(keccak256(now, _addr)) % 10;
    uint256 _myInviteCode = iCode.add(random);
    require(InviteCode[_myInviteCode] == address(0));
    iCode = iCode.add(random);
    InviteCode[_myInviteCode] = _addr;
    RInviteCode[_addr] = _myInviteCode;

    emit Registed(_addr,iCode);
    totalRegister ++;
    address father = InviteCode[_fInviteCode];
    ChildAddrs[father].push(_addr);
    if (InviteList[_addr].length < 9){
      InviteList[_addr].push(father);
      TotalUsers[father] ++;
      if (maxDeep[father] < 1){
        maxDeep[father] = 1;
        emit GradeChanged(father,1);
      }
    }

    for (uint8 i = 0 ; i < InviteList[father].length; i++){
      if (InviteList[_addr].length < 9){
        InviteList[_addr].push(InviteList[father][i]);
        TotalUsers[InviteList[father][i]] ++;
        if (maxDeep[InviteList[father][i]] < i+2){
          maxDeep[InviteList[father][i]] = i+2;
          emit GradeChanged(InviteList[father][i],i+2);
        }
      }else{
        break;
      }

    }

  }
  function join(address _addr) private {
    require(UserLevel[_addr]<9);
    address tokenR1;
    address tokenR2;
    if (InviteList[_addr].length <= UserLevel[_addr]){
      tokenR1 = receiver;
    }else{
      tokenR1 = InviteList[_addr][UserLevel[_addr]];
    }
    uint256 realUnit;
    if (UserLevel[_addr] == 0){
      realUnit = 2 * unit;
      if (InviteList[_addr].length == 9){
        tokenR2 = InviteList[_addr][8];
      }else{
        tokenR2 = receiver;
      }
    }else{
      realUnit = unit;
    }
    kol.transferFrom(_addr,address(this),realUnit);
    if (realUnit == 2*unit){
      addUnit(_addr, tokenR2);
    }
    addUnit(_addr,tokenR1);
    UserLevel[_addr] += 1;
    emit Joined(_addr,realUnit,UserLevel[_addr]);
  }
  function addUnit(address _self,address _tokenReceiver) private{
    if (UserLevel[_tokenReceiver]>=UserLevel[_self] + 1){
      UserBalance[_tokenReceiver] += unit;
    }else{
      UserBalance[receiver] += unit;
    }
  }
  function go(uint256 _fInviteCode,bool _joinAll) payable public {
    require(going);
    require(msg.value >= etherFee);
    if (RInviteCode[msg.sender] == 0){
      reg(msg.sender,_fInviteCode);
      if (_joinAll){
        joinAll(msg.sender);
        return;
      }
    }
    join(msg.sender);
  }
  function joinAll(address _addr) private{
    require(UserLevel[_addr] == 0);
    kol.transferFrom(_addr,address(this),unit*10);
    uint8 done;
    for (uint8 i=0;i<InviteList[_addr].length;i++){
      addUnit(_addr,InviteList[_addr][i]);
      done++;
    }
    if (InviteList[_addr].length == 9){
      addUnit(_addr,InviteList[_addr][8]);
      done++;
    }
    UserBalance[receiver] += (10 - done) * unit;
    UserLevel[_addr] = 9;
  }

  function drawKol() payable public {
    require(msg.value >= etherFee);
    require(UserBalance[msg.sender] >= minAmount);
    kol.transfer(msg.sender,UserBalance[msg.sender] * (100-fee)/100);
    kol.transfer(receiver,UserBalance[msg.sender] * fee/100);
    UserDrawedBalance[msg.sender]+=UserBalance[msg.sender];
    emit WithDrawed(msg.sender,UserBalance[msg.sender]);
    UserBalance[msg.sender] = 0;
  }
  function setetherFee(uint256 _fee) onlyOwner public{
    etherFee = _fee;
  }

  function setReceiver(address _receiver) onlyOwner public{
    receiver = _receiver;
  }
  function draw() onlyOwner public{
    receiver.send(address(this).balance);
  }

  function setGoing(bool _going) onlyOwner public{
    going = _going;
  }

  function getFathersLength(address _addr) public view returns(uint256){
    return InviteList[_addr].length;
  }

  function getChildsLen(address _addr) public view returns(uint256){
  return(ChildAddrs[_addr].length);
  }

  function setUnit(uint256 _unit) onlyOwner public{
    unit = _unit;
  }
  function setFee(uint8 _fee) onlyOwner public{
    fee = _fee;
  }
  function setMinAmount(uint256 _minAmount) onlyOwner public{
    minAmount = _minAmount;
  }
}