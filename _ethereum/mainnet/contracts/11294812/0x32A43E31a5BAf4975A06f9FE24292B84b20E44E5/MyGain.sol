pragma solidity >=0.4.23 <0.6.0;

contract MyGain {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        mapping(uint8 => bool) activeM3Levels;
        mapping(uint8 => bool) activeM4Levels;
        mapping(uint8 => M3) m3Matrix;
        mapping(uint8 => M4) m4Matrix;
    }
    
    struct M3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct M4 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 6;
    uint public lastUserId = 2;
    uint public adminFee = 1 ether;
    bool public lockStatus;
    address public owner;
    address public m3Wallet;
    address public m4Wallet;
    address public commissionWalet;
    
    mapping (address => User) public users;
    mapping (uint8 => uint) public levelPrice;
    mapping (uint => address) public userList;
    
     modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }
    
    modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    }
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId, uint _time);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level, uint _time);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint _time);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place, uint _time);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level, uint _time);
    event RecievedEth(address indexed receiver, address indexed _from, uint8 matrix, uint8 level, uint _time);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level, uint _time);
    event CommissionEvent(address _from, address _commissionWalet, uint _commissionAmount, uint8 _matrix, uint8 _level, uint _time);
    
    constructor(address ownerAddress, address _m3ReInvest, address _commissionWallet, address _m4Reinvest) public {
        levelPrice[1] = 0.5 ether;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        
        owner = ownerAddress;
        m3Wallet = _m3ReInvest;
        m4Wallet = _m4Reinvest;
        commissionWalet = _commissionWallet;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        userList[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeM3Levels[i] = true;
            users[ownerAddress].activeM4Levels[i] = true;
        }
    }
    
    
    function contractLock(bool _lockStatus) onlyOwner external returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }
    
    function updateLevelPrice(uint8 _level, uint _price) onlyOwner external returns(bool) {
        levelPrice[_level] = _price;
        return true;
    }
    
    function updateAdminFeePercentage(uint _fee) onlyOwner external returns(bool) {
        adminFee = _fee;
        return true;
    }
    
    function updateM3Wallet(address _m3) onlyOwner external returns(bool) {
        m3Wallet = _m3;
        return true;
    }
    
    function updateM4Wallet(address _m4) onlyOwner external returns(bool) {
        m4Wallet = _m4;
        return true;
    }
    
    function updateCommissionWallet(address _commission) onlyOwner external returns(bool) {
        commissionWalet = _commission;
        return true;
    }
    
    function failSafe(address payable _toUser, uint _amount) onlyOwner external returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }
    
    function() isLock external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) isLock external payable {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) isLock external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeM3Levels[level], "level already activated");

            if (users[msg.sender].m3Matrix[level-1].blocked) {
                users[msg.sender].m3Matrix[level-1].blocked = false;
            }
    
            address freeM3Referrer = findFreeM3Referrer(msg.sender, level);
            users[msg.sender].m3Matrix[level].currentReferrer = freeM3Referrer;
            users[msg.sender].activeM3Levels[level] = true;
            updateM3Referrer(0,msg.sender, freeM3Referrer, level);
            
            emit Upgrade(msg.sender, freeM3Referrer, 1, level, now);

        } else {
            require(!users[msg.sender].activeM4Levels[level], "level already activated"); 

            if (users[msg.sender].m4Matrix[level-1].blocked) {
                users[msg.sender].m4Matrix[level-1].blocked = false;
            }

            address freeM4Referrer = findFreeM4Referrer(msg.sender, level);
            
            users[msg.sender].activeM4Levels[level] = true;
            updateM4Referrer(0, msg.sender, freeM4Referrer, level);
            
            emit Upgrade(msg.sender, freeM4Referrer, 2, level, now);
        }
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == levelPrice[1] * (2), "Invalid Registration cost ");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        userList[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeM3Levels[1] = true; 
        users[userAddress].activeM4Levels[1] = true;
       
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeM3Referrer = findFreeM3Referrer(userAddress, 1);
        users[userAddress].m3Matrix[1].currentReferrer = freeM3Referrer;
        updateM3Referrer(0,userAddress, freeM3Referrer, 1);

        updateM4Referrer(0,userAddress, findFreeM4Referrer(userAddress, 1), 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id, now);
    }
    
    function updateM3Referrer(uint8 _flag,address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].m3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].m3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].m3Matrix[level].referrals.length), now);
            return sendETHDividends(_flag,referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3, now);
        //close matrix
        users[referrerAddress].m3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeM3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].m3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeM3Referrer(referrerAddress, level);
            if (users[referrerAddress].m3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].m3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].m3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level, now);
            updateM3Referrer(1,referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(1,owner, userAddress, 1, level);
            users[owner].m3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level, now);
        }
    }

    function updateM4Referrer(uint8 _flag,address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeM4Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].m4Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].m4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].m4Matrix[level].firstLevelReferrals.length), now);
            
            //set current level
            users[userAddress].m4Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(_flag,referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].m4Matrix[level].currentReferrer;            
            users[ref].m4Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].m4Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].m4Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].m4Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].m4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5, now);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6, now);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].m4Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].m4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3, now);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4, now);
                }
            } else if (len == 2 && users[ref].m4Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].m4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5, now);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6, now);
                }
            }

            return updateM4ReferrerSecondLevel(_flag,userAddress, ref, level);
        }
        
        users[referrerAddress].m4Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].m4Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].m4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].m4Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].m4Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].m4Matrix[level].closedPart)) {

                updateM4(userAddress, referrerAddress, level, true);
                return updateM4ReferrerSecondLevel(_flag,userAddress, referrerAddress, level);
            } else if (users[referrerAddress].m4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].m4Matrix[level].closedPart) {
                updateM4(userAddress, referrerAddress, level, true);
                return updateM4ReferrerSecondLevel(_flag,userAddress, referrerAddress, level);
            } else {
                updateM4(userAddress, referrerAddress, level, false);
                return updateM4ReferrerSecondLevel(_flag,userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].m4Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateM4(userAddress, referrerAddress, level, false);
            return updateM4ReferrerSecondLevel(_flag,userAddress, referrerAddress, level);
        } else if (users[referrerAddress].m4Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateM4(userAddress, referrerAddress, level, true);
            return updateM4ReferrerSecondLevel(_flag,userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].m4Matrix[level].firstLevelReferrals[0]].m4Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].m4Matrix[level].firstLevelReferrals[1]].m4Matrix[level].firstLevelReferrals.length) {
            updateM4(userAddress, referrerAddress, level, false);
        } else {
            updateM4(userAddress, referrerAddress, level, true);
        }
        
        updateM4ReferrerSecondLevel(_flag,userAddress, referrerAddress, level);
    }

    function updateM4(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].m4Matrix[level].firstLevelReferrals[0]].m4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].m4Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].m4Matrix[level].firstLevelReferrals[0]].m4Matrix[level].firstLevelReferrals.length), now);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].m4Matrix[level].firstLevelReferrals[0]].m4Matrix[level].firstLevelReferrals.length), now);
            //set current level
            users[userAddress].m4Matrix[level].currentReferrer = users[referrerAddress].m4Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].m4Matrix[level].firstLevelReferrals[1]].m4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].m4Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].m4Matrix[level].firstLevelReferrals[1]].m4Matrix[level].firstLevelReferrals.length), now);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].m4Matrix[level].firstLevelReferrals[1]].m4Matrix[level].firstLevelReferrals.length), now);
            //set current level
            users[userAddress].m4Matrix[level].currentReferrer = users[referrerAddress].m4Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateM4ReferrerSecondLevel(uint8 _flag,address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].m4Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(_flag,referrerAddress, userAddress, 2, level);
        }
        
        address[] memory M4Ref = users[users[referrerAddress].m4Matrix[level].currentReferrer].m4Matrix[level].firstLevelReferrals;
        
        if (M4Ref.length == 2) {
            if (M4Ref[0] == referrerAddress ||
                M4Ref[1] == referrerAddress) {
                users[users[referrerAddress].m4Matrix[level].currentReferrer].m4Matrix[level].closedPart = referrerAddress;
            } else if (M4Ref.length == 1) {
                if (M4Ref[0] == referrerAddress) {
                    users[users[referrerAddress].m4Matrix[level].currentReferrer].m4Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].m4Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].m4Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].m4Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeM4Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].m4Matrix[level].blocked = true;
        }

        users[referrerAddress].m4Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeM4Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level, now);
            updateM4Referrer(1,referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level, now);
            sendETHDividends(1,owner, userAddress, 2, level);
        }
    }
    
    function findFreeM3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeM3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeM4Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeM4Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveM3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeM3Levels[level];
    }

    function usersActiveM4Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeM4Levels[level];
    }

    function usersm3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].m3Matrix[level].currentReferrer,
                users[userAddress].m3Matrix[level].referrals,
                users[userAddress].m3Matrix[level].blocked);
    }

    function usersm4Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].m4Matrix[level].currentReferrer,
                users[userAddress].m4Matrix[level].firstLevelReferrals,
                users[userAddress].m4Matrix[level].secondLevelReferrals,
                users[userAddress].m4Matrix[level].blocked,
                users[userAddress].m4Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].m3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level, now);
                    isExtraDividends = true;
                    receiver = users[receiver].m3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].m4Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level, now);
                    isExtraDividends = true;
                    receiver = users[receiver].m4Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(uint8 _flag,address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);
        
        uint feeAmount = (levelPrice[level] * (adminFee))/10**20;
        
        if(_flag != 1) {
            
            require( (address(uint160(receiver)).send(levelPrice[level] - feeAmount)) &&  (address(uint160(commissionWalet)).send(feeAmount)),"Transaction Failure");
            emit CommissionEvent(_from, commissionWalet, feeAmount, matrix, level, now);
             
            if (isExtraDividends) {
                emit SentExtraEthDividends(_from, receiver, matrix, level, now);
            }
            
            else {
                emit RecievedEth(receiver, _from, matrix, level, now);
            }
        }
        else if(_flag == 1) {
            
            if(matrix == 1) {
                require( (address(uint160(m3Wallet)).send(levelPrice[level] - feeAmount)) &&  (address(uint160(commissionWalet)).send(feeAmount)),"ReInvest Wallet 1 Transaction Failure");
                emit RecievedEth(m3Wallet, _from, matrix, level, now);
            }
            
            else if(matrix == 2) {
                require( (address(uint160(m4Wallet)).send(levelPrice[level] - feeAmount)) &&  (address(uint160(commissionWalet)).send(feeAmount)),"ReInvest Wallet 2 Transaction Failure");
                emit RecievedEth(m4Wallet, _from, matrix, level, now);
            }
            
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}