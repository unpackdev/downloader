/**
*
*
*  /$$$$$$            /$$            /$$$$$$  /$$                 /$$          
* /$$__  $$          |__/           /$$__  $$| $$                |__/          
*| $$  \__/  /$$$$$$  /$$ /$$$$$$$ | $$  \__/| $$$$$$$   /$$$$$$  /$$ /$$$$$$$ 
*| $$ /$$$$ |____  $$| $$| $$__  $$| $$      | $$__  $$ |____  $$| $$| $$__  $$
*| $$|_  $$  /$$$$$$$| $$| $$  \ $$| $$      | $$  \ $$  /$$$$$$$| $$| $$  \ $$
*| $$  \ $$ /$$__  $$| $$| $$  | $$| $$    $$| $$  | $$ /$$__  $$| $$| $$  | $$
*|  $$$$$$/|  $$$$$$$| $$| $$  | $$|  $$$$$$/| $$  | $$|  $$$$$$$| $$| $$  | $$
* \______/  \_______/|__/|__/  |__/ \______/ |__/  |__/ \_______/|__/|__/  |__/
*                                                                              
*
* 
* GainChain
* https://GainChain.io
* (only for GainChain.io members)
* 
**/

pragma solidity ^0.5.0;

contract GainChain {
    
    struct User {
        uint id;
        address referrer;
        uint referralsCount;
        address[] referrals;
        uint referralEarnings;
        uint cycleEarnings;
        uint currentLevel;
    }

    uint8 public constant LAST_LEVEL = 4;
    uint public lastUserId = 1;
    address public owner;
    address private initialOwner;
    address public feeAddress;
    uint public constant price = 0.06 ether;
    
    uint8 public chainSelect = 1;
    uint public chainCycles = 0;
    
    address[] private level1Chain;
    uint private level1ChainLastDistributedID = 0;
    
    address[] private level2Chain;
    uint private level2ChainLastDistributedID = 0;
    
    address[] private level3Chain;
    uint private level3ChainLastDistributedID = 0;
    
    address[] private level4Chain;
    uint private level4ChainLastDistributedID = 0;

    mapping(address => User) public users;
    mapping(uint => address) public userIds;
    
    event NewJoinee(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event SentReferralReward(address indexed from, address indexed receiver);
    event UpgradeLevel(address indexed user, uint8 indexed level);
    event SentEthDividends(address indexed from, address indexed receiver, uint indexed receiverIndex, uint8 level);
    
    constructor() public {
        
        owner = msg.sender;
        initialOwner = msg.sender;
        feeAddress = msg.sender;
        address[] memory emptyArray;
        User memory user = User({
            id: 1,
            referrer: address(0),
            referralsCount: 0,
            referrals: emptyArray,
            referralEarnings: 0 ether,
            cycleEarnings: 0 ether,
            currentLevel: 4
        });
        
        users[owner] = user;
        userIds[1] = owner;
        level1Chain.push(owner);
        level2Chain.push(owner);
        level3Chain.push(owner);
        level4Chain.push(owner);
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return joinChain(msg.sender, owner);
        }
        
        joinChain(msg.sender, bytesToAddress(msg.data));
    }
    
    function joinGainChain(address referrerAddress) external payable {
        joinChain(msg.sender, referrerAddress);
    }
    
    function joinChain(address userAddress, address referrerAddress) private {
        require(msg.value == price, "Joining cost 0.06");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        lastUserId++;
        runRewardCycle(userAddress, referrerAddress);
        
        address[] memory emptyArray;
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            referralsCount: 0,
            referrals: emptyArray,
            referralEarnings: 0 ether,
            cycleEarnings: 0 ether,
            currentLevel: 1
        });
        users[userAddress] = user;
        level1Chain.push(userAddress);
        userIds[lastUserId] = userAddress;
        emit NewJoinee(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);

        updateReferrer(userAddress, referrerAddress);
    }
    
    function updateReferrer(address userAddress, address referrerAddress) private {
        users[referrerAddress].referrals.push(userAddress);
        users[referrerAddress].referralsCount++;
        
        if (referrerAddress == initialOwner){
            return;
        }
        if(users[referrerAddress].referralsCount == 2){
            level2Chain.push(referrerAddress);
            users[referrerAddress].currentLevel = 2;
            emit UpgradeLevel(referrerAddress, 2);
        }else if(users[referrerAddress].referralsCount == 16){
            level3Chain.push(referrerAddress);
            users[referrerAddress].currentLevel = 3;
            emit UpgradeLevel(referrerAddress, 3);
        }else if(users[referrerAddress].referralsCount == 64){
            level4Chain.push(referrerAddress);
            users[referrerAddress].currentLevel = 4;
            emit UpgradeLevel(referrerAddress, 4);
        }
        
    }
    
    function runRewardCycle(address userAddress, address referrerAddress) private{
        users[referrerAddress].referralEarnings = users[referrerAddress].referralEarnings + 0.02 ether;
        address(uint160(referrerAddress)).transfer(0.02 ether);
        emit SentReferralReward(userAddress,referrerAddress);

        if(chainSelect <= 2){
            uint j = 1;
            uint i = level1ChainLastDistributedID+1;
            for (i ; ((j <= 6)&&( i <= level1Chain.length )); i++) {
                address receiverAddress = level1Chain[i-1];
                address(uint160(receiverAddress)).transfer(0.005 ether);
                users[receiverAddress].cycleEarnings = users[receiverAddress].cycleEarnings + 0.005 ether;
                emit SentEthDividends(userAddress, receiverAddress, i-1, 1);
                j++;
                level1ChainLastDistributedID = i;
            }
            if(level1ChainLastDistributedID == level1Chain.length) level1ChainLastDistributedID = 0;
            chainSelect++;
        } else if(chainSelect == 3){
            uint j = 1;
            uint i = level2ChainLastDistributedID+1;
            for (i ; ((j <= 6)&&( i <= level2Chain.length )); i++) {
                address receiverAddress = level2Chain[i-1];
                address(uint160(receiverAddress)).transfer(0.005 ether);
                users[receiverAddress].cycleEarnings = users[receiverAddress].cycleEarnings + 0.005 ether;
                emit SentEthDividends(userAddress, receiverAddress, i-1, 2);
                j++;
                level2ChainLastDistributedID = i;
            }
            if(level2ChainLastDistributedID == level2Chain.length) level2ChainLastDistributedID = 0;
            chainSelect++;
        } else if(chainSelect == 4){
            uint j = 1;
            uint i = level3ChainLastDistributedID+1;
            for (i ; ((j <= 6)&&( i <= level3Chain.length )); i++) {
                address receiverAddress = level3Chain[i-1];
                address(uint160(receiverAddress)).transfer(0.005 ether);
                users[receiverAddress].cycleEarnings = users[receiverAddress].cycleEarnings + 0.005 ether;
                emit SentEthDividends(userAddress, receiverAddress, i-1, 3);
                j++;
                level3ChainLastDistributedID = i;
            }
            if(level3ChainLastDistributedID == level3Chain.length) level3ChainLastDistributedID = 0;
            chainSelect++;
        } else if(chainSelect == 5){
            uint j = 1;
            uint i = level4ChainLastDistributedID+1;
            for (i ; ((j <= 6)&&( i <= level4Chain.length )); i++) {
                address receiverAddress = level4Chain[i-1];
                address(uint160(receiverAddress)).transfer(0.005 ether);
                users[receiverAddress].cycleEarnings = users[receiverAddress].cycleEarnings + 0.005 ether;
                emit SentEthDividends(userAddress, receiverAddress, i-1, 4);
                j++;
                level4ChainLastDistributedID = i;
            }
            if(level4ChainLastDistributedID == level4Chain.length) level4ChainLastDistributedID = 0;
            chainSelect = 1;
        }
        chainCycles++;
        address(uint160(feeAddress)).transfer(0.01 ether);
        if(address(this).balance > 0) address(uint160(owner)).transfer(address(this).balance);
    }
    
    modifier _onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }
    
    function transferOwnership(address newOwner) public _onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }
    
    function setFeeaddress(address newFeeAddress) public _onlyOwner {
        require(newFeeAddress != address(0), "New owner is the zero address");
        feeAddress = newFeeAddress;
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function getUserDetails(address user) public view returns (uint id, address referrer, uint referralsCount, address[] memory referrals, uint referralEarnings, uint cycleEarnings, uint currentLevel) {
        return (users[user].id,
                users[user].referrer,
                users[user].referralsCount,
                users[user].referrals,
                users[user].referralEarnings,
                users[user].cycleEarnings,
                users[user].currentLevel);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
}