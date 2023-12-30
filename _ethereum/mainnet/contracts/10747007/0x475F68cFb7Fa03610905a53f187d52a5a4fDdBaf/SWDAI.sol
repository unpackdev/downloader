pragma solidity 0.5.17;
//0x82EA2104fA9EdAc604a59CD93148452c2121dA23  V3 version

contract Ownable {

// A list of owners which will be saved as a list here, 
// and the values are the owner’s names. 

  address newOwner; // temp for confirm;
  mapping (address=>bool) owners;
  address owner;

// all events will be saved as log files
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AddOwner(address newOwner,string name);
  event RemoveOwner(address owner);
  /**
   * @dev Ownable constructor , initializes sender’s account and 
   * set as owner according to default value according to contract
   *
   */

   // this function will be executed during initial load and will keep the smart contract creator (msg.sender) as Owner
   // and also saved in Owners. This smart contract creator/owner is 
   // Mr. Samret Wajanasathian CTO of Shuttle One Pte Ltd (https://www.shuttle.one)

   constructor() public {
    owner = msg.sender;
    owners[msg.sender] = true;
  }

// function to check if the executor is the owner? This to ensure that only the person 
// who has right to execute/call the function has the permission to do so.
  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }


// Function to check if the person is listed in a group of Owners and determine
// if the person has the any permissions in this smart contract such as Exec permission.
  
  modifier onlyOwners(){
    require(owners[msg.sender] == true || msg.sender == owner);
    _;
  }

// Function to add Owner into a list. The person who wanted to add a new owner into this list but be an existing
// member of the Owners list. The log will be saved and can be traced / monitor who’s called this function.
  
  function addOwner(address _newOwner,string memory newOwnerName) public onlyOwners{
    require(owners[_newOwner] == false);
    require(newOwner != msg.sender);
    owners[_newOwner] = true;
    emit AddOwner(_newOwner,newOwnerName);
  }

// Function to remove the Owner from the Owners list. The person who wanted to remove any owner from Owners
// List must be an existing member of the Owners List. The owner cannot evict himself from the Owners
// List by his own, this is to ensure that there is at least one Owner of this ShuttleOne Smart Contract.
// This ShuttleOne Smart Contract will become useless if there is no owner at all.

  function removeOwner(address _owner) public onlyOwners{
    require(_owner != msg.sender);  // can't remove your self
    owners[_owner] = false;
    emit RemoveOwner(_owner);
  }
// this function is to check of the given address is allowed to call/execute the particular function
// return true if the given address has right to execute the function.
// for transparency purpose, anyone can use this to trace/monitor the behaviors of this ShuttleOne smart contract.

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

contract SWDAI is Ownable {
    string public name     = "Secure Wrapped DAI";
    string public symbol   = "SWDAI";
    uint8  public decimals = 18;
    string public company  = "ShuttleOne Pte Ltd";
    uint8  public version  = 5;
    address public coldWallet;

    event  Approval(address indexed _tokenOwner, address indexed _spender, uint256 _amount);
    event  Transfer(address indexed _from, address indexed _to, uint256 _amount);
    
    event  Deposit(address indexed _from, uint256 _amount);
    event  Withdraw(address indexed _to, uint256 _amount);

    mapping (address => uint256) public  balance;
    mapping (address => mapping (address => uint256))  public  allowed;

   

    ERC20  public daiToken;
    ERC20  public swdaiOldVersion;
    bool public stopAdmin;
    
     constructor() public {
         daiToken = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F); //Dai Stablecoin (DAI)
         swdaiOldVersion = ERC20(0x82EA2104fA9EdAc604a59CD93148452c2121dA23);
         coldWallet = 0x2a3a39D963f6e8E8Ea42C7e8aEe82e0b5C9cA78D; // for fee only
     }

     function setColdWallet(address _newAddr) public onlyOwners returns(bool){
        coldWallet = _newAddr;
        return true;
     }
     
    function deposit(address _from,uint256 amount) public returns (bool) {
        if(daiToken.transferFrom(_from,address(this),amount) == true){
            balance[_from] += amount;
            
            emit Deposit(_from,amount);
            emit Transfer(address(0),_from,amount);
        }
    }

    function withdraw(uint256 _amount) public {
        require(balance[msg.sender] >= _amount,"SWDAI/ERROR-out-of-balance-withdraw");
        balance[msg.sender] -= _amount;
        daiToken.transfer(msg.sender,_amount);
        emit Withdraw(msg.sender, _amount);
        emit Transfer(msg.sender,address(0),_amount);
    }

    function balanceOf(address _addr) public view returns (uint256){
        return balance[_addr]; 
     }

    function totalSupply() public view returns (uint) {
        return daiToken.balanceOf(address(this));
    }

     function approve(address _spender, uint256 _amount) public returns (bool){
            allowed[msg.sender][_spender] = _amount;
            emit Approval(msg.sender, _spender, _amount);
            return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256){
          return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(balance[msg.sender] >= _amount,"SWDAI/ERROR-out-of-balance-transfer");
        require(_to != address(0),"SWDAI/ERROR-transfer-addr-0");
       

        balance[msg.sender] -= _amount;
        balance[_to] += _amount;
        emit Transfer(msg.sender,_to,_amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool)
    {
        require(balance[_from] >= _amount,"SWDAI/ERROR-transFrom-out-of");
        require(allowed[_from][msg.sender] >= _amount,"SWDAI/ERROR-spender-outouf"); 
       

        balance[_from] -= _amount;
        balance[_to] += _amount;
        allowed[_from][msg.sender] -= _amount;
        emit Transfer(_from, _to, _amount);

        return true;
    }
    
    function intTransfer(address _from, address _to, uint256 _amount) external onlyOwners returns(bool){
           require(balance[_from] >= _amount,"SWDAI/ERROR-intran-outof");
           require(_to != address(0),"SWDAI/ERROR-intran-addr0");
           
           balance[_from] -= _amount; 
           balance[_to] += _amount;
    
           emit Transfer(_from,_to,_amount);
           return true;
    }
    
    function intTransferWithFee(address _from, address _to, uint256 _value,uint256 _fee) external onlyOwners returns(bool){
   
            require(balance[_from] >= _value);
            require(_to != address(0));
            require(_value > _fee);    
            require(coldWallet != address(0));
        
            balance[_from] -= _value; 
            balance[_to] += _value - _fee;
            balance[coldWallet] += _fee;
    
            emit Transfer(_from,_to,_value);
            emit Transfer(_to,msg.sender,_fee);
    
            return true;
    }
    
    //============== FOR Move Balance from old Version ============
    
    
    function setStopAdmin() public onlyOwners{
        stopAdmin = true;
    }
    
    function mintToken(address _to,uint256 _amount) public onlyOwners{
        require(stopAdmin == false,"This function disable");
        balance[_to] += _amount;
        emit Transfer(address(0),_to,_amount);
    }
    
    function burnToken(address _from,uint256 _amount) public onlyOwners{
        require(stopAdmin == false,"This function disable");
        require(balance[_from] >= _amount,"SWDAI/ERROR-burn-outof");
        balance[_from] -= _amount;
        emit Transfer(_from,address(0),_amount);
    }
    
    function moveBalanceFromOldVersion(address _from) public onlyOwners returns(bool){
        require(stopAdmin == false,"This function disable");
        uint256 _amount = swdaiOldVersion.balanceOf(_from);
        
        balance[_from] += _amount;
        
        emit Transfer(address(0),_from,_amount);
        
        return true;
    }
    

    
}