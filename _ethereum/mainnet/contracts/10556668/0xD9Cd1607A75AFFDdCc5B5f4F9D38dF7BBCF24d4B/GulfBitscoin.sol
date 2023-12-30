/**
 *Submitted for verification at Etherscan.io on 2020-07-19
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-19
*/

/**
 
* GulfBitscoin 
* http://gulfbitscoin.com/
* (only for GulfBitscoin members)
* 
**/


pragma solidity >=0.4.23 <0.6.0;

contract GulfBitscoin {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeDirect;
        mapping(uint8 => bool) activeBinary;
        
        mapping(uint8 => X) xDirect;
        mapping(uint8 => Y) yBinary;
    }
    
    struct X {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct Y {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public constant LAST_DAY = 43;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId = 2;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    
    constructor(address ownerAddress) public {
        levelPrice[1] = 0.025 ether;
        for (uint8 i = 2; i <= LAST_DAY; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_DAY; i++) {
            users[ownerAddress].activeDirect[i] = true;
            users[ownerAddress].activeBinary[i] = true;
        }
        
        userIds[1] = ownerAddress;
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_DAY, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeDirect[level], "level already activated");

            if (users[msg.sender].xDirect[level-1].blocked) {
                users[msg.sender].xDirect[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);
            users[msg.sender].xDirect[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeDirect[level] = true;
            updateX3Referrer(msg.sender, freeX3Referrer, level);
            
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);

        } else {
            require(!users[msg.sender].activeBinary[level], "level already activated"); 

            if (users[msg.sender].yBinary[level-1].blocked) {
                users[msg.sender].yBinary[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
            
            users[msg.sender].activeBinary[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level);
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 0.05 ether, "registration cost 0.05");
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
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeDirect[1] = true; 
        users[userAddress].activeBinary[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].xDirect[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].xDirect[level].referrals.push(userAddress);

        if (users[referrerAddress].xDirect[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].xDirect[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].xDirect[level].referrals = new address[](0);
        if (!users[referrerAddress].activeDirect[level+1] && level != LAST_DAY) {
            users[referrerAddress].xDirect[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].xDirect[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].xDirect[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].xDirect[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].xDirect[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeBinary[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].yBinary[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].yBinary[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].yBinary[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].yBinary[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].yBinary[level].currentReferrer;            
            users[ref].yBinary[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].yBinary[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].yBinary[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].yBinary[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].yBinary[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].yBinary[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].yBinary[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].yBinary[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].yBinary[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateX6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].yBinary[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].yBinary[level].closedPart != address(0)) {
            if ((users[referrerAddress].yBinary[level].firstLevelReferrals[0] == 
                users[referrerAddress].yBinary[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].yBinary[level].firstLevelReferrals[0] ==
                users[referrerAddress].yBinary[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].yBinary[level].firstLevelReferrals[0] == 
                users[referrerAddress].yBinary[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].yBinary[level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].yBinary[level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].yBinary[level].firstLevelReferrals[0]].yBinary[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].yBinary[level].firstLevelReferrals[1]].yBinary[level].firstLevelReferrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].yBinary[level].firstLevelReferrals[0]].yBinary[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].yBinary[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].yBinary[level].firstLevelReferrals[0]].yBinary[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].yBinary[level].firstLevelReferrals[0]].yBinary[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].yBinary[level].currentReferrer = users[referrerAddress].yBinary[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].yBinary[level].firstLevelReferrals[1]].yBinary[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].yBinary[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].yBinary[level].firstLevelReferrals[1]].yBinary[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].yBinary[level].firstLevelReferrals[1]].yBinary[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].yBinary[level].currentReferrer = users[referrerAddress].yBinary[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].yBinary[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory x6 = users[users[referrerAddress].yBinary[level].currentReferrer].yBinary[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].yBinary[level].currentReferrer].yBinary[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].yBinary[level].currentReferrer].yBinary[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].yBinary[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].yBinary[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].yBinary[level].closedPart = address(0);

        if (!users[referrerAddress].activeBinary[level+1] && level != LAST_DAY) {
            users[referrerAddress].yBinary[level].blocked = true;
        }

        users[referrerAddress].yBinary[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeDirect[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeBinary[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveDirect(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeDirect[level];
    }

    function usersActiveBinary(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeBinary[level];
    }

    function usersXDirect(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].xDirect[level].currentReferrer,
                users[userAddress].xDirect[level].referrals,
                users[userAddress].xDirect[level].blocked);
    }

    function usersYBinary(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].yBinary[level].currentReferrer,
                users[userAddress].yBinary[level].firstLevelReferrals,
                users[userAddress].yBinary[level].secondLevelReferrals,
                users[userAddress].yBinary[level].blocked,
                users[userAddress].yBinary[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].xDirect[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].xDirect[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].yBinary[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].yBinary[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        if (!address(uint160(receiver)).send(levelPrice[level])) {
            return address(uint160(receiver)).transfer(address(this).balance);
        }
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}