pragma solidity >=0.4.22 <0.7.0;

contract SuperStar {
    struct UserDetail {
        uint256 id;
        uint256 userIncome;
        uint256 walletIncome;
        address payable referrer;
        mapping (uint8 => LevelDetail) levels;
        mapping (uint8 => bool) systemActiveStatus;
        mapping (uint8 => bool) slotActiveStatus;
        mapping (uint8 => CycleDetail) slotCycle;
    }
    
    struct LevelDetail {
        mapping (uint8 => uint256) slotLevelReferrals;
    }
    
    struct CycleDetail {
        uint256 cycleCount;
        uint256 cycleIncome;
        uint256 cycleWalletTransfer;
    }
    
    uint256 public currentUserId = 1;
    uint256 public totalIncome;
    address payable public owner;
    address payable referrerLevelOne;
    address payable referrerLevelTwo;
    address payable referrerLevelThree;
    address payable referrerLevelFour;
    address payable referrerLevelFive;
    address payable freeReferrer;
    address payable private partnerOne = 0xCAFb395f6A9b42349a1F18936FbaaC0Bbe9d43d2;
    address payable private partnerTwo = 0x474ccddf9540DDEFbA42C8C75e56427C95c04BE4;
    address payable private partnerThree = 0xd7e8Bf9329911DeA6f03E07614357A038A0bAf27;
    address payable private partnerFour = 0x0D3942A0e50C1bE07DE715e5F4aB222677f35814;
    address payable private partnerFive = 0x73414C32d05Efede19843aa283E26D28b2872E9D;
    address payable private partnerSix = 0x45D55c8f040CA8A2de6ca2b4455a02A6C057322F;
    address payable private partnerSeven = 0xe1544787B104F749dF01d3bE4Ec2Dc667A07ED7A;
    address payable private partnerEight = 0x42a42Cd7bDC05Ca414a32572B5e7BFac9B29FEb1;
    mapping (address => UserDetail) users;
    mapping (uint256 => address payable) public userIds;
    mapping (address => uint256) public addressToId;
    mapping (uint8 => uint256) slotInvestment;
    mapping (uint8 => uint256) slotMembershipFees;
    
    event Registration(address indexed userAddress, address referrerAddress, uint256 indexed userId, uint256 indexed referrerId);
    event SlotPurchased(address indexed userAddress, uint8 slot);
    event LevelIncome(address from, address indexed receiver, uint256 income, uint8 level, uint8 slot, uint256 levelReferralCount);
    event SystemSwitched(address indexed userAddress, uint256 id);
    event Reinvest(address indexed userAddress, uint256 userId, uint8 slot, uint256 cycleCount);
    
    
    constructor(address payable ownerAddress) public {
        owner = ownerAddress;
        slotInvestment[1] = 0.05 ether;
        slotInvestment[2] = 0.13 ether;
        slotInvestment[3] = 0.39 ether;
        slotInvestment[4] = 0.78 ether;
        slotInvestment[5] = 1.29 ether;
        slotInvestment[6] = 3.86 ether;
        slotInvestment[7] = 7.69 ether;
        slotInvestment[8] = 12.81 ether;
        slotInvestment[9] = 17.99 ether;
        slotInvestment[10] = 25.70 ether;
       
        slotMembershipFees[1] = 0.02 ether;
        slotMembershipFees[2] = 0.03 ether;
        slotMembershipFees[3] = 0.04 ether;
        slotMembershipFees[4] = 0.04 ether;
        slotMembershipFees[5] = 0.05 ether;
        slotMembershipFees[6] = 0.06 ether;
        slotMembershipFees[7] = 0.12 ether;
        slotMembershipFees[8] = 0.30 ether;
        slotMembershipFees[9] = 0.50 ether;
        slotMembershipFees[10] = 0.80 ether;
        
        
        
        UserDetail memory user = UserDetail({
            id: currentUserId,
            userIncome: uint256(0),
            walletIncome: uint256(0),
            referrer: address(0)
        });
        
        users[owner] = user;
        userIds[currentUserId] = owner;
        addressToId[owner] = currentUserId;
        currentUserId++;
        users[owner].systemActiveStatus[1] = true;
        
        emit Registration(owner, users[owner].referrer, users[owner].id, uint256(0));
        
        for (uint8 i=0; i<=10; i++) {
            users[owner].slotActiveStatus[i] = true;
            emit SlotPurchased(owner, i);
        }
    }
    
    function registration(address payable referrerAddress) external payable {
        require(msg.value == 0.05 ether, "registration amount is 0.05 ether");
        require(!isUserExists(msg.sender), "user already exists");
        require(isUserExists(referrerAddress), "referrer doesn't exists");
        
        UserDetail memory user = UserDetail({
            id: currentUserId,
            userIncome: uint256(0),
            walletIncome: uint256(0),
            referrer: referrerAddress
        });
        
        users[msg.sender] = user;
        userIds[currentUserId] = msg.sender;
        addressToId[msg.sender] = currentUserId;
        currentUserId++;
        users[msg.sender].systemActiveStatus[1] = true;
        levelIncome(msg.sender, referrerAddress, 0);
        membershipFeesDistribution(0);
        
        emit Registration(msg.sender, referrerAddress, users[msg.sender].id, users[referrerAddress].id);
        emit SlotPurchased(msg.sender, 0);
        
        totalIncome += msg.value;
        
    }
    
    function purchaseSlot(uint8 slot) external payable {
        UserDetail storage user = users[msg.sender];
        require(slot > 1 && slot <=10, "Invalid slot number");
        require(!user.slotActiveStatus[slot], "Slot already activated");
        require(user.systemActiveStatus[2], "system 2 is not active yet");
        require(msg.value == (slotInvestment[slot] + slotMembershipFees[slot]));
        user.slotActiveStatus[slot] = true;
        
        levelIncome(msg.sender, user.referrer, slot);
        membershipFeesDistribution(slot);
        
        emit SlotPurchased(msg.sender, slot);
        
        totalIncome += msg.value;
        
    }
    
    function levelIncome(address userAddress, address payable referrerAddress, uint8 slot) private {
        uint256 investment;
        
        if (slot == 0) {
            investment = 0.03 ether;
        } else {
            investment = slotInvestment[slot];
        }
        
        uint256 investmentLevelOne = investment * 50/100;
        uint256 investmentLevelTwo = investment * 20/100;
        uint256 investmentLevelThree = investment * 15/100;
        uint256 investmentLevelFour = investment * 10/100;
        uint256 investmentLevelFive = investment * 5/100;
        
        referrerLevelOne = referrerAddress;
        referrerLevelTwo = users[referrerLevelOne].referrer;
        referrerLevelThree = users[referrerLevelTwo].referrer;
        referrerLevelFour = users[referrerLevelThree].referrer;
        referrerLevelFive = users[referrerLevelFour].referrer;
        
        if (referrerLevelOne != address(0)) {
            UserDetail storage user = users[referrerLevelOne];
            if (user.systemActiveStatus[1]) {
                user.userIncome += investmentLevelOne;
                user.levels[slot].slotLevelReferrals[1]++;
                emit LevelIncome(userAddress, referrerLevelOne, investmentLevelOne, 1, slot, user.levels[slot].slotLevelReferrals[1]);
                canSwitchSystem(userAddress, referrerLevelOne);
            } else {
                if (slot == 0) {
                    slot =1;
                }
                user.userIncome += investmentLevelOne;
                user.slotCycle[slot].cycleIncome += investmentLevelOne;
                user.levels[slot].slotLevelReferrals[1]++;
                emit LevelIncome(userAddress, referrerLevelOne, investmentLevelOne, 1, slot, user.levels[slot].slotLevelReferrals[1]);
                slotCycleUpdate(userAddress, referrerLevelOne, slot);
            }
        }
        
        if (referrerLevelTwo != address(0)) {
            UserDetail storage user = users[referrerLevelTwo];
            if (user.systemActiveStatus[1]) {
                user.userIncome += investmentLevelTwo;
                user.levels[slot].slotLevelReferrals[2]++;
                emit LevelIncome(userAddress, referrerLevelTwo, investmentLevelTwo, 2, slot, user.levels[slot].slotLevelReferrals[2]);
                canSwitchSystem(userAddress, referrerLevelTwo);
            } else {
                if (slot == 0) {
                    slot =1;
                }
                user.userIncome += investmentLevelTwo;
                user.slotCycle[slot].cycleIncome += investmentLevelTwo;
                user.levels[slot].slotLevelReferrals[2]++;
                emit LevelIncome(userAddress, referrerLevelTwo, investmentLevelTwo, 2, slot, user.levels[slot].slotLevelReferrals[2]);
                slotCycleUpdate(userAddress, referrerLevelTwo, slot);
            }
        }
        
        if (referrerLevelThree != address(0)) {
            UserDetail storage user = users[referrerLevelThree];
            if (user.systemActiveStatus[1]) {
                user.userIncome += investmentLevelThree;
                user.levels[slot].slotLevelReferrals[3]++;
                emit LevelIncome(userAddress, referrerLevelThree, investmentLevelThree, 3, slot, user.levels[slot].slotLevelReferrals[3]);
                canSwitchSystem(userAddress, referrerLevelThree);   
            } else {
                if (slot == 0) {
                    slot =1;
                }
                user.userIncome += investmentLevelThree;
                user.slotCycle[slot].cycleIncome += investmentLevelThree;
                user.levels[slot].slotLevelReferrals[3]++;
                emit LevelIncome(userAddress, referrerLevelThree, investmentLevelThree, 3, slot, user.levels[slot].slotLevelReferrals[3]);
                slotCycleUpdate(userAddress, referrerLevelThree, slot);
            }
        }
        
        if (referrerLevelFour != address(0)) {
            UserDetail storage user = users[referrerLevelFour];
            if (user.systemActiveStatus[1]) {
                user.userIncome += investmentLevelFour;
                user.levels[slot].slotLevelReferrals[4]++;
                emit LevelIncome(userAddress, referrerLevelFour, investmentLevelFour, 4, slot, user.levels[slot].slotLevelReferrals[4]);
                canSwitchSystem(userAddress, referrerLevelFour);
            } else {
                if (slot == 0) {
                    slot =1;
                }
                user.userIncome += investmentLevelFour;
                user.slotCycle[slot].cycleIncome += investmentLevelFour;
                user.levels[slot].slotLevelReferrals[4]++;
                emit LevelIncome(userAddress, referrerLevelFour, investmentLevelFour, 4, slot, user.levels[slot].slotLevelReferrals[4]);
                slotCycleUpdate(userAddress, referrerLevelFour, slot);
            }
        }
        
        if (referrerLevelFive != address(0)) {
            UserDetail storage user = users[referrerLevelFive];
            if (user.systemActiveStatus[1]) {
                user.userIncome += investmentLevelFive;
                user.levels[slot].slotLevelReferrals[5]++;
                emit LevelIncome(userAddress, referrerLevelFive, investmentLevelFive, 5, slot, user.levels[slot].slotLevelReferrals[5]);
                canSwitchSystem(userAddress, referrerLevelFive);
            } else {
                if (slot == 0) {
                    slot =1;
                }
                user.userIncome += investmentLevelFive;
                user.slotCycle[slot].cycleIncome += investmentLevelFive;
                user.levels[slot].slotLevelReferrals[5]++;
                emit LevelIncome(userAddress, referrerLevelFive, investmentLevelFive, 5, slot, user.levels[slot].slotLevelReferrals[5]);
                slotCycleUpdate(userAddress, referrerLevelFive, slot);
            }
        }
    }   
    
    function membershipFeesDistribution(uint8 slot) private {
         uint256 fees;
         
        if (slot == 0) {
            fees = 0.02 ether;
        } else {
            fees = slotMembershipFees[slot];
        }
        partnerOne.transfer(fees * 20/100);
        partnerTwo.transfer(fees * 125/1000);
        partnerThree.transfer(fees * 125/1000);
        partnerFour.transfer(fees * 10/100);
        partnerFive.transfer(fees * 10/100);
        partnerSix.transfer(fees * 10/100);
        partnerSeven.transfer(fees * 10/100);
        partnerEight.transfer(fees * 15/100);
        
    }
    
    function canSwitchSystem(address userAddress, address payable referrerAddress) private {
        
        uint256 systemThreshold = slotInvestment[1] + slotMembershipFees[1];
        UserDetail storage user = users[referrerAddress];
        require(user.systemActiveStatus[1], "system already switched to S2");// check this condition.
        if (user.userIncome >= systemThreshold) {
            referrerAddress.transfer(user.userIncome - systemThreshold);
            user.walletIncome += (user.userIncome - systemThreshold);
            levelIncome(userAddress, user.referrer, 1);
            membershipFeesDistribution(1);
            user.systemActiveStatus[1] = false;
            user.systemActiveStatus[2] = true;
            
            emit SystemSwitched(referrerAddress, users[referrerAddress].id);
            emit SlotPurchased(referrerAddress, 1);
        }
    }
    
    function slotCycleUpdate(address userPlaced, address payable userAddress, uint8 slot) private {
        UserDetail storage user = users[userAddress];
        
        if (slot == 0) {
            slot = 1;
        }
        
        uint256 cycleThreshold = (slotInvestment[slot] * 3);
        uint256 cycleCompletionRewards = cycleThreshold * 20/100;
        uint256 slotRepurchaseCost = slotInvestment[slot] + slotMembershipFees[slot];
        uint256 walletTransfer = (user.slotCycle[slot].cycleIncome - (cycleCompletionRewards + slotRepurchaseCost + user.slotCycle[slot].cycleWalletTransfer));
        
        if (user.slotCycle[slot].cycleIncome >= (cycleCompletionRewards + slotRepurchaseCost)) {
            userAddress.transfer(walletTransfer);
            user.walletIncome += walletTransfer;
            user.slotCycle[slot].cycleWalletTransfer += walletTransfer;
            
        }
        
        if (user.slotCycle[slot].cycleIncome >= cycleThreshold) {
            
            freeReferrer = nextFreeReferrer(userAddress, slot);
            if (freeReferrer != address(0)) {
                users[freeReferrer].userIncome += cycleCompletionRewards;
                users[freeReferrer].walletIncome += cycleCompletionRewards;
                freeReferrer.transfer(cycleCompletionRewards);
            }
            
            user.slotCycle[slot].cycleIncome = 0;
            user.slotCycle[slot].cycleWalletTransfer = 0;
            user.slotCycle[slot].cycleCount++;
            membershipFeesDistribution(slot);
            
            emit Reinvest(userAddress, user.id, slot, user.slotCycle[slot].cycleCount);
            
        }
    }
    
    function nextFreeReferrer(address payable userAddress, uint8 slot) public view returns(address payable) {
        while (userAddress != owner) {
            if (users[users[userAddress].referrer].slotActiveStatus[slot]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
            return address(0);
    }
    
    function isUserExists(address userAddress) public view returns (bool) {
        return (users[userAddress].id != 0);
    }
    
    function getUserDetails(uint id, uint8 slot) public view returns (uint256 userIncome, uint256 cycleIncome, uint256 walletIncome, bool systemOneStatus, bool systemTwoStatus) {
        return (
            users[userIds[id]].userIncome,
            users[userIds[id]].slotCycle[slot].cycleIncome,
            users[userIds[id]].walletIncome,
            users[userIds[id]].systemActiveStatus[1],
            users[userIds[id]].systemActiveStatus[2]
            );
    }
}