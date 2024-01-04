pragma solidity 0.5.17;

library SafeMath256 {

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

// A list of owners which will be saved as a list here, 
// and the values are the owner’s names. 


  string [] ownerName;  
  address newOwner; // temp for confirm;
  mapping (address=>bool) owners;
  mapping (address=>uint256) ownerToProfile;
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
    uint256 idx = ownerName.push("SAMRET WAJANASATHIAN");
    ownerToProfile[msg.sender] = idx;

  }

// // function to check whether the given address is either Wallet address or Contract Address

//   function isContract(address _addr) internal view returns(bool){
//      uint256 length;
//      assembly{
//       length := extcodesize(_addr)
//      }
//      if(length > 0){
//       return true;
//     }
//     else {
//       return false;
//     }

//   }

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



// Mandatory basic functions according to ERC20 standard
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
        require(_value <= balance[msg.sender],"SZO/ERROR-insufficient-balance");
        require(_to != address(0),"SZO/ERROR-address-0");

        balance[msg.sender] = balance[msg.sender].sub(_value);
        balance[_to] = balance[_to].add(_value);
        emit Transfer(msg.sender,_to,_value);
        
        return true;

     }

     function approve(address _spender, uint256 _value)
            public returns (bool){
            require (( _value == 0) || ( allowed[msg.sender ] [_spender] == 0),"SZO/ERROR-Approve");    
            allowed[msg.sender][_spender] = _value;

            emit Approval(msg.sender, _spender, _value);
            return true;
            }

      function transferFrom(address _from, address _to, uint256 _value)
            public returns (bool){
               require(_value <= balance[_from],"SZO/ERROR-insufficient-balance");
               require(_value <= allowed[_from][msg.sender],"SZO/ERROR-insufficient-allowed"); 
               require(_to != address(0),"SZO/ERROR-sendto-address0");

              balance[_from] = balance[_from].sub(_value);
              balance[_to] = balance[_to].add(_value);
              allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
              emit Transfer(_from, _to, _value);
              return true;
      }

}

contract ShuttleOneToken is StandarERC20, Ownable {
  using SafeMath256 for uint256;
  string public name = "ShuttleOne Token";
  string public symbol = "SZO"; 
  uint256 public decimals = 18;
  uint256 public version = 10;
  uint256 public token_price = 500000000000000; // 0.0005 ETH
  uint256 public tokenRedeem = 400000000000000; // 0.0004 ETH
  uint256 public totalSell = 0;
  bool public stopMint = false;
  
  uint256 public _1Token = 1 ether;
  uint256 public HARD_CAP = 230000000 ether;
  uint256 public NEW_HARD_CAP = 230000000 ether; // start new hard cap and hard cap are same value
  uint256 public MINT_PER_YEAR = 11500000 ether; // 11.5 M (5%) Mint per year
  uint256 public mintCount = MINT_PER_YEAR;
  uint256 public MAX_TOKEN_SELL;
  
  uint256 public startTime;
  uint256 public nextMintTime;
  uint256 public nextBuyTime;
  
  // KYC encode Data
  	struct KYCData{
		bytes32    KYCData01;
		bytes32    KYCData02;
	}

	KYCData[] internal kycDatas;
	mapping (address=>uint256) OwnerToKycData; // mapping index with address
   
   mapping (address => bool) public haveKYC;
   mapping (address => bool) public disInterTran; // Allow for internal transfer default = Yes 
   mapping (address => bool) public agents;
   
   mapping(address => bool) public whitelist;
   mapping(address => bool) public blacklist;
  
   
  
  address lockContract  = 0x697FD3721B20D7E2e7B99cE2540bB0df2E470c5a; 
  
  uint256 public tokenLock = 96800000 ether; // 96.8M Token (GENESIS USERS = 37M,DEV = 23M,FOUNDER = 23M,EQUITY SEED A INVESTORS = 13.8M)

  constructor() public {
        
    balance[lockContract] = tokenLock;
    haveKYC[lockContract] = true;
    addOwner(lockContract,"lockContract");
    
    MAX_TOKEN_SELL = HARD_CAP - tokenLock;
    totalSupply_ += tokenLock;
    emit Transfer(address(0),lockContract,tokenLock);
    startTime = now;
    nextMintTime = startTime + 365 days;
    nextBuyTime = startTime;
  }
  
 
  uint256 tokenProfit;
  
  function stopMintToken() public onlyOwners returns(bool){
      stopMint = true;
      return true;
  }
  
  function buyToken() payable public returns(bool){
      require(stopMint == false,"SZO/ERROR-stopmint");
      require(msg.value >= token_price,"SZO/ERROR-buy-lower");
      require(now - nextBuyTime > 60 seconds,"SZO/ERROR-wait-buy-time");
      
      uint256 amount = msg.value / token_price;
      require (amount > 0 ," Insufficient eth" ) ;
      
      amount  = amount * _1Token;
      require(totalSell + amount <= MAX_TOKEN_SELL,"SZO/ERROR-insufficient-tosell");

      tokenProfit += (token_price - tokenRedeem) * amount;
      totalSell += amount;
      totalSupply_ += amount;
      nextBuyTime = now;
      balance[msg.sender] += amount;
      emit Transfer(address(0),msg.sender,amount);
      return true;
  }
  
  function setWhiteList(address _addr,bool _whiteList) public onlyOwners returns(bool){
      whitelist[_addr] = _whiteList;
      return true;
  }
  
  function setBlackList(address _addr,bool _blackList) public onlyOwners returns(bool){
      blacklist[_addr] = _blackList;
      return true;
  }
  
  
  // Token can mint only 11.5 M token per year after reach 230M token mint
    modifier canMintToken(){
    require(whitelist[msg.sender] == true,"SZO/ERROR-not-whitelist");
    require(mintCount < MINT_PER_YEAR,"SZO/ERROR-insufficient-mint-year");
    _;
    }
  
    function resetMintCount() public onlyOwners returns(bool) {
         if(now > nextMintTime && MINT_PER_YEAR == mintCount && totalSell == MAX_TOKEN_SELL){
              nextMintTime = nextMintTime + 365;
              mintCount = 0;
             return true;
         }
         
         return false;
      }
      
      
       
      
   function mintToken() public payable canMintToken returns(bool){
      require(stopMint == false,"SZO/ERROR-stopmint02");
      require(haveKYC[msg.sender] == true,"SZO/ERROR-not_kyc-mint");
      require(msg.value >= token_price,"SZO/ERROR-buy-lower2");
       
      uint256 amount = msg.value / token_price;
      tokenProfit += (token_price - tokenRedeem) * amount;
      amount  = amount * _1Token;
      
      require(mintCount + amount <= MINT_PER_YEAR,"SZO/ERROR-insufficient-mint-year2");
      totalSupply_ += amount;
      mintCount += amount;
      balance[msg.sender] += amount;
      emit Transfer(address(0),msg.sender,amount);
      return true;
     }
  
 

// Add information KYC for standard ERC20 transfer to block only KYC user  
  function transfer(address _to, uint256 _value) public returns (bool){
      require(haveKYC[msg.sender] == true,"SZO/ERROR-transfer-not-kyc");
      require(blacklist[msg.sender] == false,"SZO/ERROR-transfer-blacklist");
      require(blacklist[_to] == false,"SZO/ERROR-transfer-to-blacklist");
      
      //require(haveKYC[_to] == true);  // remove recieve no KYC

       super.transfer(_to, _value);
  }
  
  //Add on KYC check to StandarERC20 transferFrom function
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool){

        require(haveKYC[_from] == true,"SZO/ERROR-transferfrom-not-kyc");
        require(blacklist[msg.sender] == false,"SZO/ERROR-transferfrom-sender-blacklist");
        require(blacklist[_to] == false,"SZO/ERROR-transferfrom-to-blacklist");
        require(blacklist[_from] == false,"SZO/ERROR-transferfrom-from-blacklist");

//      require(haveKYC[_to] == true); // remove recieve no KYC
        super.transferFrom(_from, _to, _value);
   }
    // Set address can allow internal transfer or not. Default are on. Owner of address should disable by them self
  function setNotAllowInterTransfer(bool _allow) public returns(bool){
      disInterTran[msg.sender] = _allow;
      return true;
  }
  

  
  // This function use only for internal wallet that create by XSE Wallet only
  // sender and reciever  will need to KYC
   function intTransfer(address _from, address _to, uint256 _value) external onlyOwners returns(bool){
   
    require(disInterTran[_from] == false,"SZO/ERROR-disable-tran");
    require(balance[_from] >= _value,"SZO/ERROR-insufficient-balance-intran");
    require(haveKYC[_from] == true,"SZO/ERROR-from-no-kyc");
    require(blacklist[_from] == false,"SZO/ERROR-intran-from-blacklist");
    require(blacklist[_to] == false,"SZO/ERROR-intran-to-blacklist");
    
  //  require(haveKYC[_to] == true);
        
    balance[_from] -= _value; 
    balance[_to] += _value;
    
    emit Transfer(_from,_to,_value);
    return true;
  }
  
   	// Add KYC Data to blockchain with encode It will have Name Surname National and ID/Passport No.
   	// Only permission of ShuttleOne can put this data 
	function createKYCData(bytes32 _KycData1, bytes32 _kycData2,address  _wallet) onlyOwners public returns(uint256){
		require(haveKYC[_wallet] == false,"SZO/ERROR-already-kyc"); // can't re KYC  if already KYC
		
		uint256 id = kycDatas.push(KYCData(_KycData1, _kycData2));
		OwnerToKycData[_wallet] = id;
        haveKYC[_wallet] = true;

		return id;
	}
  
    //Get Encoding KYC Data 
    function getKYCData(address _wallet) public view returns(bytes32 _data1,bytes32 _data2){
        require(haveKYC[_wallet] == true,"SZO/ERROR-no-kyc");
        uint256 index = OwnerToKycData[_wallet]-1;
        
        _data1 = kycDatas[index].KYCData01;
        _data2 = kycDatas[index].KYCData02;
    }
    
  
//   //Change token sell price. 
    function setTokenPrice(uint256 pricePerToken) public onlyOwners returns(bool){
      require(pricePerToken > tokenRedeem,"SZO/ERROR-set-lower-price");
      
      token_price = pricePerToken;
      return true;
    } 
  
    function addAgent(address _agent) public onlyOwners returns(bool){
        require(agents[_agent] == false,"SZO/ERROR-already-agent");
        require(haveKYC[_agent] == true,"SZO/ERROR-agent-no-kyc");
        require(_agent != msg.sender,"SZO/ERROR-add-yourself");
        
        agents[_agent] = true;
        
        return true;
    }

  //Redeem token that use for fee. after reedeem token will burn 
  function redeemFee(uint256 amount) public onlyOwners returns(bool){
      uint256  _fund;
      require(agents[msg.sender] == true,"SZO/ERROR-not-agent");
      
      _fund = (amount / _1Token) * tokenRedeem; 
      require(balance[msg.sender] >= amount,"SZO/ERROR-insufficient-balance-agent");
      require(address(this).balance >= _fund,"SZO/ERROR-insufficient-balance-szo");
      
      balance[msg.sender] -= amount;
      totalSupply_ -= amount; // burn token
      emit Transfer(msg.sender,address(0),amount);
      
      msg.sender.transfer(_fund);
      
      return true;
  }
  
  function burn(uint256 amount) public onlyOwners returns(bool){
      require(balance[msg.sender] >= amount,"SZO/ERROR-insufficient-balance-burn");
      
      balance[msg.sender] -= amount;
      totalSupply_ -= amount; // burn token
      emit Transfer(msg.sender,address(0),amount);
      
      return true;
  }
  
  function getProfit() public view onlyOwners returns(uint256){
      return tokenProfit;
  }
  
  address payable profitAddr1 = address(0);
  address payable profitAddr2 = address(0);
  
  function setProfitAddr(uint256 addrIdx) public onlyOwners{
      require(addrIdx == 1 || addrIdx == 2,"Invalid addrIdx");
     if(addrIdx == 1){
          require(msg.sender != profitAddr2,"SZO/ERROR-profit-error1");
          profitAddr1 = msg.sender;
     }
     if(addrIdx == 2){
          require(msg.sender != profitAddr1,"SZO/ERROR-profit-error2");
          profitAddr2 = msg.sender;
     }
  }
  
  function withDrawFunc(uint256 _fund) public onlyOwners{
		require(address(this).balance >= _fund,"SZO/ERROR-insufficient-balance-withdraw");
		require(_fund & 1 == 0,"SZO/ERROR-only-evennumber"); // only even number
		require(tokenProfit >= _fund,"SZO/ERROR-insufficient-balance-profit");
		require(profitAddr1 != address(0),"SZO/ERROR-notset-address1");
		require(profitAddr2 != address(0),"SZO/ERROR-notset-address2");
		
        profitAddr1.transfer(_fund / 2);
        profitAddr2.transfer(_fund / 2);
        
		tokenProfit -= _fund;
  }
  
  
  
}