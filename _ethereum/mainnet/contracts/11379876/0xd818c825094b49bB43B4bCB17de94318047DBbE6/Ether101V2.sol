pragma solidity 0.5.14;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}


contract Ether101V2 {
    using SafeMath for uint256;

    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint currentLevel;
        uint totalEarningEth;
        address[] referral;
        mapping(uint => bool) levelActive;
    }
    
    address public ownerAddress;
    address public marketingAddress;
    uint public marketingFee = 40 ether;
    uint public currentId = 0;
    bool public lockStatus;
    
    mapping (uint => uint) public LEVEL_PRICE;
    mapping (uint => uint) public uplinePercentage;
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (address => mapping (uint => uint)) public EarnedEth;
    mapping (address => uint) public loopCheck;
    mapping (address => uint) public createdDate;
    
    event regLevelEvent(address indexed UserAddress, address indexed ReferrerAddress, uint Time);
    event buyLevelEvent(address indexed UserAddress, uint Levelno, uint Time);
    event getMoneyForLevelEvent(address indexed UserAddress, uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);
    event lostMoneyForLevelEvent(address indexed UserAddress, uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);    
    
    constructor(address _marketing) public {
        ownerAddress = msg.sender;
        marketingAddress = _marketing;
       
        // Level_Price
        LEVEL_PRICE[1] = 0.1 ether;
        LEVEL_PRICE[2] = 0.3 ether;
        LEVEL_PRICE[3] = 1 ether;
        LEVEL_PRICE[4] = 3 ether;
        LEVEL_PRICE[5] = 10 ether;
        LEVEL_PRICE[6] = 30 ether;
        LEVEL_PRICE[7] = 100 ether;
        LEVEL_PRICE[8] = 300 ether;
        LEVEL_PRICE[9] = 1000 ether;
        LEVEL_PRICE[10] = 3000 ether;
       
        
        uplinePercentage[1] = 50 ether;
        uplinePercentage[2] = 10 ether;
        
        UserStruct memory userStruct;
        currentId = currentId.add(1);
    
        userStruct = UserStruct({
            isExist: true,
            id: currentId,
            referrerID: 0,
            currentLevel:1,
            totalEarningEth:0,
            referral: new address[](0)
        });
        users[ownerAddress] = userStruct;
        userList[currentId] = ownerAddress;
        users[ownerAddress].currentLevel = 10;
    
        for(uint i = 1; i <= 10; i++) {
            users[ownerAddress].levelActive[i] = true;
        }
    } 
    
    /**
     * @dev User registration
     */ 
    function regUser(uint _referrerID) external payable {
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist == false, "User exist");
        require(_referrerID > 0 && _referrerID <= currentId, "Incorrect referrer Id");
        require(msg.value == LEVEL_PRICE[1], "Incorrect Value");
        
        
        // check 
        address UserAddress=msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(UserAddress)
        }
        require(size == 0, "cannot be a contract"); 
    
        UserStruct memory userStruct;
        currentId = currentId.add(1);
        
        userStruct = UserStruct({
            isExist: true,
            id: currentId,
            referrerID: _referrerID,
            currentLevel: 1,
            totalEarningEth:0,
            referral: new address[](0)
        });
    
        users[msg.sender] = userStruct;
        userList[currentId] = msg.sender;
        users[msg.sender].levelActive[1] = true;
        users[userList[_referrerID]].referral.push(msg.sender);
        
        loopCheck[msg.sender] = 0;
        createdDate[msg.sender] = now;
        payForLevel(1, msg.sender, ((LEVEL_PRICE[1].mul(marketingFee)).div(10**20)));
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }
    
    /**
     * @dev To buy the next level by User
     */ 
    function buyLevel(uint _level) external payable {
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist, "User not exist"); 
        require(_level > 0 && _level <= 10, "Incorrect level");
        require(msg.value == LEVEL_PRICE[_level], "Incorrect Value");
        require(users[msg.sender].levelActive[_level] == false,"Already active");
    
        if (_level != 1) {
            for (uint i = _level - 1; i > 0; i--) 
                require(users[msg.sender].levelActive[i] == true, "Buy the previous level");
        } 
           
      
        users[msg.sender].levelActive[_level] = true;
        users[msg.sender].currentLevel = _level;
    
        loopCheck[msg.sender] = 0;
        payForLevel(_level, msg.sender, ((LEVEL_PRICE[_level].mul(marketingFee)).div(10**20)));
        emit buyLevelEvent(msg.sender, _level, now);
    }
    
    /**
     * @dev Internal function for payment
     */ 
    function payForLevel(uint _level, address _userAddress, uint _marketingFee) internal {
        address referer;
        
        referer = userList[users[_userAddress].referrerID];
        
        if (loopCheck[msg.sender] == 0) {
            require((address(uint160(marketingAddress)).send(_marketingFee)), "Transaction Failure 1");
            loopCheck[msg.sender] = loopCheck[msg.sender].add(1);
            EarnedEth[marketingAddress][_level] =  EarnedEth[ownerAddress][_level].add(_marketingFee);
            users[marketingAddress].totalEarningEth  = users[ownerAddress].totalEarningEth.add(_marketingFee);
            emit getMoneyForLevelEvent(msg.sender, users[msg.sender].id, marketingAddress, users[marketingAddress].id, _level, _marketingFee, now);
        }
        
        if (!users[referer].isExist) 
            referer = userList[1];
        
        if (loopCheck[msg.sender] > 2) 
            referer = userList[1];
        
        
        if (users[referer].levelActive[_level] == true) {
            
            if (loopCheck[msg.sender] <= 2) {
                uint uplinePrice;
                
                if(referer == ownerAddress) {
                    
                    for(uint i=loopCheck[msg.sender];i<=2;i++) {
                        uint _uplineShare = (LEVEL_PRICE[_level].mul(uplinePercentage[i])).div(100 ether);
                        uplinePrice = uplinePrice.add(_uplineShare);
                    }
                    
                    require(address(uint160(referer)).send(uplinePrice), "Transaction Failure");
                    users[referer].totalEarningEth = users[referer].totalEarningEth.add(uplinePrice);
                    EarnedEth[referer][_level] = EarnedEth[referer][_level].add(uplinePrice);
                    loopCheck[msg.sender] = 2;
                    emit getMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer, users[referer].id, _level, uplinePrice, now);
                }
                
                else {
                    uplinePrice = (LEVEL_PRICE[_level].mul(uplinePercentage[loopCheck[msg.sender]])).div(100 ether);
                    require(address(uint160(referer)).send(uplinePrice), "Transaction Failure");
                    users[referer].totalEarningEth = users[referer].totalEarningEth.add(uplinePrice);
                    EarnedEth[referer][_level] = EarnedEth[referer][_level].add(uplinePrice);
                    loopCheck[msg.sender] = loopCheck[msg.sender].add(1);
                    emit getMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer, users[referer].id, _level, uplinePrice, now);
                    payForLevel(_level, referer, _marketingFee);
                }
            }
        } else {
            if (loopCheck[msg.sender] <= 2) {
                uint uplinePrice = (LEVEL_PRICE[_level].mul(uplinePercentage[loopCheck[msg.sender]])).div(100 ether);
                emit lostMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer, users[referer].id, _level, uplinePrice,now);
                payForLevel(_level, referer, _marketingFee);
            }
        }
    }
    
    /**
     * @dev Contract balance 
     */ 
    function failSafe(address payable _toUser, uint _amount) public returns (bool) {
        require(msg.sender == ownerAddress, "only Owner Wallet");
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
    
        (_toUser).transfer(_amount);
        return true;
    }
            
    /**
     * @dev Update marketing fee percentage
     */ 
    function updateFeePercentage(uint256 _marketingFee) public returns (bool) {
        require(msg.sender == ownerAddress, "only OwnerWallet");
    
        marketingFee = _marketingFee;
        return true;  
    }
    
    /**
     * @dev Update marketing Address
     */ 
    function updateMarketingAddress(address _marketing) public returns (bool) {
        require(msg.sender == ownerAddress, "only OwnerWallet");
    
        marketingAddress = _marketing;
        return true;  
    }
    
    /**
     * @dev Update level price
     */ 
    function updatePrice(uint _level, uint _price) public returns (bool) {
        require(msg.sender == ownerAddress, "only OwnerWallet");
    
        LEVEL_PRICE[_level] = _price;
        return true;
    }
    
    /**
     * @dev Update contract status
     */ 
    function contractLock(bool _lockStatus) public returns (bool) {
        require(msg.sender == ownerAddress, "Invalid User");
    
        lockStatus = _lockStatus;
        return true;
    }
    
    /**
     * @dev Total earned ETH
     */
    function getTotalEarnedEther() public view returns (uint) {
        uint totalEth;
        for (uint i = 1; i <= currentId; i++) {
            totalEth = totalEth.add(users[userList[i]].totalEarningEth);
        }
        return totalEth;
    }
        
    /**
     * @dev View referrals
     */ 
    function viewUserReferral(address _userAddress) external view returns (address[] memory) {
        return users[_userAddress].referral;
    }
    
    /**
     * @dev View level expired time
     */ 
    function viewUserLevelExpired(address _userAddress,uint _level) external view returns (bool) {
        return users[_userAddress].levelActive[_level];
    }
    
    // fallback
    function () external payable {
        revert("Invalid Transaction");
    }
}