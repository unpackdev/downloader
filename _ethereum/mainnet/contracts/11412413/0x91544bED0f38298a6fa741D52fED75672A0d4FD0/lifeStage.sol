pragma solidity 0.5.16;

contract lifeStage {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        uint totalETHEarnings;
        uint zeroBonusStartMonth;
        uint zeroBonusEndMonth;
        uint  zreEarnedETH;
        uint  ldbEarnedETH;
        uint [] userLDBDays;
        uint currLDBDay;
        uint currZREMonth;
        bool zeroBonus;
        
        
        mapping(uint => bool) userZREReceived;
        
        mapping(uint => UserSLAP) userSLAP;
        
        mapping(uint8 => bool) activeA7Levels;
        mapping(uint8 => bool) activeP7Levels;
        
        mapping(uint8 => A7) a7Matrix;
        mapping(uint8 => P7) p7Matrix;
    }
    
    
    struct UserSLAP{
        uint slap;
        uint referralCount;
        bool received;
    }
    
    struct A7 {
        address currentReferrer;
        address[] referrals;
        uint referralsCount;
        bool blocked;
        uint reinvestCount;
    }
    
    struct P7 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        uint referralsCount;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }
    
    struct divZRERecord
    {
        uint totalDividendCollection;
        uint totalEligibleCount;
        uint nextMonthEligibleCount;
        uint withdrawalCount;
        uint withdrawalDividend;
        bool withdrawStatus;
    }
    
    struct divLDRecord  
    {
        uint totalSLAPCollection;
        uint totalS1EligibleCount;
        uint totalS2EligibleCount;
        uint totalS3EligibleCount;
        uint totalS4EligibleCount;
        uint totalS5EligibleCount;
        bool withdrawStatus;
    }
    
    divLDRecord[] public  LDB;
    divZRERecord[] public ZRE;

    uint8 public constant LAST_LEVEL = 2;
    uint public oneMonthDuration = 30 days;
    uint public oneDayDuration = 1 days;
    uint public thisMonthEnd;
    uint public thisDayEnd;
    uint public adminLDBCommission;
    uint public adminZRECommission;
    bool public lockStatus;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    uint public lastUserId = 2;
    address public owner;
    uint public LDBPrice = 0.05 ether;
    uint public SLAPPrice = LDBPrice*(80 ether)/(100 ether);
    uint public LDBAdminCommission = LDBPrice*(20 ether)/(100 ether);
    uint public ZREPrice = (SLAPPrice * (20 ether)/(100 ether));
    uint public LDBDisPrice = 80 ether;
    uint public ZREETHLimit = 0.3 ether;
    
    uint public totalEarnedETH=0;
    uint public currLDB;
    uint public currZRE;
    
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId, uint _time);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level, uint _time);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint _time);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place, uint _time);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level, uint _time);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level, uint _time);
    event LDBWithdrawal(address indexed _user, uint indexed _day, uint _amount, uint _time);
    event ZREWithdrawal(address indexed _user, uint indexed _month, uint _amount, uint _time);
    
    
    constructor() public {
        levelPrice[1] = 0.05 ether;
        levelPrice[2] = 0.1 ether;
        // for (uint8 i = 2; i <= LAST_LEVEL; i++) {
        //     levelPrice[i] = levelPrice[i-1] * 2;
        // }
        
        owner = msg.sender;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            totalETHEarnings:0,
            zeroBonusStartMonth:0,
            zeroBonusEndMonth:0,
            zreEarnedETH:0,
            ldbEarnedETH:0,
            userLDBDays: new uint[](0),
            currLDBDay:0,
            currZREMonth:0,
            zeroBonus:true
        });
        
        users[owner] = user;
        idToAddress[1] = owner;
        
        for (uint8 i = 1; i <= 2; i++) {
            users[owner].activeA7Levels[i] = true;
            users[owner].activeP7Levels[i] = true;
        }
        
        
        startNextDay();
        startNextMonth();
        
        uint lastZREIndex = ZRE.length -1;
        users[owner].zeroBonusStartMonth = lastZREIndex+1;
        ZRE[lastZREIndex].nextMonthEligibleCount++;
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable {
        require(lockStatus == false,"Contract is locked");
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(lockStatus == false,"Contract is locked");
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= 2, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeA7Levels[level], "level already activated");

            if (users[msg.sender].a7Matrix[level-1].blocked) {
                users[msg.sender].a7Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeA7Referrer(msg.sender, level);
            users[msg.sender].a7Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeA7Levels[level] = true;
            updateA7Referrer(msg.sender, freeX3Referrer, level);
            
            emit Upgrade(msg.sender, freeX3Referrer, 1, level, now);

        } else {
            require(!users[msg.sender].activeP7Levels[level], "level already activated"); 

            if (users[msg.sender].p7Matrix[level-1].blocked) {
                users[msg.sender].p7Matrix[level-1].blocked = false;
            }

            address freeP7Referrer = findFreeP7Referrer(msg.sender, level);
            
            users[msg.sender].activeP7Levels[level] = true;
            updateP7Referrer(msg.sender, freeP7Referrer, level);
            
            emit Upgrade(msg.sender, freeP7Referrer, 2, level, now);
        }
    }    
    
    function startNextDay() public returns(bool)
    {
        require(msg.sender == owner,"Invalid user address");
        require(thisDayEnd < now,"day end not reached");
        thisDayEnd = now + oneDayDuration;
        divLDRecord memory temp;
        temp.totalS1EligibleCount = 1;
        temp.totalS2EligibleCount = 1;
        temp.totalS3EligibleCount = 1;
        temp.totalS4EligibleCount = 1;
        temp.totalS5EligibleCount = 1;
        
        LDB.push(temp);
        
        uint lastLDBIndex = LDB.length-1;
        currLDB = lastLDBIndex;
        users[owner].userSLAP[lastLDBIndex].slap = 5;
        
        if(lastLDBIndex > 0){
            LDB[lastLDBIndex-1].withdrawStatus = true;
            
            if(adminLDBCommission > 0){
                require(
                    address(uint160(owner)).send(adminLDBCommission),
                    "ZRE admin fee transfer failed"
                );
                
                users[owner].totalETHEarnings += adminLDBCommission;
                adminLDBCommission = 0;
            }
            
        }
        
        return (true);
    }
    
    function startNextMonth() public returns(bool)
    {
        require(msg.sender == owner,"Invalid user address");
        require(thisMonthEnd < now,"month end not reached");
        thisMonthEnd = now + oneMonthDuration;
        divZRERecord memory temp;
        temp.totalEligibleCount = 0;
        ZRE.push(temp);
        uint lastDivPoolIndex = ZRE.length -1;
        currZRE = lastDivPoolIndex;
        
         if (lastDivPoolIndex > 0)
        {
            ZRE[lastDivPoolIndex].totalEligibleCount = ZRE[lastDivPoolIndex -1].totalEligibleCount + ZRE[lastDivPoolIndex -1].nextMonthEligibleCount;
            ZRE[lastDivPoolIndex -1].withdrawStatus = true;
            
            if(adminZRECommission > 0){
                require(
                    address(uint160(owner)).send(adminZRECommission),
                    "ZRE admin fee transfer failed"
                );
                users[owner].totalETHEarnings += adminZRECommission;
                adminZRECommission = 0;
            }
        }
        
        if(lastDivPoolIndex == 1)
            ZRE[lastDivPoolIndex].totalDividendCollection = ZRE[lastDivPoolIndex-1].totalDividendCollection;
        
        return (true);
    }
    
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == levelPrice[1]*3, "registration cost 0.15");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            totalETHEarnings:0,
            zeroBonusStartMonth:0,
            zeroBonusEndMonth:0,
            zreEarnedETH:0,
            ldbEarnedETH:0,
            userLDBDays: new uint[](0),
            currLDBDay:0,
            currZREMonth:0,
            zeroBonus:true
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeA7Levels[1] = true; 
        users[userAddress].activeP7Levels[1] = true;
        
        lastUserId++;
        
        users[referrerAddress].partnersCount++;
        
        LDB[LDB.length -1].totalSLAPCollection += SLAPPrice;
        
        slapDistrubution( referrerAddress, LDB.length -1);
        
        ZRE[ZRE.length -1].totalDividendCollection += ZREPrice*(80 ether)/ (100 ether);
        
        users[msg.sender].zeroBonusStartMonth = ZRE.length;
        users[msg.sender].currZREMonth = users[msg.sender].zeroBonusStartMonth;
        ZRE[ZRE.length -1].nextMonthEligibleCount++;

        if(users[referrerAddress].zeroBonus)
        {
            if((ZRE.length-1) == 0)
                ZRE[ZRE.length -1].nextMonthEligibleCount--;
            else    
                ZRE[ZRE.length -1].totalEligibleCount--;
            
            users[referrerAddress].zeroBonus = false;
            users[referrerAddress].zeroBonusEndMonth = ZRE.length -1;
        }
        
        address freeA7Referrer = findFreeA7Referrer(userAddress, 1);
        users[userAddress].a7Matrix[1].currentReferrer = freeA7Referrer;
        updateA7Referrer(userAddress, freeA7Referrer, 1);

        updateP7Referrer(userAddress, findFreeP7Referrer(userAddress, 1), 1);
        
        adminLDBCommission += LDBAdminCommission;
        adminZRECommission += ((ZREPrice)*(20 ether)/ (100 ether));
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id, now);
    }
    
    function withdrawLDB(uint _day) public returns(bool)
    {
        address payable caller = msg.sender;
        require(lockStatus == false,"Contract is locked");
        require(users[caller].id > 0, 'User not exist');
        require(_day <= LDB.length -1,"invalid end day");
        require(LDB[_day].totalSLAPCollection > 0,"LDB divident is zero");
        require(LDB[_day].withdrawStatus == true,"this day divident is not actived");
        
        uint totalAmount;
            
        require(users[caller].userSLAP[_day].received == false,"User already rceived");
        require(users[caller].userSLAP[_day].slap > 0,"User not qualified to receive LDB");
        
        uint slapPercent;
        uint _slap = users[caller].userSLAP[_day].slap;
        if(_slap == 1){
            slapPercent = LDB[_day].totalSLAPCollection*(10 ether)/(100 ether);
            totalAmount +=slapPercent/LDB[_day].totalS1EligibleCount;
        }
        else if(_slap == 2){
            slapPercent = LDB[_day].totalSLAPCollection*(10 ether)/(100 ether);
            totalAmount +=slapPercent/LDB[_day].totalS1EligibleCount;
            slapPercent = LDB[_day].totalSLAPCollection*(20 ether)/(100 ether);
            totalAmount +=slapPercent/LDB[_day].totalS2EligibleCount;
        }
        else if(_slap == 3){
            slapPercent = LDB[_day].totalSLAPCollection*(10 ether)/(100 ether);
            totalAmount +=slapPercent/LDB[_day].totalS1EligibleCount;
            slapPercent = LDB[_day].totalSLAPCollection*(20 ether)/(100 ether);
            totalAmount +=slapPercent/LDB[_day].totalS2EligibleCount;
            slapPercent = LDB[_day].totalSLAPCollection*(20 ether)/(100 ether);
            totalAmount +=slapPercent/LDB[_day].totalS3EligibleCount;
        }
        else if(_slap == 4){
            slapPercent = LDB[_day].totalSLAPCollection*(10 ether)/(100 ether);
            totalAmount +=slapPercent/LDB[_day].totalS1EligibleCount;
            slapPercent = LDB[_day].totalSLAPCollection*(20 ether)/(100 ether);
            totalAmount +=slapPercent/LDB[_day].totalS2EligibleCount;
            slapPercent = LDB[_day].totalSLAPCollection*(20 ether)/(100 ether);
            totalAmount +=slapPercent/LDB[_day].totalS3EligibleCount;
            slapPercent = LDB[_day].totalSLAPCollection*(20 ether)/(100 ether);
            totalAmount +=slapPercent/LDB[_day].totalS4EligibleCount;
        }
        else if(_slap == 5){
            slapPercent = LDB[_day].totalSLAPCollection*(10 ether)/(100 ether);
            totalAmount =slapPercent/LDB[_day].totalS1EligibleCount;
            slapPercent = LDB[_day].totalSLAPCollection*(20 ether)/(100 ether);
            totalAmount +=slapPercent/LDB[_day].totalS2EligibleCount;
            slapPercent = LDB[_day].totalSLAPCollection*(20 ether)/(100 ether);
            totalAmount +=slapPercent/LDB[_day].totalS3EligibleCount;
            slapPercent = LDB[_day].totalSLAPCollection*(20 ether)/(100 ether);
            totalAmount +=slapPercent/LDB[_day].totalS4EligibleCount;
            slapPercent = LDB[_day].totalSLAPCollection*(10 ether)/(100 ether);
            totalAmount +=slapPercent/LDB[_day].totalS5EligibleCount;
        }
        users[caller].userSLAP[_day].received = true;
        users[caller].currLDBDay = _day;
        
        require(address(uint160(caller)).send(totalAmount),"transfer failed");
        users[msg.sender].ldbEarnedETH += totalAmount;
        users[msg.sender].totalETHEarnings += totalAmount;
        totalEarnedETH += totalAmount;
        
        emit LDBWithdrawal( msg.sender, _day, totalAmount, now);
        
        return true;
    }
    
    function withdrawZRE(uint _month) public returns(bool){
        require(lockStatus == false,"Contract is locked");
        require(_month <= ZRE.length -1,"invalid end month");
        require(users[msg.sender].id > 0, 'User not exist');
        require(_month > 0,"month should be greather than zero");
        require(ZRE[_month].totalDividendCollection > 0,"month divident is zero");
        require(ZRE[_month].withdrawStatus == true,"this month divident is not activated");
        
        
        uint totalAmount;
        
        require(
            (_month >= users[msg.sender].zeroBonusStartMonth) &&
            ((_month < users[msg.sender].zeroBonusEndMonth) || ((users[msg.sender].zeroBonusEndMonth == 0) && (users[msg.sender].zeroBonus == true))),
            "invalid month"
        );
        
        require(!users[msg.sender].userZREReceived[_month],"already received");
        
        if(_month > 1){
            if((_month-1) >= users[msg.sender].zeroBonusStartMonth)
                require(users[msg.sender].userZREReceived[_month-1],"previous month withdrawal not happened");
        }
        
        totalAmount = ZRE[_month].totalDividendCollection / ZRE[_month].totalEligibleCount;
        users[msg.sender].userZREReceived[_month] = true;
        users[msg.sender].currZREMonth = _month;
        
        ZRE[_month].withdrawalCount++;
        
        require(ZRE[_month].withdrawalCount <= ZRE[_month].totalEligibleCount,"withdrawal count exceed");
        
        if((users[msg.sender].zreEarnedETH+totalAmount) > ZREETHLimit){
            totalAmount = ZREETHLimit - users[msg.sender].zreEarnedETH+totalAmount;
            
            if(users[msg.sender].zeroBonus == true){
                users[msg.sender].zeroBonus = false;
                users[msg.sender].zeroBonusEndMonth = _month+1;
                for(uint i = _month+1; i< ZRE.length;i++){
                    ZRE[i].totalEligibleCount--;                
                }    
            }
            
        }
            
        require(msg.sender.send(totalAmount),"invalid transfer");
        
        users[msg.sender].zreEarnedETH += totalAmount;
        ZRE[_month].withdrawalDividend += totalAmount;
        users[msg.sender].totalETHEarnings += totalAmount;
        totalEarnedETH += totalAmount;
        
        emit ZREWithdrawal( msg.sender, _month, totalAmount, now);
    }
    
    
    function slapDistrubution(address _userAddress, uint _lastLDBIndex) internal {
        users[_userAddress].userSLAP[_lastLDBIndex].referralCount++;
 
        if(_userAddress != owner){
            if(users[_userAddress].userSLAP[_lastLDBIndex].referralCount >= 5){
                
                if((users[_userAddress].userLDBDays.length ==0) || (users[_userAddress].userLDBDays[users[_userAddress].userLDBDays.length-1] != _lastLDBIndex)) // current slap count
                    users[_userAddress].userLDBDays.push(_lastLDBIndex);
                    
                if(users[_userAddress].userSLAP[_lastLDBIndex].referralCount ==5){
                    users[_userAddress].userSLAP[_lastLDBIndex].slap = 1;
                    LDB[_lastLDBIndex].totalS1EligibleCount++;
                }
                else if(users[_userAddress].userSLAP[_lastLDBIndex].referralCount ==10){
                    users[_userAddress].userSLAP[_lastLDBIndex].slap = 2;
                    LDB[_lastLDBIndex].totalS2EligibleCount++;
                }
                else if(users[_userAddress].userSLAP[_lastLDBIndex].referralCount ==15){
                    users[_userAddress].userSLAP[_lastLDBIndex].slap = 3;
                    LDB[_lastLDBIndex].totalS3EligibleCount++;
                }
                else if(users[_userAddress].userSLAP[_lastLDBIndex].referralCount ==20){
                    users[_userAddress].userSLAP[_lastLDBIndex].slap = 4;
                    LDB[_lastLDBIndex].totalS4EligibleCount++;
                }
                else if(users[_userAddress].userSLAP[_lastLDBIndex].referralCount ==25){
                    users[_userAddress].userSLAP[_lastLDBIndex].slap = 5;
                    LDB[_lastLDBIndex].totalS5EligibleCount++;
                }
            }
        }
    }
    
    
    function updateA7Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].a7Matrix[level].referrals.push(userAddress);
        users[referrerAddress].a7Matrix[level].referralsCount++;
        
        if (users[referrerAddress].a7Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].a7Matrix[level].referrals.length), now);
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3, now);
        //close matrix
        users[referrerAddress].a7Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeA7Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].a7Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeA7Referrer(referrerAddress, level);
            if (users[referrerAddress].a7Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].a7Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].a7Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level, now);
            updateA7Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].a7Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level, now);
        }
    }

    function updateP7Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeP7Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].p7Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].p7Matrix[level].firstLevelReferrals.push(userAddress);
            users[referrerAddress].p7Matrix[level].referralsCount++;
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].p7Matrix[level].firstLevelReferrals.length), now);
            
            //set current level
            users[userAddress].p7Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].p7Matrix[level].currentReferrer;            
            users[ref].p7Matrix[level].secondLevelReferrals.push(userAddress); 
            users[ref].p7Matrix[level].referralsCount++;
            
            uint len = users[ref].p7Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].p7Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].p7Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].p7Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5, now);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6, now);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].p7Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].p7Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3, now);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4, now);
                }
            } else if (len == 2 && users[ref].p7Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].p7Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5, now);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6, now);
                }
            }

            return updateP7ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].p7Matrix[level].secondLevelReferrals.push(userAddress);
        users[referrerAddress].p7Matrix[level].referralsCount++;

        if (users[referrerAddress].p7Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].p7Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].p7Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].p7Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].p7Matrix[level].closedPart)) {

                updateP7(userAddress, referrerAddress, level, true);
                return updateP7ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].p7Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].p7Matrix[level].closedPart) {
                updateP7(userAddress, referrerAddress, level, true);
                return updateP7ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateP7(userAddress, referrerAddress, level, false);
                return updateP7ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].p7Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateP7(userAddress, referrerAddress, level, false);
            return updateP7ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].p7Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateP7(userAddress, referrerAddress, level, true);
            return updateP7ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].p7Matrix[level].firstLevelReferrals[0]].p7Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].p7Matrix[level].firstLevelReferrals[1]].p7Matrix[level].firstLevelReferrals.length) {
            updateP7(userAddress, referrerAddress, level, false);
        } else {
            updateP7(userAddress, referrerAddress, level, true);
        }
        
        updateP7ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateP7(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].p7Matrix[level].firstLevelReferrals[0]].p7Matrix[level].firstLevelReferrals.push(userAddress);
            users[users[referrerAddress].p7Matrix[level].firstLevelReferrals[0]].p7Matrix[level].referralsCount++;
            emit NewUserPlace(userAddress, users[referrerAddress].p7Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].p7Matrix[level].firstLevelReferrals[0]].p7Matrix[level].firstLevelReferrals.length), now);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].p7Matrix[level].firstLevelReferrals[0]].p7Matrix[level].firstLevelReferrals.length), now);
            //set current level
            users[userAddress].p7Matrix[level].currentReferrer = users[referrerAddress].p7Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].p7Matrix[level].firstLevelReferrals[1]].p7Matrix[level].firstLevelReferrals.push(userAddress);
            users[users[referrerAddress].p7Matrix[level].firstLevelReferrals[1]].p7Matrix[level].referralsCount++;
            emit NewUserPlace(userAddress, users[referrerAddress].p7Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].p7Matrix[level].firstLevelReferrals[1]].p7Matrix[level].firstLevelReferrals.length), now);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].p7Matrix[level].firstLevelReferrals[1]].p7Matrix[level].firstLevelReferrals.length), now);
            //set current level
            users[userAddress].p7Matrix[level].currentReferrer = users[referrerAddress].p7Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateP7ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].p7Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory x6 = users[users[referrerAddress].p7Matrix[level].currentReferrer].p7Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].p7Matrix[level].currentReferrer].p7Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].p7Matrix[level].currentReferrer].p7Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].p7Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].p7Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].p7Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeP7Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].p7Matrix[level].blocked = true;
        }

        users[referrerAddress].p7Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeP7Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level, now);
            updateP7Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level, now);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }
    
     /**
     * @dev Contract balance withdraw
     * @param _toUser  receiver addrress
     * @param _amount  withdraw amount
     */ 
    function failSafe(address payable _toUser, uint _amount) public returns (bool) {
        require(msg.sender == owner, "Only Owner Wallet");
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    }

    /**
     * @dev To lock/unlock the contract
     * @param _lockStatus  status in bool
     */
    function contractLock(bool _lockStatus) public returns (bool) {
        require(msg.sender == owner, "Invalid ownerWallet");

        lockStatus = _lockStatus;
        return true;
    }
    
    
    function findFreeA7Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeA7Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeP7Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeP7Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveA7Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeA7Levels[level];
    }

    function usersActiveP7Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeP7Levels[level];
    }

    function usersA7Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, uint, uint, bool) {
        return (users[userAddress].a7Matrix[level].currentReferrer,
                users[userAddress].a7Matrix[level].referrals,
                users[userAddress].a7Matrix[level].reinvestCount,
                users[userAddress].a7Matrix[level].referralsCount,
                users[userAddress].a7Matrix[level].blocked);
    }

    function usersp7Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, uint, bool, address) {
        return (users[userAddress].p7Matrix[level].currentReferrer,
                users[userAddress].p7Matrix[level].firstLevelReferrals,
                users[userAddress].p7Matrix[level].secondLevelReferrals,
                users[userAddress].p7Matrix[level].reinvestCount,
                users[userAddress].p7Matrix[level].blocked,
                users[userAddress].p7Matrix[level].closedPart);
    }
    
    function usersp7MatrixRefferalsCount(address userAddress, uint8 level) public view returns(uint){
        return users[userAddress].p7Matrix[level].referralsCount;
    }
    
    function usersLDBDays(address userAddress) public view returns(uint[] memory){
        return users[userAddress].userLDBDays;
    }
    
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function viewUserZREReceived(address _user, uint _month) public view returns(bool){
        return users[_user].userZREReceived[_month];   
    }
    
    function viewUserSLAP(address _user, uint _day) public view returns(uint , uint, bool){
        return (users[_user].userSLAP[_day].slap,users[_user].userSLAP[_day].referralCount,users[_user].userSLAP[_day].received);   
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].a7Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level, now);
                    isExtraDividends = true;
                    receiver = users[receiver].a7Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].p7Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level, now);
                    isExtraDividends = true;
                    receiver = users[receiver].p7Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        require(address(uint160(receiver)).send(levelPrice[level]),"amount transferred");
        users[receiver].totalETHEarnings += levelPrice[level];
        totalEarnedETH += levelPrice[level];
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level, now);
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}