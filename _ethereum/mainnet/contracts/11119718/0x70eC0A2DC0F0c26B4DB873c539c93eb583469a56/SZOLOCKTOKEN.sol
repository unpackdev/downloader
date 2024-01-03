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
    require(_owner != msg.sender);  // can't remove your self
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

contract SZTOKEN {

   	   function totalSupply() public view returns (uint256);
       function balanceOf(address tokenOwner) public view returns (uint256 balance);
       function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);

       function transfer(address to, uint256 tokens) public returns (bool success);
       
       function approve(address spender, uint256 tokens) public returns (bool success);
       function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
       function intTransfer(address _from, address _to, uint256 _value) public  returns(bool);

}


contract DEPOSITQUOTA{
      function getRedeemQuota(address _from) public view returns(uint256);
      function setRedeemQuota(address _from,uint256 _amount) public returns(uint256);
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
        require(_value <= balance[msg.sender],"In sufficial Balance");
        require(_to != address(0),"Can't transfer To Address 0");

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
               require(_value <= balance[_from]);
               require(_value <= allowed[_from][msg.sender]); 
               require(_to != address(0));

              balance[_from] = balance[_from].sub(_value);
              balance[_to] = balance[_to].add(_value);
              allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
              emit Transfer(_from, _to, _value);
              return true;
      }
}

contract SZOLOCKTOKEN is StandarERC20,Ownable{
  string public name = "SZO 270 DAY LOCK";
  string public symbol = "SZO_W2"; 
  uint256 public decimals = 18;
  uint256 public lockTime; // 270 Day since 25th Octoer 2020 6:00 UTC Time;
  
  bool public stopAdd;
  SZTOKEN public szoToken;
  address public sellPools;
  DEPOSITQUOTA public depoPools;
  uint256  public redeemQuota; // for early 9 month
  uint256  public totalRedeem;

  constructor() public {
      szoToken = SZTOKEN(0x6086b52Cab4522b4B0E8aF9C3b2c5b8994C36ba6);
      sellPools = 0x0D80089B5E171eaC7b0CdC7afe6bC353B71832d1;
 
      lockTime = 1603605600 + 270 days;  

  }
  
  function stopAddToken() public onlyOwner returns(bool){
      stopAdd = true;
  }
  
  function setSellPool(address _addr) public onlyOwner returns(bool){
      sellPools = _addr;
      return true;
  }
  
  function setDepositPools(address _addr) public onlyOwner returns(bool){
      depoPools = DEPOSITQUOTA(_addr);
      return true;
  }
  
  function setRedeemQuota(uint256 _quota) public onlyOwner returns(bool){
      require(_quota >= redeemQuota,"Can't reduce quota");
      redeemQuota = _quota;
      return true;
  }
  
  function addSZOToken(address _from,uint256 _amount) public onlyOwners returns(bool){
      require(stopAdd == false,"Token Can't Add");
      if(szoToken.intTransfer(_from,address(this),_amount) == true){
          totalSupply_ += _amount;
          balance[_from] += _amount;
          emit Transfer(address(0),_from,_amount);
      }
      
  }
  
  function redeemToSellPool(address _addr,uint256 _amount) public returns(bool){
      require(_addr != address(this),"Can't redeem in this address");
      require(_amount <= balance[_addr],"Not Enought Token to Refund");
      
      balance[_addr] -= _amount;
      totalSupply_ -= _amount;
      szoToken.transfer(sellPools,_amount);
      
      emit Transfer(_addr,address(0),_amount);
  }
  
  // each 1 USD can reddem 3 Token  7 day minimum deposit
  function redeemFromDepositPool(address _addr,uint256 _amount) public returns(bool){
      require(_addr != address(this),"Can't redeem in this address");
      require(_amount <= balance[_addr],"Not Enought Token to Refund");
      require(depoPools.getRedeemQuota(_addr) >= _amount,"Not have quota to redeem");
      
      depoPools.setRedeemQuota(_addr,_amount);
      
      balance[_addr] -= _amount;
      totalSupply_ -= _amount;
      szoToken.transfer(_addr,_amount);
      
      emit Transfer(_addr,address(0),_amount);
      
  }

  function redeemToSZOQuota(address _addr,uint256 _amount) public returns(bool){
      require(_addr != address(this),"Can't redeem in this address");
      require(_amount <= balance[_addr],"Not Enought Token to Refund");
      require(_amount + totalRedeem <= redeemQuota,"Out of quota to redeem");
      
      balance[_addr] -= _amount;
      totalSupply_ -= _amount;
      totalRedeem += _amount;
      
      szoToken.transfer(_addr,_amount);
      
      emit Transfer(_addr,address(0),_amount);
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