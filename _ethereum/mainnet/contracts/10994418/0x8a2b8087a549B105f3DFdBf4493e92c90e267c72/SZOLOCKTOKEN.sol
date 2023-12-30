pragma solidity 0.5.17;

 library SafeMath256 {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if(a==0 || b==0)
        return 0;  
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b>0);
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
   require( b<= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }
  
}


contract Ownable {


  address newOwner;
  mapping (address=>bool) owners;
  address owner;

// all events will be saved as log files
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AddOwner(address newOwner,string name);
  event RemoveOwner(address owner);

   constructor() public {
    owner = msg.sender;
    owners[msg.sender] = true;
  }

  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }


  modifier onlyOwners(){
    require(owners[msg.sender] == true || msg.sender == owner);
    _;
  }


  
  function addOwner(address _newOwner,string memory newOwnerName) public onlyOwners{
    require(owners[_newOwner] == false);
    require(newOwner != msg.sender);
    owners[_newOwner] = true;
    emit AddOwner(_newOwner,newOwnerName);
  }


  function removeOwner(address _owner) public onlyOwners{
    require(_owner != msg.sender,"Can't Remove your self");  
    owners[_owner] = false;
    emit RemoveOwner(_owner);
  }

  function isOwner(address _owner) public view returns(bool){
    return owners[_owner];
  }

}

contract ERC20 {
	   event Transfer(address indexed from, address indexed to, uint256 tokens);
       event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

   	   function totalSupply() public view returns (uint256);
       function balanceOf(address tokenOwner) public view returns (uint256 balance);
       function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);

       function transfer(address to, uint256 tokens) public returns (bool success);
       
       function approve(address spender, uint256 tokens) public returns (bool success);
       function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
  

}

contract StandarERC20 is ERC20{
     using SafeMath256 for uint256; 
     
     mapping (address => uint256) balance;
     mapping (address => mapping (address=>uint256)) allowed;


     uint256  totalSupply_; 
     
      event Transfer(address indexed from,address indexed to,uint256 value);
      event Approval(address indexed owner,address indexed spender,uint256 value);


     function totalSupply() public view returns (uint256){
       return totalSupply_;
     }

     function balanceOf(address _walletAddress) public view returns (uint256){
        return balance[_walletAddress]; 
     }


     function allowance(address _owner, address _spender) public view returns (uint256){
          return allowed[_owner][_spender];
        }

     function transfer(address _to, uint256 _value) public returns (bool){
        require(_value <= balance[msg.sender],"Tranfer Error Insufficient Fund");
        require(_to != address(0),"Destination are Address 0");

        balance[msg.sender] = balance[msg.sender].sub(_value);
        balance[_to] = balance[_to].add(_value);
        emit Transfer(msg.sender,_to,_value);
        
        return true;

     }

     function approve(address _spender, uint256 _value)
            public returns (bool){
            allowed[msg.sender][_spender] = _value;

            emit Approval(msg.sender, _spender, _value);
            return true;
            }

      function transferFrom(address _from, address _to, uint256 _value)
            public returns (bool){
               require(_value <= balance[_from],"Insufficient Fund");
               require(_value <= allowed[_from][msg.sender],"Insufficient Quota"); 
               require(_to != address(0),"Destination are address 0");

              balance[_from] = balance[_from].sub(_value);
              balance[_to] = balance[_to].add(_value);
              allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
              emit Transfer(_from, _to, _value);
              return true;
      }
}

contract SZOLOCKTOKEN is StandarERC20,Ownable{
  string public name = "SZO 2 YEAR LOCK";
  string public symbol = "SZO_W1"; 
  uint256 public decimals = 18;
  uint256 public lockTime; // 2 YEAR since 25th Octoer 2020 6:00 UTC Time;
  uint256 public version = 1;
  ERC20 szoToken;

  constructor() public {
      szoToken = ERC20(0x6086b52Cab4522b4B0E8aF9C3b2c5b8994C36ba6);
      totalSupply_ = 31252340 ether;
      balance[address(this)] = 31252340 ether;
      lockTime = 1603605600 + 730 days;  
      emit Transfer(address(0),address(this),totalSupply_);
  }
  
  function giveToken(address _addr,uint256 _amount) public onlyOwners returns(bool) {
        require(_amount <= balance[address(this)],"In sufficial Balance");
        require(_addr != address(0),"Can't transfer To Address 0");

        balance[address(this)] -= _amount;
        balance[_addr] +=_amount;
        emit Transfer(address(this),_addr,_amount);
        
        return true;
  } 
  
  function redeemToSZO(address _addr,uint256 _amount) public returns(bool){
      require(_addr != address(this),"Can't redeem in this address");
      require(_amount <= balance[_addr],"Not Enought Token to Refund");
      require(now>lockTime,"Still in lock Time");
      
      balance[_addr] -= _amount;
      totalSupply_ -= _amount;
      szoToken.transfer(_addr,_amount);
      
      emit Transfer(_addr,address(0),_amount);
  }

      
}