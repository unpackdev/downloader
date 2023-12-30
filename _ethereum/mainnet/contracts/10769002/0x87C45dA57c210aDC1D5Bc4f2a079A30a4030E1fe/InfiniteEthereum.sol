pragma solidity 0.5.16;

contract InfiniteEthereum {
    address public ownerWallet;

    struct PoolStruct {
        uint currentPool;
        address user;
        uint referrerID;
        uint currentID;
        uint[] referral;
        uint payment_received; 
    }
    
    uint public DOWNLINE_LIMIT = 5;
    bool public lockStatus;
    
    mapping(uint => mapping(uint =>PoolStruct)) public poolusers;
    mapping (uint => mapping(uint => address)) public poolList;
    mapping (uint => uint) public PoolcurrentID;
    mapping (address => mapping(uint => uint)) public totalEarnings;
    mapping (address => mapping(uint => uint[])) public userSequenceID;
    
    mapping (uint => uint) public poolPrice;
    mapping (address => mapping (uint => bool)) public levelStatus;
    
    event JoinFee( address indexed UserAddress, uint UserID, uint Amount, uint Time);
    event BuyPool(uint indexed Pool, address indexed UserAddress, uint UserID, address indexed toaddress, uint RefererID, uint Amount, uint Time);
    event ReInvest(uint indexed Pool, address indexed UserAddress, uint ReInvestID, uint Time); 
    
    constructor() public {
        ownerWallet = msg.sender;
        poolPrice[1] = 0.05 ether;
        poolPrice[2] = 0.1 ether;
        poolPrice[3] = 0.4 ether;
        poolPrice[4] = 1.6 ether;
        poolPrice[5] = 6.4 ether;
        poolPrice[6] = 25.6 ether;
        poolPrice[7] = 102.4 ether;
        poolPrice[8] = 409.6 ether;
        poolPrice[9] = 1638.4 ether;
        poolPrice[10] = 6553.6 ether;
        poolPrice[11] = 26214.4 ether;
        poolPrice[12] = 104857.6 ether;
        
        for(uint i=1; i <= 12; i++) {
            poolusers[i][1].currentPool = i;
            poolusers[i][1].user = ownerWallet;
            poolusers[i][1].referral = new uint[](0); 
            levelStatus[ownerWallet][i] = true;
            poolusers[i][1].payment_received = 0;
            PoolcurrentID[i]++;
            poolusers[i][PoolcurrentID[i]].currentID = PoolcurrentID[i];
            poolList[i][PoolcurrentID[i]] = ownerWallet;
            userSequenceID[ownerWallet][i].push(PoolcurrentID[i]);
        }
    } 
    
    function buyPool(uint _pool, uint _referrerID) public payable returns (bool) {
        require(lockStatus == false, "Contract Locked");
        require(_pool > 0 && _pool <= 12, "Incorrect Pool");
        require(!levelStatus[msg.sender][_pool], "User exist");
        require(msg.value == poolPrice[_pool], "Incorrect value");
        require(_referrerID > 0 && _referrerID <= PoolcurrentID[_pool], "Incorrect referrer Id");
       
        if(poolusers[_pool][_referrerID].referral.length >= DOWNLINE_LIMIT)
            _referrerID = findFreeReferrer( _pool, _referrerID);
        
        for (uint i = _pool - 1; i > 0; i--) 
                require(levelStatus[msg.sender][i], "Buy Pool in sequence");
                
        PoolcurrentID[_pool]++;

        poolusers[_pool][PoolcurrentID[_pool]].currentPool = _pool;
        poolusers[_pool][PoolcurrentID[_pool]].user = msg.sender;
        poolusers[_pool][PoolcurrentID[_pool]].referrerID = _referrerID;
        poolusers[_pool][PoolcurrentID[_pool]].referral = new uint[](0); 
        poolusers[_pool][PoolcurrentID[_pool]].currentID = PoolcurrentID[_pool];

        poolList[_pool][PoolcurrentID[_pool]] = msg.sender;
        userSequenceID[msg.sender][_pool].push(PoolcurrentID[_pool]);
        poolusers[_pool][_referrerID].referral.push(PoolcurrentID[_pool]);
        
        levelStatus[msg.sender][_pool] = true;
        
        address Referrer = poolList[_pool][_referrerID];
        uint UserID = PoolcurrentID[_pool];
        
        if(poolusers[_pool][_referrerID].payment_received < 4) {
            if(_pool == 1){
                uint amount = poolPrice[_pool]/2;
                require(address(uint160(ownerWallet)).send(amount) && address(uint160(Referrer)).send(amount), "Owner wallet and referer transfer failed");
                poolusers[_pool][_referrerID].payment_received += 1;
                totalEarnings[Referrer][_pool] += amount;
                totalEarnings[ownerWallet][_pool] += amount;
                emit BuyPool(_pool, msg.sender, UserID, Referrer, _referrerID, amount, now);    
                emit JoinFee( msg.sender, UserID, amount, now);
            }
            else{
                require(address(uint160(Referrer)).send(poolPrice[_pool]), "Transfer failed");
                poolusers[_pool][_referrerID].payment_received += 1;
                totalEarnings[Referrer][_pool] += poolPrice[_pool];
                emit BuyPool(_pool, msg.sender, UserID, Referrer, _referrerID, poolPrice[_pool], now);    
            }
        }    
        else {
            require(address(uint160(ownerWallet)).send(poolPrice[_pool]), "Transfer Failed");
            
            poolusers[_pool][_referrerID].payment_received += 1;
            totalEarnings[ownerWallet][_pool] += poolPrice[_pool];
            
            PoolcurrentID[_pool]++;
            
            poolList[_pool][PoolcurrentID[_pool]] = Referrer;
            poolusers[_pool][PoolcurrentID[_pool]].currentID = PoolcurrentID[_pool];
            poolusers[_pool][PoolcurrentID[_pool]].user = Referrer;
            poolusers[_pool][PoolcurrentID[_pool]].referrerID = poolusers[_pool][_referrerID].referrerID;
            poolusers[_pool][PoolcurrentID[_pool]].currentPool = poolusers[_pool][_referrerID].currentPool;
            userSequenceID[Referrer][_pool].push(PoolcurrentID[_pool]);
            emit ReInvest(_pool, Referrer, PoolcurrentID[_pool], now); 
            emit BuyPool(_pool, msg.sender, UserID, ownerWallet, 1, poolPrice[_pool], now);
        }
        return true; 
    }
    
    function failSafe(address payable _toUser, uint _amount) public returns (bool) {
        require(msg.sender == ownerWallet, "only Owner Wallet");
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    }
    
    function updatePrice(uint _pool, uint _price) public returns (bool) {
        require(msg.sender == ownerWallet, "only OwnerWallet");

        poolPrice[_pool] = _price;
        return true;
    }
    
    function contractLock(bool _lockStatus) public returns (bool) {
        require(msg.sender == ownerWallet, "Invalid User");

        lockStatus = _lockStatus;
        return true;
    }
    
    function findFreeReferrer(uint _pool, uint _userID) public view returns(uint) {
        if(poolusers[_pool][_userID].referral.length < DOWNLINE_LIMIT) return _userID;

        uint[] memory referrals = new uint[](3125);
        referrals[0] = poolusers[_pool][_userID].referral[0];
        referrals[1] = poolusers[_pool][_userID].referral[1];
        referrals[2] = poolusers[_pool][_userID].referral[2];
        referrals[3] = poolusers[_pool][_userID].referral[3];
        referrals[4] = poolusers[_pool][_userID].referral[4];

        uint freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 3125; i++) {
            if(poolusers[_pool][referrals[i]].referral.length == DOWNLINE_LIMIT) {
                if(i < 625) {
                    referrals[(i+1)*5]   = poolusers[_pool][referrals[i]].referral[0];
                    referrals[(i+1)*5+1] = poolusers[_pool][referrals[i]].referral[1];
                    referrals[(i+1)*5+2] = poolusers[_pool][referrals[i]].referral[2];
                    referrals[(i+1)*5+3] = poolusers[_pool][referrals[i]].referral[3];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, "No Free Referrer");

        return freeReferrer;
    }
    
    function viewUserPoolSeqID(address _user,uint _poolID)public view returns(uint[] memory) {
        return userSequenceID[_user][_poolID];
    }
    
    function viewUserReferral(uint _pool, uint _userID) public view returns(uint[] memory) {
        return poolusers[_pool][_userID].referral;
    }

}