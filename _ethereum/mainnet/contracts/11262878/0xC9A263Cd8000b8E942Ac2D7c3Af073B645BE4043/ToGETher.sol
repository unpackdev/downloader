pragma solidity >=0.4.0 <0.6.0;


 contract ToGETher {
        
        struct User  {
            address userAddress;
            address referrerAddress;
            address UpLinePartner;
            uint partnersCount;
            uint id;
     }
         
        struct partner {
            address userAddress;
            address referrerAddress;
            address UpLinePartner;
         }
         
         
        address public ownerWallet;  
        uint private cost = 0.08 ether;
        partner[] private partners;
         
         
         
    constructor() public {
        ownerWallet = msg.sender; 
        User memory user = User({
            id: 1,                    
            userAddress: address (ownerWallet), 
            UpLinePartner: address(ownerWallet),
            referrerAddress: address(ownerWallet),
            partnersCount: uint(0)
        });
            users[ownerWallet] = user;
            idToAddress[1] = ownerWallet;
            lastUserId = lastUserId;
        }
    

    modifier onlyOwner() {
        require(msg.sender == ownerWallet, "Only Owner");
        _;
     
     }
     
    function changeCostInWei(uint NewCost)public onlyOwner returns (bool){
        cost = NewCost;
        return true;
    }
    
    
    function setUser(address userAddress) public onlyOwner returns (bool){
        require(!isUserExists(userAddress), "User already exists");
        
        address referrerAddress = ownerWallet;
        address UpLinePartner = ownerWallet;
        
        User memory user = User({
            id: lastUserId,
            userAddress: address (userAddress),
            referrerAddress: address (referrerAddress),
            UpLinePartner: address(UpLinePartner),
            partnersCount: uint(0)
            
 });
            users[userAddress] = user;
            idToAddress[lastUserId] = userAddress;
            lastUserId = lastUserId + 1;
        
            users[referrerAddress].partnersCount++;
        
    }
    
    function viewCost()public view  returns (uint){
        return uint (cost);
       
      
     }
     
    function viewContractbalance() public view returns (uint256) {
        return address(this).balance;
     }
    
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, ownerWallet);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable {
         
        registration(msg.sender,  referrerAddress);
    }
    
    
    
    function registration ( address userAddress, address referrerAddress) private { 
         
        address UpLinePartner;
        userAddress = msg.sender;
         
        users[userAddress].referrerAddress = referrerAddress;
        UpLinePartner = users[referrerAddress].referrerAddress;
         
        require(!isUserExists(userAddress), "User already exists");
        require(msg.sender == userAddress, "You cannot register using someone else's ETH address");
        require(referrerAddress != msg.sender, "You cannot invite yourself");
        require(isUserExists(referrerAddress), "Referrer not found");
        require(msg.value == cost, "The amount of the contribution is indicated in the menu - Cost. The amount is indicated in Wei.");
          partners.push(partner(userAddress, referrerAddress, UpLinePartner));    
          

        uint32 size;
           assembly {
           size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
       
       
     
        User memory user = User({
            id: lastUserId,
            userAddress: msg.sender,
            referrerAddress: address (referrerAddress),
            UpLinePartner: address(UpLinePartner),
            partnersCount: uint(0)
            
 });
            users[userAddress] = user;
            idToAddress[lastUserId] = userAddress;
            lastUserId = lastUserId + 1;
        
            users[referrerAddress].partnersCount++;
        
        address receiver;
        address secondReceiverAddress;
        uint partnersCount;
        uint x = partnersCount % 4 ;
         (x == 0);
         
         // Reinvest
        if ( users[referrerAddress].partnersCount % 4 ==0 ) {
        receiver = ownerWallet;
        secondReceiverAddress = UpLinePartner;
        
        if (!address(uint160(receiver)).send(msg.value/2) ) {
            return address(uint160(receiver)).transfer(address(this).balance/2); 
               }
        if (!address(uint160(secondReceiverAddress)).send(msg.value)) {
            return address(uint160(secondReceiverAddress)).transfer(address(this).balance); 
                }
                
        // The logic of the distribution of funds in normal conditions        
        } else {    
        
        receiver = referrerAddress;
        secondReceiverAddress = UpLinePartner;
           
        if (!address(uint160(receiver)).send(msg.value/2) ) {
            return address(uint160(receiver)).transfer(address(this).balance/2); 
               }
        if (!address(uint160(secondReceiverAddress)).send(msg.value)) {
            return address(uint160(secondReceiverAddress)).transfer(address(this).balance); 
        
           }
    }
     emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
        
 }
 
 
        
    function isUserExists(address userAddress) public view returns (bool) {
            return (users[userAddress].id != 0);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
   }

    
         
    mapping(address => User) public users;
    mapping(uint => address) private userIds;
    mapping(uint => address) private idToAddress;
    mapping(address => uint) private balances; 
    
    uint public lastUserId = 2;
     
     // EVENTS
     
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
     
     
     
 }