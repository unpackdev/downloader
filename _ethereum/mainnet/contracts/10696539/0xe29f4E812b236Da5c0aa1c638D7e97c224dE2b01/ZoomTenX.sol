pragma solidity >=0.4.23 <0.6.0;

contract ZoomTenX {
    
    struct UserAccount {
        uint id;
        address referrer;
        uint partnersCount;
         
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        
        mapping(uint8 => XXX) x3Matrix;
        mapping(uint8 => XXXX) x6Matrix;
    }
    
    struct XXX {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct XXXX{
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 12;
    
    mapping(address => UserAccount) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
 

    uint public lastUserId = 2;
    address payable public  owner;
 
    mapping(uint8 => uint) public levelPrice;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event UserIncome(address indexed user,address indexed from,uint256 value,uint8 matrix, uint8 level,uint8 logType);
    
    constructor(address payable ownerAddress) public {
        levelPrice[1] = 0.025 ether;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
           owner = ownerAddress;
      UserAccount memory user ;
          user= UserAccount({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });   
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX6Levels[i] = true;
        }
        userIds[1] = ownerAddress;
        
    }
  
    
    function regUser(address referrerAddress,uint8 _type) external payable {
        registration(msg.sender, referrerAddress,_type);
    }
    
    function purchaseLevel(uint8 matrix, uint8 level,uint8 _type) external payable {
        if(_type==0){
             require(users[msg.sender].id <=6,"You not have this prev." ); 
        }
       else{
             require(msg.value == levelPrice[level] ,"invalid price"); 
       }
      
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
     
       
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
       
        if (matrix == 1) {
            require(!users[msg.sender].activeX3Levels[level], "level already activated");

            if (users[msg.sender].x3Matrix[level-1].blocked) {
                users[msg.sender].x3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = getFreeXXXReferrer(msg.sender, level);
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
            updateXXXReferrer(msg.sender, freeX3Referrer, level,_type);
            
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);

        } else {
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = getFreeXXXXReferrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            updateXXXXReferrer(msg.sender, freeX6Referrer, level,_type);
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
    }    
    
    function registration(address userAddress, address referrerAddress,uint8 _type) private {
      if(_type==0){
            require(lastUserId <=6,"You not have this prev." );
      }else{
          require(msg.value == 0.05 ether, "Invalid Cost"); 
      }
       
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
    
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cc");
        
        UserAccount memory user = UserAccount({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeX3Referrer = getFreeXXXReferrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateXXXReferrer(userAddress, freeX3Referrer, 1,_type);

        updateXXXXReferrer(userAddress, getFreeXXXXReferrer(userAddress, 1), 1,_type);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateXXXReferrer(address userAddress, address referrerAddress, uint8 level,uint8 _type) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level,_type);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x3Matrix[level].blocked = true;
        }

       
        if (referrerAddress != owner) {
           
            address freeReferrerAddress = getFreeXXXReferrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateXXXReferrer(referrerAddress, freeReferrerAddress, level,_type);
        } else {
            sendETHDividends(owner, userAddress, 1, level,_type);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateXXXXReferrer(address userAddress, address referrerAddress, uint8 level,uint8 _type) private {
        require(users[referrerAddress].activeX6Levels[level], "500");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
     
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level,_type);
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateXXXXReferrerSecondLevel(userAddress, ref, level,_type);
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                updateXXXX(userAddress, referrerAddress, level, true);
                return updateXXXXReferrerSecondLevel(userAddress, referrerAddress, level,_type);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
            updateXXXX(userAddress, referrerAddress, level, true);
                return updateXXXXReferrerSecondLevel(userAddress, referrerAddress, level,_type);
            } else {
                updateXXXX(userAddress, referrerAddress, level, false);
                return updateXXXXReferrerSecondLevel(userAddress, referrerAddress, level,_type);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateXXXX(userAddress, referrerAddress, level, false);
            return updateXXXXReferrerSecondLevel(userAddress, referrerAddress, level,_type);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateXXXX(userAddress, referrerAddress, level, true);
            return updateXXXXReferrerSecondLevel(userAddress, referrerAddress, level,_type);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            updateXXXX(userAddress, referrerAddress, level, false);
        } else {
            updateXXXX(userAddress, referrerAddress, level, true);
        }
        
        updateXXXXReferrerSecondLevel(userAddress, referrerAddress, level,_type);
    }

    function updateXXXX(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateXXXXReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level , uint8 _type) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level,_type);
        }
        
        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = getFreeXXXXReferrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateXXXXReferrer(referrerAddress, freeReferrerAddress, level,_type);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level,_type);
        }
    }
    
    function getFreeXXXReferrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    
    function getFreeXXXXReferrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveXXXLevels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveXXXXLevels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersXXXMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked);
    }

    function usersXXXXMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function getEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                 
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
              
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level,uint8 _type) private {
        if(_type==1){
        (address receiver, bool isExtraDividends) = getEthReceiver(userAddress, _from, matrix, level);
        
       
        if (!address(uint160(receiver)).send(levelPrice[level])) {
             emit  UserIncome(receiver,_from,address(this).balance, matrix,level,0);
            return address(uint160(receiver)).transfer(address(this).balance);
        }
         emit  UserIncome(receiver,_from,levelPrice[level],matrix,level,1);
      
        }else{
          emit  UserIncome(userAddress,_from,levelPrice[level],matrix,level,1);
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}