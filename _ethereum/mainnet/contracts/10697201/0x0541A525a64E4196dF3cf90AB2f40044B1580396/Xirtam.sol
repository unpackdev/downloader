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
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Xirtam {
    
    struct UserStruct {
        bool isExist;
        uint id;
        address referrer;
        uint partnersCount;
        mapping(uint => X3Struct) X3Matrix;
        mapping(uint => X14Struct) X14Matrix;
        mapping(uint => uint) currentLevel;
    }

    struct X3Struct {
        uint currentReferrer;
        address[] referral;
        bool levelExpired;
        uint reInvestCount;
        bool blocked;
    }
    
    struct X14Struct {
        uint currentReferrer;
        address[] firstLineRef;
        address[] secondLineRef;
        address[] thirdLineRef;
        bool levelStatus;
        uint reInvestCount;
    }
    
    using SafeMath for uint256;
    address public ownerAddress;
    uint public currentId = 0;
    uint refLimit = 2;
    uint constant LAST_LEVEL =12;
    bool public lockStatus;
    address public partnerContract;
    address public dividendAddress;
    uint public dividendCount;
    
    mapping (uint => uint) public levelPrice;
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (address => mapping (uint => mapping (uint => uint))) public EarnedEth;
    mapping (address => mapping (uint => uint)) public totalEarnedEth;
    mapping (address => bool) public dividendStatus;
    
    event regLevelEvent(uint indexed Matrix,address indexed UserAddress, address indexed ReferrerAddress, uint Time);
    event buyLevelEvent(uint indexed Matrix, address indexed UserAddress, uint Levelno, uint Time);
    event reInvestEvent(uint indexed Matrix, address indexed UserAddress, address indexed ReferrerAddress, address  CallerAddress,uint Levelno, uint Count, uint Time);
    event getMoneyForLevelEvent(uint indexed Matrix,address indexed UserAddress,uint UserId,address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);
    event lostMoneyForLevelEvent(uint indexed Matrix,address indexed UserAddress,uint UserId,address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);
    event Dividend(address UserAddress, uint Amount);
    event lostReferrer(address indexed UserAddress, uint Matrix);
    
    constructor(address _partner, address _dividentAddress) public {
        ownerAddress = msg.sender;
        partnerContract = _partner;
        dividendAddress = _dividentAddress;
        
        levelPrice[1] = 0.02 ether;
        
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        
        currentId = currentId.add(1);
        
        UserStruct memory user = UserStruct({
            isExist: true,
            id: currentId,
            referrer: address (0),
            partnersCount: 0
        });
        
        users[ownerAddress] = user;
        userList[currentId] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].X3Matrix[i].levelExpired = true;
            users[ownerAddress].X14Matrix[i].levelStatus = true;
            users[ownerAddress].currentLevel[1] = i;
            users[ownerAddress].currentLevel[2] = i;
        }
        
    }
    
    function () external payable {
        revert("Invalid Transaction");
    }
    
    function registration(uint _referrerID) external payable {
        require(users[userList[_referrerID]].isExist == true,"Referrer not Exist");
        require(users[msg.sender].isExist == false,"User  Exist");
        require(_referrerID>0 && _referrerID <= currentId,"Incorrect Id");
        require(msg.value == levelPrice[1].mul(2),"Incorrect Value");
        
        UserStruct memory user;
        currentId = currentId.add(1);
        
        user = UserStruct ({
            isExist: true,
            id: currentId,
            referrer: userList[_referrerID],
            partnersCount: 0
        });
        
        users[msg.sender]= user;
        userList[currentId] = msg.sender;
        users[userList[_referrerID]].partnersCount = users[userList[_referrerID]].partnersCount.add(1);
        
        X3Registration();
        X14Registration();
    }
    
    function X3BuyLevel(uint256 _level) external payable {
        require(lockStatus == false,"Contract Locked");
        require(users[msg.sender].isExist,"User not exist"); 
        require(users[msg.sender].X3Matrix[_level].levelExpired == false,"Already Active in this level"); 
        require(_level > 0 && _level <= 12,"Incorrect level");
        require(msg.value == levelPrice[_level],"Incorrect Value");
        
            
        users[msg.sender].X3Matrix[_level].levelExpired = true;
        users[msg.sender].currentLevel[1] = _level;
        
        if (users[msg.sender].X3Matrix[_level-1].blocked) {
                users[msg.sender].X3Matrix[_level-1].blocked = false;
        }
        
        uint _referrerID = users[findX3Referrer(msg.sender,_level)].id;
        
        updateX3Details(_referrerID,msg.sender,_level);
        emit buyLevelEvent(1,msg.sender, _level, now);
    }
    
    function X14BuyLevel(uint256 _level) external payable {
        require(lockStatus == false,"Contract Locked");
        require(users[msg.sender].isExist,"User not exist");
        require(_level > 0 && _level <= 12,"Incorrect level");
        require(users[msg.sender].X14Matrix[_level].levelStatus == false, "Already Active in this level");
        require(msg.value == levelPrice[_level],"Incorrect Value");
            
        users[msg.sender].X14Matrix[_level].levelStatus = true;
        users[msg.sender].currentLevel[2] = _level;
        users[msg.sender].X14Matrix[_level].firstLineRef = new address[](0);
        users[msg.sender].X14Matrix[_level].secondLineRef = new address[](0);
        users[msg.sender].X14Matrix[_level].reInvestCount = 0;
        
        uint _referrerID = users[findX14Referrer(msg.sender,_level)].id;
        
        updateX14Details(_referrerID,msg.sender,_level,0);
        emit buyLevelEvent(2,msg.sender, _level, now);
    }
    
    function contractLock(bool _lockStatus) public returns(bool) {
        require(msg.sender == ownerAddress, "Invalid User");
        lockStatus = _lockStatus;
        return true;
    }
    
    function updateLevelPrice(uint _level, uint _price) public returns(bool) {
          require(msg.sender == ownerAddress,"only OwnerWallet");
          levelPrice[_level] = _price;
          return true;
    }
    
    function updatePartnerAddress(address _partner) public returns(bool) {
          require(msg.sender == ownerAddress,"only OwnerWallet");
          partnerContract = _partner;
          return true;
    }
    
    function updateDividendAddress(address _dividentAddress) public returns(bool) {
          require(msg.sender == ownerAddress,"only OwnerWallet");
          dividendAddress = _dividentAddress;
          return true;
    }
    
    function failSafe(address payable _toUser, uint _amount) public returns (bool) {
        require(msg.sender == ownerAddress, "only Owner Wallet");
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }
    
    function viewX3UserReferral(address _userAddress,uint _level) public view returns(address[] memory) {
        return users[_userAddress].X3Matrix[_level].referral;
    }
    
    function viewX14UserReferral(address _userAddress,uint _level) public view returns(address[] memory,address [] memory, address [] memory) {
        return (users[_userAddress].X14Matrix[_level].firstLineRef,users[_userAddress].X14Matrix[_level].secondLineRef,users[_userAddress].X14Matrix[_level].thirdLineRef);
    }
    
    function viewX3UserLevelStatus(address _userAddress,uint _level) public view returns(bool) {
        return users[_userAddress].X3Matrix[_level].levelExpired;
    }
    
    function viewX14UserLevelStatus(address _userAddress,uint _level) public view returns(bool) {
        return users[_userAddress].X14Matrix[_level].levelStatus;
    }
    
    function getX3TotalEarnedEther() public view returns(uint) {
        uint totalEth;
        
        for( uint i=1;i<=currentId;i++) {
            totalEth = totalEth.add(totalEarnedEth[userList[i]][1]);
        }
        
        return totalEth;
    }
    
    function getAutoPoolTotalEarnedEther() public view returns(uint) {
         uint totalEth;
        
        for( uint i=1;i<=currentId;i++) {
            totalEth = totalEth.add(totalEarnedEth[userList[i]][2]);
        }
        
        return totalEth;
    }
    
    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, uint, bool) {
        return (userList[users[userAddress].X3Matrix[level].currentReferrer],
                users[userAddress].X3Matrix[level].referral,
                users[userAddress].X3Matrix[level].levelExpired,
                users[userAddress].X3Matrix[level].reInvestCount,
                users[userAddress].X3Matrix[level].blocked);
    }

    function usersX14Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, address [] memory,bool, uint) {
        return (userList[users[userAddress].X14Matrix[level].currentReferrer],
                users[userAddress].X14Matrix[level].firstLineRef,
                users[userAddress].X14Matrix[level].secondLineRef,
                users[userAddress].X14Matrix[level].thirdLineRef,
                users[userAddress].X14Matrix[level].levelStatus,
                users[userAddress].X14Matrix[level].reInvestCount);
    }
    
    function usersCurrentLevel(address _userAddress, uint _matrix) public view returns(uint) {
        return users[_userAddress].currentLevel[_matrix];
    }
    
    function getX14Referrer(uint _flag,uint _level,address _referrerAddress) internal view returns(uint) {
        require(users[_referrerAddress].X14Matrix[_level].levelStatus ==  true, "referer not active"); 
        
        if(_flag == 1) {
            address[] memory referrals = new address[](2);
            referrals[0] = users[_referrerAddress].X14Matrix[_level].firstLineRef[0];
            referrals[1] = users[_referrerAddress].X14Matrix[_level].firstLineRef[1];
            
            
            if(users[_referrerAddress].X14Matrix[_level].secondLineRef.length == 0 ||
            users[_referrerAddress].X14Matrix[_level].secondLineRef.length == 2) {
                
                if(users[referrals[0]].X14Matrix[_level].firstLineRef.length < 2) {
                    return (users[referrals[0]].id);
                }
            }
            
            else if(users[_referrerAddress].X14Matrix[_level].secondLineRef.length == 1 ||
            users[_referrerAddress].X14Matrix[_level].secondLineRef.length == 3) {
                
                if(users[referrals[1]].X14Matrix[_level].firstLineRef.length < 2) {
                    return (users[referrals[1]].id);
                }
            }
        }
        
        else if(_flag == 2) {
            address[] memory referrals = new address[](4);
            referrals[0] = users[_referrerAddress].X14Matrix[_level].secondLineRef[0];
            referrals[1] = users[_referrerAddress].X14Matrix[_level].secondLineRef[1];
            referrals[2] = users[_referrerAddress].X14Matrix[_level].secondLineRef[2];
            referrals[3] = users[_referrerAddress].X14Matrix[_level].secondLineRef[3];
            
            
            if(users[_referrerAddress].X14Matrix[_level].thirdLineRef.length == 0 ||
            users[_referrerAddress].X14Matrix[_level].thirdLineRef.length == 4)  {
                
                if(users[referrals[0]].X14Matrix[_level].firstLineRef.length < 2) {
                    return (users[referrals[0]].id);
                }
            }
            
            else if(users[_referrerAddress].X14Matrix[_level].thirdLineRef.length == 1 ||
            users[_referrerAddress].X14Matrix[_level].thirdLineRef.length == 5)  {
                
                if(users[referrals[1]].X14Matrix[_level].firstLineRef.length < 2) {
                    return (users[referrals[1]].id);
                }
            }
            
            else if(users[_referrerAddress].X14Matrix[_level].thirdLineRef.length == 2 ||
            users[_referrerAddress].X14Matrix[_level].thirdLineRef.length == 6)  {
                
                if(users[referrals[2]].X14Matrix[_level].firstLineRef.length < 2) {
                    return (users[referrals[2]].id);
                }
            }
            
            else if(users[_referrerAddress].X14Matrix[_level].thirdLineRef.length == 3 ||
            users[_referrerAddress].X14Matrix[_level].thirdLineRef.length == 7)  {
                
                if(users[referrals[3]].X14Matrix[_level].firstLineRef.length < 2) {
                    return (users[referrals[3]].id);
                }
            }
        
        }
        
    }
    
    function findX14Referrer(address userAddress, uint _level) internal  returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].X14Matrix[_level].levelStatus == true) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
            emit lostMoneyForLevelEvent(2,msg.sender,users[msg.sender].id,userAddress,users[userAddress].id, _level, levelPrice[_level],now);
        }
        
    }
    
    function findX3Referrer(address userAddress, uint _level) internal view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].X3Matrix[_level].levelExpired == true) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function X3Registration() internal  {
        require(lockStatus == false,"Contract Locked");
        
        address ref = findX3Referrer(msg.sender,1);
        users[msg.sender].X3Matrix[1].currentReferrer = users[ref].id;
        users[msg.sender].currentLevel[1] =1;
        users[msg.sender].X3Matrix[1].levelExpired = true;
        users[msg.sender].X3Matrix[1].blocked = false;
        
        updateX3Details(users[ref].id,msg.sender,1);
        emit regLevelEvent(1,msg.sender, ref, now);
    }
    
    function updateX3Details(uint _referrerID, address userAddress, uint level) internal {
        
        users[userList[_referrerID]].X3Matrix[level].referral.push(userAddress);

        if (users[userList[_referrerID]].X3Matrix[level].referral.length < 3) {
           
            return X3Pay(userList[_referrerID],level);
        }
        
       
        //close matrix
        users[userList[_referrerID]].X3Matrix[level].referral = new address[](0);
        if (!users[userList[_referrerID]].X3Matrix[level+1].levelExpired && level != LAST_LEVEL) {
            users[userList[_referrerID]].X3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (userList[_referrerID] != ownerAddress) {
            //check referrer active level
            address freeReferrerAddress = findX3Referrer(userList[_referrerID], level);
            if (users[userList[_referrerID]].X3Matrix[level].currentReferrer != users[freeReferrerAddress].id) {
                users[userList[_referrerID]].X3Matrix[level].currentReferrer = users[freeReferrerAddress].id;
            }
            
            users[userList[_referrerID]].X3Matrix[level].reInvestCount = users[userList[_referrerID]].X3Matrix[level].reInvestCount.add(1);
            emit reInvestEvent(1,userList[_referrerID],userList[users[userList[_referrerID]].X3Matrix[level].currentReferrer],msg.sender,level,users[userList[_referrerID]].X3Matrix[level].reInvestCount,now);   
            updateX3Details(users[freeReferrerAddress].id,userList[_referrerID], level);
            
        } else {
            X3Pay(ownerAddress,level);
            users[userList[1]].X3Matrix[level].reInvestCount = users[userList[1]].X3Matrix[level].reInvestCount.add(1);
            emit reInvestEvent(1,userList[_referrerID],userList[users[userList[_referrerID]].X3Matrix[level].currentReferrer],msg.sender,level,users[userList[_referrerID]].X3Matrix[level].reInvestCount,now);
        }
    }
    
    function X14Registration() internal  {
        require(lockStatus == false,"Contract Locked");
        require(users[msg.sender].isExist == true, "User not exist in working plan");
        
        address ref = findX14Referrer(msg.sender,1);

        users[msg.sender].X14Matrix[1].currentReferrer = users[ref].id;
        users[msg.sender].currentLevel[2] = 1;
        users[msg.sender].X14Matrix[1].levelStatus = true;
        
        updateX14Details(users[ref].id,msg.sender,1,0);
        
        emit regLevelEvent(2,msg.sender, ref, now);
    }
    
    function updateX14Details(uint _referrerID, address _userAddress,uint _level, uint _flag) internal {
        
        if (users[userList[_referrerID]].X14Matrix[_level].firstLineRef.length < 2) {
            users[userList[_referrerID]].X14Matrix[_level].firstLineRef.push(_userAddress);
            users[_userAddress].X14Matrix[_level].currentReferrer = _referrerID;
            
            uint ref2 = users[userList[_referrerID]].X14Matrix[_level].currentReferrer;
            
            if(ref2 != 0)
                users[userList[ref2]].X14Matrix[_level].secondLineRef.push(_userAddress);
            
            uint ref3 = users[userList[ref2]].X14Matrix[_level].currentReferrer;
            
            if(ref3 != 0) {
                users[userList[ref3]].X14Matrix[_level].thirdLineRef.push(_userAddress);
                _referrerID = ref3;
            }
            
            
        } else if (users[userList[_referrerID]].X14Matrix[_level].secondLineRef.length < 4)  {
            
            
            uint ref1;
             
            ref1 = getX14Referrer(1,_level,userList[_referrerID]);
                
            users[userList[ref1]].X14Matrix[_level].firstLineRef.push(_userAddress);
            users[_userAddress].X14Matrix[_level].currentReferrer = ref1;
            
            users[userList[_referrerID]].X14Matrix[_level].secondLineRef.push(_userAddress);
            
            uint ref3 = users[userList[_referrerID]].X14Matrix[_level].currentReferrer;
            
            if(ref3 != 0) {
                users[userList[ref3]].X14Matrix[_level].thirdLineRef.push(_userAddress);
                 _referrerID = ref3;
            }
           
            
        } else if (users[userList[_referrerID]].X14Matrix[_level].thirdLineRef.length < 8)  {
            
            
            uint ref1 = getX14Referrer(2,_level,userList[_referrerID]);
            
            users[userList[ref1]].X14Matrix[_level].firstLineRef.push(_userAddress);
            
            users[_userAddress].X14Matrix[_level].currentReferrer = ref1;
            
            uint ref2 = users[userList[ref1]].X14Matrix[_level].currentReferrer;
            
            users[userList[ref2]].X14Matrix[_level].secondLineRef.push(_userAddress);
            
            users[userList[_referrerID]].X14Matrix[_level].thirdLineRef.push(_userAddress);
            
            _referrerID = _referrerID;
            
        }
        
        //0 -- directUpline
        if((users[userList[_referrerID]].X14Matrix[_level].firstLineRef.length == 1 && users[userList[_referrerID]].X14Matrix[_level].secondLineRef.length == 0 ) || 
        (users[userList[_referrerID]].X14Matrix[_level].secondLineRef.length == 2 && users[userList[_referrerID]].X14Matrix[_level].thirdLineRef.length == 0) ||
        users[userList[_referrerID]].X14Matrix[_level].thirdLineRef.length == 1 || users[userList[_referrerID]].X14Matrix[_level].thirdLineRef.length == 3) {
            
            if(_flag == 0)
                X14Pay(0,_level,userList[_referrerID]);
        }
        
        //1 -- your wallet
        else if((users[userList[_referrerID]].X14Matrix[_level].firstLineRef.length == 2 && users[userList[_referrerID]].X14Matrix[_level].secondLineRef.length == 0) ||
        (users[userList[_referrerID]].X14Matrix[_level].secondLineRef.length == 1 && users[userList[_referrerID]].X14Matrix[_level].thirdLineRef.length == 0)  || 
        (users[userList[_referrerID]].X14Matrix[_level].secondLineRef.length == 3 && users[userList[_referrerID]].X14Matrix[_level].thirdLineRef.length == 0) ||
        users[userList[_referrerID]].X14Matrix[_level].thirdLineRef.length == 2 || users[userList[_referrerID]].X14Matrix[_level].thirdLineRef.length == 4 ||
        users[userList[_referrerID]].X14Matrix[_level].thirdLineRef.length == 5 || users[userList[_referrerID]].X14Matrix[_level].thirdLineRef.length == 7) {
            
            if(_flag == 0) 
                X14Pay(1,_level,userList[_referrerID]);
            
        }
        
        //2 -- oneaboveUpline
        else if( (users[userList[_referrerID]].X14Matrix[_level].secondLineRef.length == 4 &&  users[userList[_referrerID]].X14Matrix[_level].thirdLineRef.length == 0)||
        users[userList[_referrerID]].X14Matrix[_level].thirdLineRef.length == 6 ) {
            
            if(_flag == 0)
                X14Pay(2,_level,userList[_referrerID]);
        }
        
        
        else if(users[userList[_referrerID]].X14Matrix[_level].thirdLineRef.length == 8) {
            
            if(_flag == 0)
                X14Pay(3,_level,ownerAddress);
            
            users[userList[_referrerID]].X14Matrix[_level].firstLineRef = new address[](0);
            users[userList[_referrerID]].X14Matrix[_level].secondLineRef = new address[](0);
            users[userList[_referrerID]].X14Matrix[_level].thirdLineRef = new address[](0);
            
            if(userList[_referrerID] != ownerAddress) {
            
                address FreeReferrer = findX14Referrer(userList[_referrerID],_level);
                
                if (users[userList[_referrerID]].X14Matrix[_level].currentReferrer != users[FreeReferrer].id) {
                    users[userList[_referrerID]].X14Matrix[_level].currentReferrer = users[FreeReferrer].id;
                }
                
               updateX14Details(users[FreeReferrer].id,userList[_referrerID],_level,1);
               users[userList[_referrerID]].X14Matrix[_level].reInvestCount =  users[userList[_referrerID]].X14Matrix[_level].reInvestCount.add(1);
               emit reInvestEvent(2,userList[_referrerID],userList[users[userList[_referrerID]].X14Matrix[_level].currentReferrer],msg.sender,_level,users[userList[_referrerID]].X14Matrix[_level].reInvestCount,now);
            }
            else {
                users[ownerAddress].X14Matrix[_level].reInvestCount =  users[ownerAddress].X14Matrix[_level].reInvestCount.add(1);
                emit reInvestEvent(2,ownerAddress,address(0),msg.sender,_level,users[ownerAddress].X14Matrix[_level].reInvestCount,now);
            }
        }
        
    }
    
    function findX3Receiver(address referer, uint _level) internal returns(address) {
        
        while (true) {
                if (users[referer].X3Matrix[_level].blocked) {
                    emit lostMoneyForLevelEvent(1,msg.sender,users[msg.sender].id,referer,users[referer].id, _level, levelPrice[_level],now);
                    referer = userList[users[referer].X3Matrix[_level].currentReferrer];
                }
                else {
                    return referer;
                }
        }
        
    }

    function X3Pay(address _referrerAddress,uint _level) internal {
        
        address referer = findX3Receiver(_referrerAddress,_level);

        if(!users[referer].isExist) 
            referer = userList[1];
        
        
        if(users[referer].X3Matrix[_level].levelExpired == true) {
            if(referer == ownerAddress) {
                require((address(uint160(partnerContract)).send(levelPrice[_level])), "Transaction Failure X3");
                totalEarnedEth[partnerContract][1] = totalEarnedEth[partnerContract][1].add(levelPrice[_level]);
                EarnedEth[partnerContract][1][_level] =  EarnedEth[partnerContract][1][_level].add(levelPrice[_level]);
                emit getMoneyForLevelEvent(1,msg.sender,users[msg.sender].id,ownerAddress,1, _level, levelPrice[_level],now);
            } else {
                require((address(uint160(referer)).send(levelPrice[_level])), "Transaction Failure X3");
                totalEarnedEth[referer][1] = totalEarnedEth[referer][1].add(levelPrice[_level]);
                EarnedEth[referer][1][_level] =  EarnedEth[referer][1][_level].add(levelPrice[_level]);
                emit getMoneyForLevelEvent(1,msg.sender,users[msg.sender].id,referer,users[referer].id, _level, levelPrice[_level],now);
            }
        }    
        
    }
    
     function X14Pay(uint _flag,uint _level,address _userAddress) internal {
       
        address[2] memory referer;
        
        if(_flag == 0)
          referer[0] = userList[users[_userAddress].X14Matrix[_level].currentReferrer];
        
        else if(_flag == 1) 
          referer[0] = _userAddress;
             
        else if(_flag == 2) {
          referer[1] = userList[users[_userAddress].X14Matrix[_level].currentReferrer];
          referer[0] = userList[users[referer[1]].X14Matrix[_level].currentReferrer];
        }
        
        else if(_flag == 3) 
            referer[0] = ownerAddress;

        if(!users[referer[0]].isExist) 
            referer[0] = userList[1];
 
        
        if(users[referer[0]].X14Matrix[_level].levelStatus == true) {
            
            if(referer[0] == ownerAddress && _flag != 3) {
                
                require((address(uint160(partnerContract)).send(levelPrice[_level])), "Transaction Failure X14");
                totalEarnedEth[partnerContract][2] = totalEarnedEth[partnerContract][2].add(levelPrice[_level]);
                EarnedEth[partnerContract][2][_level] =  EarnedEth[partnerContract][2][_level].add(levelPrice[_level]);
                emit getMoneyForLevelEvent(2,msg.sender,users[msg.sender].id,ownerAddress,1, _level, levelPrice[_level],now);
                
            } else if(referer[0] == ownerAddress && _flag == 3) {
                
                uint256 share = ((levelPrice[_level]).mul(33.33 ether)).div(10**20);
                require((address(uint160(dividendAddress)).send(share)) &&
                (address(uint160(partnerContract)).send(levelPrice[_level].sub(share))), "Transaction Failure X14");
                dividendCount = dividendCount.add(1);
                totalEarnedEth[dividendAddress][2] = totalEarnedEth[dividendAddress][2].add(share);
                EarnedEth[dividendAddress][2][_level] =  EarnedEth[dividendAddress][2][_level].add(share);
                emit getMoneyForLevelEvent(2,msg.sender,users[msg.sender].id,dividendAddress,0, _level, share,now);
                totalEarnedEth[partnerContract][2] = totalEarnedEth[partnerContract][2].add(levelPrice[_level].sub(share));
                EarnedEth[partnerContract][2][_level] =  EarnedEth[partnerContract][2][_level].add(levelPrice[_level].sub(share));
                emit getMoneyForLevelEvent(2,msg.sender,users[msg.sender].id,ownerAddress,1, _level, levelPrice[_level].sub(share),now);
                
            }
            else {
                
                require((address(uint160(referer[0])).send(levelPrice[_level])), "Transaction Failure X14");
                totalEarnedEth[referer[0]][2] = totalEarnedEth[referer[0]][2].add(levelPrice[_level]);
                EarnedEth[referer[0]][2][_level] =  EarnedEth[referer[0]][2][_level].add(levelPrice[_level]);
                emit getMoneyForLevelEvent(2,msg.sender,users[msg.sender].id,referer[0],users[referer[0]].id, _level, levelPrice[_level],now);
            }    
        
         }
        
    }    
    
    
    function dividendShare(address[] memory addresses, uint256[] memory _amount) public payable returns (bool) {
        require(msg.sender == dividendAddress || msg.sender == ownerAddress, "Unauthorized call");
        require(addresses.length == _amount.length, "Invalid length");
        
        uint _divident = msg.value;
       
        for(uint i =0 ; i < addresses.length; i++) {
            require(addresses[i] != address(0),"Invalid address");
            require(_amount[i] > 0, "Invalid amount");
            require(users[addresses[i]].isExist, "User not exist");
            require(users[addresses[i]].X14Matrix[8].levelStatus == true, "Invalid level");
            require(dividendStatus[addresses[i]] == false, "Divident already sent");
            require(_divident >= _amount[i],"Insufficient divident");
            require(address(uint160(addresses[i])).send(_amount[i]), "Transfer failed");
            
            _divident = _divident.sub(_amount[i]);
            totalEarnedEth[dividendAddress][2] = totalEarnedEth[dividendAddress][2].sub(_amount[i]);
            dividendStatus[addresses[i]] = true;
            emit Dividend(addresses[i], _amount[i]);
        }
        
        return true;
    }
    
}