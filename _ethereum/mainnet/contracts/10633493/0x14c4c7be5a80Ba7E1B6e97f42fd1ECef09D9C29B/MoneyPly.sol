/*______  ___                                 ______        
* ___   |/  /______________________  ____________  /____  __
* __  /|_/ /_  __ \_  __ \  _ \_  / / /__  __ \_  /__  / / /
* _  /  / / / /_/ /  / / /  __/  /_/ /__  /_/ /  / _  /_/ / 
* /_/  /_/  \____//_/ /_/\___/_\__, / _  .___//_/  _\__, /  
*                            /____/  /_/          /____/    
*
*  https://www.moneyply.io
*  (Strictly for Moneyply users)
*/


pragma solidity >=0.4.23 <0.6.0;

contract MoneyPly {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeM1Levels;
        mapping(uint8 => bool) activeM2Levels;
        mapping(uint8 => bool) activeM3Levels;
        
        mapping(uint8 => M1) m1Matrix;
        mapping(uint8 => M2) m2Matrix;
    }
    
    struct M1 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct M2 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 12;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances;
    
    mapping(uint => uint[]) public m3Ids;

    uint public lastUserId = 2;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event update(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    
    
    
    constructor(address ownerAddress) public {
        levelPrice[1] = 0.025 ether;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
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
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeM1Levels[i] = true;
            users[ownerAddress].activeM2Levels[i] = true;
            users[ownerAddress].activeM3Levels[i] = true;
            m3Ids[i].push(1);
            m3Ids[i].push(1);
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
        require(matrix == 1 || matrix == 2 || matrix == 3, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeM1Levels[level], "level already activated");

            if (users[msg.sender].m1Matrix[level-1].blocked) {
                users[msg.sender].m1Matrix[level-1].blocked = false;
            }
    
            address freeM1Referrer = findFreeM1Referrer(msg.sender, level);
            users[msg.sender].m1Matrix[level].currentReferrer = freeM1Referrer;
            users[msg.sender].activeM1Levels[level] = true;
            updateM1Referrer(msg.sender, freeM1Referrer, level);
            
            emit Upgrade(msg.sender, freeM1Referrer, 1, level);

        } else if (matrix == 2) {
            require(!users[msg.sender].activeM2Levels[level], "level already activated"); 

            if (users[msg.sender].m2Matrix[level-1].blocked) {
                users[msg.sender].m2Matrix[level-1].blocked = false;
            }

            address freeM2Referrer = findFreeM2Referrer(msg.sender, level);
            
            users[msg.sender].activeM2Levels[level] = true;
            updateM2Referrer(msg.sender, freeM2Referrer, level);
            
            emit Upgrade(msg.sender, freeM2Referrer, 2, level);
        }
        else {
            require(!users[msg.sender].activeM3Levels[level], "level already activated");
            users[msg.sender].activeM3Levels[level] = true;
            emit Upgrade(msg.sender, updateM3(msg.sender, level), 3, level);
            
        }
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 0.075 ether, "registration cost 0.075");
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
        
        users[userAddress].activeM1Levels[1] = true; 
        users[userAddress].activeM2Levels[1] = true;
        users[userAddress].activeM3Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeM1Referrer = findFreeM1Referrer(userAddress, 1);
        users[userAddress].m1Matrix[1].currentReferrer = freeM1Referrer;
        updateM1Referrer(userAddress, freeM1Referrer, 1);

        updateM2Referrer(userAddress, findFreeM2Referrer(userAddress, 1), 1);
        
        // Code for m3Ids
        updateM3(userAddress, 1);
        
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateM3(address userAddress, uint8 level) private returns (address receiver){
        // Assign the ID to user
        uint nodeNumber = m3Ids[level].length;
        
        if((nodeNumber) % 4 == 0){
            receiver =  idToAddress[m3Ids[level][nodeNumber/ 4]];
            uint idToPush = m3Ids[level][(nodeNumber/4) - 1];
            idToPush = idToPush == 0 ? 1 : idToPush;
            m3Ids[level].push(idToPush);
            emit Reinvest(receiver, idToAddress[idToPush], userAddress, 3, level);
            nodeNumber = nodeNumber + 1;
        }
        else {
            receiver = idToAddress[m3Ids[level][(nodeNumber)/4]];
        }
        m3Ids[level].push(users[userAddress].id);
        
        emit NewUserPlace(userAddress, receiver, 3, level, uint8((nodeNumber % 4)));
    
        address(uint160(receiver)).transfer(levelPrice[level]);
    }
    
    function updateM1Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].m1Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].m1Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].m1Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].m1Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeM1Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].m1Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeM1Referrer(referrerAddress, level);
            if (users[referrerAddress].m1Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].m1Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].m1Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateM1Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].m1Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateM2Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeM2Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].m2Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].m2Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].m2Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].m2Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].m2Matrix[level].currentReferrer;            
            users[ref].m2Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].m2Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].m2Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].m2Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].m2Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].m2Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].m2Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].m2Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].m2Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateM2ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].m2Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].m2Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].m2Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].m2Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].m2Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].m2Matrix[level].closedPart)) {

                updateM2(userAddress, referrerAddress, level, true);
                return updateM2ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].m2Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].m2Matrix[level].closedPart) {
                updateM2(userAddress, referrerAddress, level, true);
                return updateM2ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateM2(userAddress, referrerAddress, level, false);
                return updateM2ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].m2Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateM2(userAddress, referrerAddress, level, false);
            return updateM2ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].m2Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateM2(userAddress, referrerAddress, level, true);
            return updateM2ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].m2Matrix[level].firstLevelReferrals[0]].m2Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].m2Matrix[level].firstLevelReferrals[1]].m2Matrix[level].firstLevelReferrals.length) {
            updateM2(userAddress, referrerAddress, level, false);
        } else {
            updateM2(userAddress, referrerAddress, level, true);
        }
        
        updateM2ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateM2(address userAddress, address referrerAddress, uint8 level, bool m2) private {
        if (!m2) {
            users[users[referrerAddress].m2Matrix[level].firstLevelReferrals[0]].m2Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].m2Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].m2Matrix[level].firstLevelReferrals[0]].m2Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].m2Matrix[level].firstLevelReferrals[0]].m2Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].m2Matrix[level].currentReferrer = users[referrerAddress].m2Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].m2Matrix[level].firstLevelReferrals[1]].m2Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].m2Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].m2Matrix[level].firstLevelReferrals[1]].m2Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].m2Matrix[level].firstLevelReferrals[1]].m2Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].m2Matrix[level].currentReferrer = users[referrerAddress].m2Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateM2ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].m2Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory m2 = users[users[referrerAddress].m2Matrix[level].currentReferrer].m2Matrix[level].firstLevelReferrals;
        
        if (m2.length == 2) {
            if (m2[0] == referrerAddress ||
                m2[1] == referrerAddress) {
                users[users[referrerAddress].m2Matrix[level].currentReferrer].m2Matrix[level].closedPart = referrerAddress;
            } else if (m2.length == 1) {
                if (m2[0] == referrerAddress) {
                    users[users[referrerAddress].m2Matrix[level].currentReferrer].m2Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].m2Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].m2Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].m2Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeM2Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].m2Matrix[level].blocked = true;
        }

        users[referrerAddress].m2Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeM2Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateM2Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeM1Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeM1Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeM2Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeM2Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveM1Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeM1Levels[level];
    }

    function usersActiveM2Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeM2Levels[level];
    }

    function usersM1Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].m1Matrix[level].currentReferrer,
                users[userAddress].m1Matrix[level].referrals,
                users[userAddress].m1Matrix[level].blocked);
    }

    function usersM2Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].m2Matrix[level].currentReferrer,
                users[userAddress].m2Matrix[level].firstLevelReferrals,
                users[userAddress].m2Matrix[level].secondLevelReferrals,
                users[userAddress].m2Matrix[level].blocked,
                users[userAddress].m2Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].m1Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].m1Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].m2Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].m2Matrix[level].currentReferrer;
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