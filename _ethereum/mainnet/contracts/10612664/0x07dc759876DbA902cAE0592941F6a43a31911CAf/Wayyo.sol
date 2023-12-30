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


contract ERC20 {
    function mint(address reciever, uint256 value) public returns(bool);
}

contract Wayyo {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        mapping(uint8 => bool) activeYo3Levels;
        mapping(uint8 => bool) activeYo4Levels;
        mapping(uint8 => Yo3Manual) Yo3Matrix;
        mapping(uint8 => Yo4Auto) Yo4Matrix;
    }
    
    struct Yo3Manual {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct Yo4Auto {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }

    ERC20 Token;
    using SafeMath for uint256;
    bool public lockStatus;
    uint8 public constant LAST_LEVEL = 12;
    uint public lastUserId = 2;
    address public ownerAddress;
    
    mapping(uint8 => uint) public levelPrice;
    mapping(address => User) public users;
    mapping(uint => address) public userIds;
    mapping(address => mapping(uint=> mapping(uint => uint))) public earnedEth; 
    mapping(address=> mapping (uint => uint)) public totalEarnedEth;
    
    modifier onlyOwner() {
        require(msg.sender == ownerAddress,"only Owner");
        _;
    }
    
    modifier isLock() {
        require(lockStatus == false,"Contract Locked");
        _;
    }
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    constructor(address _owner,address _tokenAddress) public {
        require(_tokenAddress != address(0),"Invalid Token Address");
        
        levelPrice[1] = 0.020 ether;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        
        ownerAddress = _owner;
        Token = ERC20(_tokenAddress);
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        userIds[1] = ownerAddress;
       
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeYo3Levels[i] = true;
            users[ownerAddress].activeYo4Levels[i] = true;
        }
        
    }
    
    // external functions
    function() external payable {
        revert("Invalid Contract Transaction");
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
            require(!users[msg.sender].activeYo3Levels[level], "level already activated");
            if (users[msg.sender].Yo3Matrix[level-1].blocked) {
                users[msg.sender].Yo3Matrix[level-1].blocked = false;
            }
            address freeYo3Referrer = findFreeYo3Referrer(msg.sender, level);
            users[msg.sender].Yo3Matrix[level].currentReferrer = freeYo3Referrer;
            users[msg.sender].activeYo3Levels[level] = true;
            updateYo3Referrer(msg.sender, freeYo3Referrer, level);
            emit Upgrade(msg.sender, freeYo3Referrer, 1, level);
        } else {
            require(!users[msg.sender].activeYo4Levels[level], "level already activated"); 
            if (users[msg.sender].Yo4Matrix[level-1].blocked) {
                users[msg.sender].Yo4Matrix[level-1].blocked = false;
            }
            address freeYo4Referrer = findFreeYo4Referrer(msg.sender, level);
            users[msg.sender].activeYo4Levels[level] = true;
            updateYo4Referrer(msg.sender, freeYo4Referrer, level);
            emit Upgrade(msg.sender, freeYo4Referrer, 2, level);
        }
    }   
    
    // public functions
    function failSafe(address payable _toUser, uint _amount) onlyOwner public returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }
    
    function contractLock(bool _lockStatus) onlyOwner public returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }
    
    function findFreeYo3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeYo3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeYo4Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeYo4Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveYo3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeYo3Levels[level];
    }

    function usersActiveYo4Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeYo4Levels[level];
    }

    function usersYo3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory,uint, bool) {
        return (users[userAddress].Yo3Matrix[level].currentReferrer,
                users[userAddress].Yo3Matrix[level].referrals,
                users[userAddress].Yo3Matrix[level].reinvestCount,
                users[userAddress].Yo3Matrix[level].blocked);
    }

    function usersYo4Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address,uint) {
        return (users[userAddress].Yo4Matrix[level].currentReferrer,
                users[userAddress].Yo4Matrix[level].firstLevelReferrals,
                users[userAddress].Yo4Matrix[level].secondLevelReferrals,
                users[userAddress].Yo4Matrix[level].blocked,
                users[userAddress].Yo4Matrix[level].closedPart,
                users[userAddress].Yo4Matrix[level].reinvestCount);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    //private functions
    function registration(address userAddress, address referrerAddress) isLock private {
        require(msg.value == 0.04 ether, "registration cost 0.04");
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
        users[userAddress].referrer = referrerAddress;
        users[userAddress].activeYo3Levels[1] = true; 
        users[userAddress].activeYo4Levels[1] = true;
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++;

        address freeYo3Referrer = findFreeYo3Referrer(userAddress, 1);
        users[userAddress].Yo3Matrix[1].currentReferrer = freeYo3Referrer;
        updateYo3Referrer(userAddress, freeYo3Referrer, 1);

        updateYo4Referrer(userAddress, findFreeYo4Referrer(userAddress, 1), 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateYo3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].Yo3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].Yo3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].Yo3Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].Yo3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeYo3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].Yo3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != ownerAddress) {
            //check referrer active level
            address freeReferrerAddress = findFreeYo3Referrer(referrerAddress, level);
            if (users[referrerAddress].Yo3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].Yo3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            users[referrerAddress].Yo3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateYo3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(ownerAddress, userAddress, 1, level);
            users[ownerAddress].Yo3Matrix[level].reinvestCount++;
            emit Reinvest(ownerAddress, address(0), userAddress, 1, level);
        }
    }

    function updateYo4Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeYo4Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].Yo4Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].Yo4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].Yo4Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].Yo4Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == ownerAddress) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].Yo4Matrix[level].currentReferrer;            
            users[ref].Yo4Matrix[level].secondLevelReferrals.push(userAddress); 
            uint len = users[ref].Yo4Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].Yo4Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].Yo4Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].Yo4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].Yo4Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].Yo4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].Yo4Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].Yo4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }
            return updateYo4ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].Yo4Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].Yo4Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].Yo4Matrix[level].closedPart)) {
                updateYo4(userAddress, referrerAddress, level, true);
                return updateYo4ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].Yo4Matrix[level].closedPart) {
                updateYo4(userAddress, referrerAddress, level, true);
                return updateYo4ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateYo4(userAddress, referrerAddress, level, false);
                return updateYo4ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateYo4(userAddress, referrerAddress, level, false);
            return updateYo4ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateYo4(userAddress, referrerAddress, level, true);
            return updateYo4ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[0]].Yo4Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[1]].Yo4Matrix[level].firstLevelReferrals.length) {
            updateYo4(userAddress, referrerAddress, level, false);
        } else {
            updateYo4(userAddress, referrerAddress, level, true);
        }
        
        updateYo4ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateYo4(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[0]].Yo4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[0]].Yo4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[0]].Yo4Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].Yo4Matrix[level].currentReferrer = users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[1]].Yo4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[1]].Yo4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[1]].Yo4Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].Yo4Matrix[level].currentReferrer = users[referrerAddress].Yo4Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateYo4ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].Yo4Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory Yo4 = users[users[referrerAddress].Yo4Matrix[level].currentReferrer].Yo4Matrix[level].firstLevelReferrals;
        
        if (Yo4.length == 2) {
            if (Yo4[0] == referrerAddress ||
                Yo4[1] == referrerAddress) {
                users[users[referrerAddress].Yo4Matrix[level].currentReferrer].Yo4Matrix[level].closedPart = referrerAddress;
            } else if (Yo4.length == 1) {
                if (Yo4[0] == referrerAddress) {
                    users[users[referrerAddress].Yo4Matrix[level].currentReferrer].Yo4Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        users[referrerAddress].Yo4Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].Yo4Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].Yo4Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeYo4Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].Yo4Matrix[level].blocked = true;
        }

        users[referrerAddress].Yo4Matrix[level].reinvestCount++;
        
        if (referrerAddress != ownerAddress) {
            address freeReferrerAddress = findFreeYo4Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateYo4Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(ownerAddress, address(0), userAddress, 2, level);
            sendETHDividends(ownerAddress, userAddress, 2, level);
        }
    }
    
    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].Yo3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].Yo3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].Yo4Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].Yo4Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);
        uint256 tobeminted;
        if(matrix == 1) {
            tobeminted = 30 ether;
            (bool success,) = (receiver).call.value(levelPrice[level])("");
            require(success && Token.mint(msg.sender, tobeminted),"Invalid Transaction");
            earnedEth[receiver][matrix][level] = earnedEth[receiver][matrix][level].add(levelPrice[level]);
            totalEarnedEth[receiver][matrix] = totalEarnedEth[receiver][matrix].add(levelPrice[level]);
        }
        else {
            tobeminted  = 15 ether;
            (bool success,) = (receiver).call.value(levelPrice[level])("");
            require( success && Token.mint(msg.sender, tobeminted),"Invalid Transaction");
            earnedEth[receiver][matrix][level] = earnedEth[receiver][matrix][level].add(levelPrice[level]);
            totalEarnedEth[receiver][matrix] = totalEarnedEth[receiver][matrix].add(levelPrice[level]);
        }
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
    function getYo3TotalEarnedEth() public view returns(uint) {
        uint256 yo3TotalEarn;
        
        for(uint i=1; i<=lastUserId;i++) {
            yo3TotalEarn = yo3TotalEarn.add(totalEarnedEth[userIds[i]][1]);
        }
        
        return yo3TotalEarn;
        
    }
    
    function getYo4TotalEarnedEth() public view returns(uint) {
        uint256 yo4TotalEarn;
        
        for(uint i=1; i<=lastUserId;i++) {
            yo4TotalEarn = yo4TotalEarn.add(totalEarnedEth[userIds[i]][2]);
        }
        
        return yo4TotalEarn;
        
    }
    
}