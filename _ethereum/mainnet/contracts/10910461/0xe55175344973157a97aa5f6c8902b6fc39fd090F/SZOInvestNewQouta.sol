pragma solidity 0.5.17;

contract Ownable {


  string [] ownerName;  
  address newOwner; // temp for confirm;
  mapping (address=>bool) owners;
  mapping (address=>uint256) ownerToProfile;
  address owner;

// all events will be saved as log files
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AddOwner(address newOwner,string name);
  event RemoveOwner(address owner);


   constructor() public {
    owner = msg.sender;
    owners[msg.sender] = true;
    uint256 idx = ownerName.push("SAMRET WAJANASATHIAN");
    ownerToProfile[msg.sender] = idx;

  }


// function to check if the executor is the owner? This to ensure that only the person 
// who has right to execute/call the function has the permission to do so.
  modifier onlyOwner(){
    require(msg.sender == owner,"SZO/ERROR-not-owner");
    _;
  }

// This function has only one Owner. The ownership can be transferrable and only
//  the current Owner will only be  able to execute this function.
//  Onwer can be Contract address
  function transferOwnership(address  _newOwner, string memory newOwnerName) public onlyOwner{
    
    uint256 idx;
    if(ownerToProfile[_newOwner] == 0)
    {
    	idx = ownerName.push(newOwnerName);
    	ownerToProfile[_newOwner] = idx;
    }


    emit OwnershipTransferred(owner,_newOwner);
    newOwner = _newOwner;

  }
  
  // Function to confirm New Owner can execute
  function newOwnerConfirm() public returns(bool){
        if(newOwner == msg.sender)
        {
            owner = newOwner;
            newOwner = address(0);
            return true;
        }
        return false;
  }

// Function to check if the person is listed in a group of Owners and determine
// if the person has the any permissions in this smart contract such as Exec permission.
  
  modifier onlyOwners(){
    require(owners[msg.sender] == true);
    _;
  }

// Function to add Owner into a list. The person who wanted to add a new owner into this list but be an existing
// member of the Owners list. The log will be saved and can be traced / monitor who’s called this function.
  
  function addOwner(address _newOwner,string memory newOwnerName) public onlyOwners{
    require(owners[_newOwner] == false,"SZO/ERROR-already-owner");
    require(newOwner != msg.sender,"SZO/ERROR-same-owner-add");
    if(ownerToProfile[_newOwner] == 0)
    {
    	uint256 idx = ownerName.push(newOwnerName);
    	ownerToProfile[_newOwner] = idx;
    }
    owners[_newOwner] = true;
    emit AddOwner(_newOwner,newOwnerName);
  }

// Function to remove the Owner from the Owners list. The person who wanted to remove any owner from Owners
// List must be an existing member of the Owners List. The owner cannot evict himself from the Owners
// List by his own, this is to ensure that there is at least one Owner of this ShuttleOne Smart Contract.
// This ShuttleOne Smart Contract will become useless if there is no owner at all.

  function removeOwner(address _owner) public onlyOwners{
    require(_owner != msg.sender,"SZO/ERROR-remove-yourself");  // can't remove your self
    owners[_owner] = false;
    emit RemoveOwner(_owner);
  }
// this function is to check of the given address is allowed to call/execute the particular function
// return true if the given address has right to execute the function.
// for transparency purpose, anyone can use this to trace/monitor the behaviors of this ShuttleOne smart contract.

  function isOwner(address _owner) public view returns(bool){
    return owners[_owner];
  }

// Function to check who’s executed the functions of smart contract. This returns the name of 
// Owner and this give transparency of whose actions on this ShuttleOne Smart Contract. 

  function getOwnerName(address ownerAddr) public view returns(string memory){
  	require(ownerToProfile[ownerAddr] > 0,"SZO/ERROR-NOT-OWNER-ADDRESS");
  	return ownerName[ownerToProfile[ownerAddr] - 1];
  }
}


contract SZO {
	   event Transfer(address indexed from, address indexed to, uint256 tokens);
       event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

   	   function totalSupply() public view returns (uint256);
       function balanceOf(address tokenOwner) public view returns (uint256 balance);
       function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);

       function transfer(address to, uint256 tokens) public returns (bool success);
       
       function approve(address spender, uint256 tokens) public returns (bool success);
       function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
  
	   function createKYCData(bytes32 _KycData1, bytes32 _kycData2,address  _wallet) public returns(uint256);
	   
	   function haveKYC(address _addr) public view returns(bool);
	   
}

contract SZOInvestNewQouta is  Ownable {
     SZO szoToken;
     address public firstPool;
     address public invester;
     address public poolReward;
     
     uint256 poolQuota = 1000000 ether;
     uint256 investerQuota  = 8252340 ether;
     uint256 poolRewardQuota = 4547660 ether;
  
    
     
     constructor() public {
         szoToken = SZO(0x6086b52Cab4522b4B0E8aF9C3b2c5b8994C36ba6); // MAINNET

     }
      
     function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
             bytes memory tempEmptyStringTest = bytes(source);
            if (tempEmptyStringTest.length == 0) {
                return 0x0;
             }

            assembly {
                 result := mload(add(source, 32))
            }
     }
      //
     function transferToPools(address _addr) public onlyOwners returns(bool){
           require(firstPool == address(0),"ERROR Already Send to Pools");
           firstPool = _addr;
           szoToken.transfer(firstPool,poolQuota);
           if(szoToken.haveKYC(firstPool) == false)
               szoToken.createKYCData(stringToBytes32("UniswapPool"),stringToBytes32("NONE"),firstPool);
           return true;
     }
     
     function transferToInvester(address _addr) public onlyOwners returns(bool){
         require(invester == address(0),"ERROR Already Send to invester");
         invester = _addr;
         szoToken.transfer(invester,investerQuota);
         if(szoToken.haveKYC(invester) == false)
                szoToken.createKYCData(stringToBytes32("SeedFund"),stringToBytes32("NONE"),invester);
           return true;
     }
     
    function transferToPoolsReward(address _addr) public onlyOwners returns(bool){
           require(poolReward == address(0),"ERROR Already Send to PoolsReward");
           poolReward = _addr;
           szoToken.transfer(poolReward,poolRewardQuota);
           if(szoToken.haveKYC(poolReward) == false)
               szoToken.createKYCData(stringToBytes32("PoolReward"),stringToBytes32("NONE"),poolReward);
           return true;
     }


      function transfer(address _to,uint256 _amount) public onlyOwners returns(bool){
          // Emegency Call just in case have problem
          return szoToken.transfer(_to,_amount);
      }
      
}