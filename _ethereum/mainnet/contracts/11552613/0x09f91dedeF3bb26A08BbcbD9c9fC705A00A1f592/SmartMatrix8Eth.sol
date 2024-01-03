pragma solidity >=0.4.23 <0.6.0;

contract SmartMatrix8Eth {
    struct User {
        uint256 id;
        address referrer;
        mapping(uint8 => bool) activeX5Levels;
        mapping(uint8 => uint256) reinvestCounts;
        mapping(uint8 => bool) blockX5Levels;
        mapping(uint8 => uint256) partnersCounts;
    }

     struct X5 {
        mapping(uint8 => address) referrals;
        uint8   lastRefereeId;
        address placer;
        address freePlacer;
    }

    struct luckyGroup {
        mapping(address => uint256) users;
        mapping(uint256 => address) ids;
        uint256 lastId;
    }

    mapping(address => X5) x5Matrix;

    uint8 public constant LAST_LEVEL = 12;

    mapping(address => User) public users;
    mapping(uint256 => address) public idToAddress;
    mapping(uint8 => luckyGroup) public luckyGroups;

    uint256 public lastUserId = 2;
    address public owner;

    mapping(uint8 => uint256) public levelPrice;

    event Registration(
        address indexed user,
        address indexed referrer,
        uint256 indexed userId,
        address placer
    );

    event Reinvest(uint256 receiver, uint8 rtype, uint256 bonus, uint8 level);

    event Upgrade(address indexed user, uint8 level);

    constructor(address ownerAddress) public {
        levelPrice[1] = 0.1 ether;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i - 1] * 2;
        }

        owner = ownerAddress;

        User memory user = User({
            id: 1,
            referrer: address(0)
        });

        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX5Levels[i] = true;
        }

        x5Matrix[ownerAddress].placer = ownerAddress;
        x5Matrix[ownerAddress].freePlacer = ownerAddress;
    }

    function() external payable {
        if (msg.data.length == 0) {
            return registration(msg.sender, owner);
        }

        registration(msg.sender, bytesToAddress(msg.data));
    }

    function sendETHDividends(
        address userAddress,
        address referrerAddress,
        uint8 level
    ) private {
        int256 amount = int256(levelPrice[level]);
        uint256 bonus = uint256(amount / 10);

        address(uint160(referrerAddress)).transfer(bonus);

        amount -= int256(bonus);

        address receiver = userAddress;
        uint256 receivers = users[referrerAddress].id;
        int256 index;

        while (true) {
            receiver = x5Matrix[receiver].placer;

            if (receiver == owner) break;

            if (index - int256(users[receiver].partnersCounts[level]) > 2) {
                continue;
            }

            if (users[receiver].blockX5Levels[level]) {
                continue;
            }

            if (level > 1 && !users[receiver].activeX5Levels[level]) {
                continue;
            }

            amount -= int256(bonus);

            address(uint160(receiver)).transfer(bonus);

            receivers = receivers * 0xffffffff + users[receiver].id;

            users[receiver].reinvestCounts[level] += 1;

            if (level > 1 && level < LAST_LEVEL) {
                if (
                    !users[receiver].activeX5Levels[level + 1] &&
                    users[receiver].reinvestCounts[level] >= 30
                ) {
                    users[receiver].blockX5Levels[level] = true;
                }
            }

            index++;

            if (index >= 7) {
                break;
            }
        }

        emit Reinvest(receivers, 1, bonus, level);
        uint256 lucklastId = luckyGroups[level].lastId;
        if (lucklastId > 0) {
            address randaddress = luckyGroups[level].ids[block.number %
                lucklastId];

            address(uint160(randaddress)).transfer(bonus);

            emit Reinvest(users[randaddress].id, 2, bonus, level);

            amount -= int256(bonus);
        }

        if (amount > 0) {
            emit Reinvest(1, 3, uint256(amount), level);
            address(uint160(owner)).transfer(address(this).balance);
        }
    }

    function registrationExt(address referrerAddress, address userAddress)
        external
        payable
    {
        registration(userAddress, referrerAddress);
        sendETHDividends(userAddress, referrerAddress, 1);
    }

    function addToLuckyGroup(address referrerAddress, uint8 level) private {
        uint256 lastId = luckyGroups[level].lastId;
        luckyGroups[level].users[referrerAddress] = lastId;
        luckyGroups[level].ids[lastId] = referrerAddress;
        luckyGroups[level].lastId = lastId + 1;
    }

    function buyNewLevel(address userAddress, uint8 level) external payable {
        require(
            isUserExists(msg.sender),
            "user is not exists. Register first."
        );

        require(
            isUserExists(userAddress),
            "user is not exists. Register first."
        );

        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        require(
            !users[userAddress].activeX5Levels[level],
            "level already activated"
        );

        require(
            users[userAddress].activeX5Levels[level - 1],
            "level should be correct"
        );

        if (users[userAddress].blockX5Levels[level - 1]) {
            users[userAddress].blockX5Levels[level - 1] = false;
        }

        users[userAddress].activeX5Levels[level] = true;
        address referrerAddress = users[userAddress].referrer;
        users[referrerAddress].partnersCounts[level]++;

        if (users[referrerAddress].partnersCounts[level] >= 30) {
            addToLuckyGroup(referrerAddress, level);
        }

        emit Upgrade(userAddress, level);

        sendETHDividends(userAddress, referrerAddress, level);
    }

    function registration(address userAddress, address referrerAddress)
        private
    {
        require(msg.value == 0.1 ether, "registration cost 0.1");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress
        });

        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        x5Matrix[userAddress].freePlacer = userAddress;

        users[userAddress].activeX5Levels[1] = true;
        users[referrerAddress].partnersCounts[1]++;

        if (users[referrerAddress].partnersCounts[1] >= 30) {
            addToLuckyGroup(referrerAddress, 1);
        }

        address placer = updateX5Referrer(
            userAddress,
            referrerAddress,
            x5Matrix[referrerAddress].freePlacer
        );

        emit Registration(userAddress, referrerAddress, lastUserId, placer);

        lastUserId++;
    }

    function getPosition(address placer, address userAddress)
        private
        view
        returns (uint8)
    {
        for (uint8 i = 0; i < 4; i++) {
            if (x5Matrix[placer].referrals[i] == userAddress) return i;
        }
        return 4;
    }

    function findfreePlacer(address referrer, address placer)
        private
        view
        returns (address)
    {
        uint256 level = 0;

        while (true) {
            if (placer == referrer) {
                placer = x5Matrix[referrer].referrals[0];
                break;
            }

            address SuperPlacer = x5Matrix[placer].placer;
            uint8 pos = getPosition(SuperPlacer, placer);

            if (pos < 4) {
                placer = x5Matrix[SuperPlacer].referrals[pos + 1];
                break;
            }

            placer = SuperPlacer;
            level++;
        }

        while (level > 0) {
            placer = x5Matrix[placer].referrals[0];
            level--;
        }

        return placer;
    }

    function updateX5Referrer(
        address userAddress,
        address referrer,
        address freePlacer
    ) private returns (address) {
        while (true) {
            uint8 lastRefereeId = x5Matrix[freePlacer].lastRefereeId;
            if (lastRefereeId  < 5) {
                x5Matrix[freePlacer].referrals[lastRefereeId] = userAddress;
                x5Matrix[referrer].freePlacer = freePlacer;
                x5Matrix[userAddress].placer = freePlacer;
                lastRefereeId ++;
                x5Matrix[freePlacer].lastRefereeId =  lastRefereeId;
                return freePlacer;
            }


            freePlacer = findfreePlacer(referrer, freePlacer);
        }
    }

    function usersActiveX5Levels(address userAddress, uint8 level)
        public
        view
        returns (bool)
    {
        return users[userAddress].activeX5Levels[level];
    }

    function usersX5Matrix(address userAddress, uint8 id)
        public
        view
        returns (address, address)
    {
        return (x5Matrix[userAddress].placer, x5Matrix[userAddress].referrals[id]);
    }

    function usersLuckyGroupsLevels(address userAddress, uint8 level)
        public
        view
        returns (uint256)
    {
        return luckyGroups[level].users[userAddress];
    }

    function usersInfo(address userAddress, uint8 level)
        public
        view
        returns (
            uint256,
            address,
            address,
            uint256
        )
    {
        return (
            users[userAddress].id,
            users[userAddress].referrer,
            x5Matrix[userAddress].placer,
            users[userAddress].partnersCounts[level]
        );
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function bytesToAddress(bytes memory bys)
        private
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}