/*
*
*         ███████╗████████╗██╗  ██╗███████╗██████╗ ███╗   ███╗ █████╗ ███████╗███████╗    ██████╗     ██████╗ 
*         ██╔════╝╚══██╔══╝██║  ██║██╔════╝██╔══██╗████╗ ████║██╔══██╗╚══███╔╝██╔════╝    ╚════██╗   ██╔═████╗
*         █████╗     ██║   ███████║█████╗  ██████╔╝██╔████╔██║███████║  ███╔╝ █████╗       █████╔╝   ██║██╔██║
*         ██╔══╝     ██║   ██╔══██║██╔══╝  ██╔══██╗██║╚██╔╝██║██╔══██║ ███╔╝  ██╔══╝      ██╔═══╝    ████╔╝██║
*         ███████╗   ██║   ██║  ██║███████╗██║  ██║██║ ╚═╝ ██║██║  ██║███████╗███████╗    ███████╗██╗╚██████╔╝
*         ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚══════╝╚═╝ ╚═════╝ 
* 
*                                                           888                                   888            d8b          
*                                                           888                                   888            Y8P          
*                                                           888                                   888                         
* 888  888  .d88b.  888  888 888d888       88888b.   .d88b.  888888 888  888  888  .d88b.  888d888 888  888       888 .d8888b  
* 888  888 d88""88b 888  888 888P"         888 "88b d8P  Y8b 888    888  888  888 d88""88b 888P"   888 .88P       888 88K      
* 888  888 888  888 888  888 888           888  888 88888888 888    888  888  888 888  888 888     888888K        888 "Y8888b. 
* Y88b 888 Y88..88P Y88b 888 888           888  888 Y8b.     Y88b.  Y88b 888 d88P Y88..88P 888     888 "88b       888      X88 
*  "Y88888  "Y88P"   "Y88888 888           888  888  "Y8888   "Y888  "Y8888888P"   "Y88P"  888     888  888       888  88888P' 
*      888                                                                                                                     
* Y8b d88P                                                                                                                     
*  "Y88P"                                                                                                                      
*                                                           888                                         888    888      
*                                                           888                                         888    888      
*                                                           888                                         888    888      
* 888  888  .d88b.  888  888 888d888       88888b.   .d88b.  888888       888  888  888  .d88b.  888d888 888888 88888b.  
* 888  888 d88""88b 888  888 888P"         888 "88b d8P  Y8b 888          888  888  888 d88""88b 888P"   888    888 "88b 
* 888  888 888  888 888  888 888           888  888 88888888 888          888  888  888 888  888 888     888    888  888 
* Y88b 888 Y88..88P Y88b 888 888           888  888 Y8b.     Y88b.        Y88b 888 d88P Y88..88P 888     Y88b.  888  888 
*  "Y88888  "Y88P"   "Y88888 888           888  888  "Y8888   "Y888        "Y8888888P"   "Y88P"  888      "Y888 888  888 
*      888                                                                                                               
* Y8b d88P                                                                                                               
*  "Y88P"                                                                                                                
*
* Improved version 
*/

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
}


contract Ethermaze {
    using SafeMath for uint256;

    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint currentLevel;
        uint totalEarningEth;
        address[] referral;
        mapping(uint => uint) levelExpired;
    }
    
    Ethermaze public oldETHMaze;
    uint oldETHMazeId = 1;
    address public ownerAddress;
    uint public adminFee = 1 ether;
    uint public currentId = 0;
    uint public PERIOD_LENGTH = 100 days;
    uint referrer1Limit = 2;
    bool public lockStatus;
    
    mapping (uint => uint) public LEVEL_PRICE;
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (address => mapping (uint => uint)) public EarnedEth;
    mapping (address => uint) public loopCheck;
    mapping (address => uint) public createdDate;
    
    event regLevelEvent(address indexed UserAddress, address indexed ReferrerAddress, uint Time);
    event buyLevelEvent(address indexed UserAddress, uint Levelno, uint Time);
    event getMoneyForLevelEvent(address indexed UserAddress, uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);
    event lostMoneyForLevelEvent(address indexed UserAddress, uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);    
    
    constructor() public {
        ownerAddress = msg.sender;
        
        oldETHMaze = Ethermaze(0xa76bd82432259B36C6D4Df53B2bDc8b003632720);
        
        LEVEL_PRICE[1] = 0.06 ether;
        LEVEL_PRICE[2] = 0.1 ether;
        LEVEL_PRICE[3] = 0.3 ether;
        LEVEL_PRICE[4] = 0.5 ether;
        LEVEL_PRICE[5] = 1 ether;
        LEVEL_PRICE[6] = 3 ether;
        LEVEL_PRICE[7] = 7 ether;
        LEVEL_PRICE[8] = 10 ether;
        LEVEL_PRICE[9] = 15 ether;
        LEVEL_PRICE[10] = 25 ether;
        LEVEL_PRICE[11] = 31 ether;
        LEVEL_PRICE[12] = 40 ether;
        
        UserStruct memory userStruct;
        currentId = currentId.add(1);

        userStruct = UserStruct({
            isExist: true,
            id: currentId,
            referrerID: 0,
            currentLevel:1,
            totalEarningEth:0,
            referral: new address[](0)
        });
        users[ownerAddress] = userStruct;
        userList[currentId] = ownerAddress;

        for(uint i = 1; i <= 12; i++) {
            users[ownerAddress].currentLevel = i;
            users[ownerAddress].levelExpired[i] = 55555555555;
        }
    } 

    /**
     * @dev User registration
     */ 
    function regUser(uint _referrerID) external payable {
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist == false, "User exist");
        require(_referrerID > 0 && _referrerID <= currentId, "Incorrect referrer Id");
        require(msg.value == LEVEL_PRICE[1], "Incorrect Value");
        
        if (users[userList[_referrerID]].referral.length >= referrer1Limit) 
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;

        UserStruct memory userStruct;
        currentId++;
        
        userStruct = UserStruct({
            isExist: true,
            id: currentId,
            referrerID: _referrerID,
            currentLevel: 1,
            totalEarningEth:0,
            referral: new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currentId] = msg.sender;
        users[msg.sender].levelExpired[1] = block.timestamp.add(PERIOD_LENGTH);
        users[userList[_referrerID]].referral.push(msg.sender);
        loopCheck[msg.sender] = 0;
        createdDate[msg.sender] = block.timestamp;

        payForLevel(0, 1, msg.sender, ((LEVEL_PRICE[1].mul(adminFee)).div(10**20)), msg.value);

        emit regLevelEvent(msg.sender, userList[_referrerID], block.timestamp);
    }
    
    /**
     * @dev To buy the next level by User
     */ 
    function buyLevel(uint256 _level) external payable {
        require(lockStatus == false, "Contract Locked");
        require(users[msg.sender].isExist, "User not exist"); 
        require(_level > 0 && _level <= 12, "Incorrect level");

        if (_level == 1) {
            require(msg.value == LEVEL_PRICE[1], "Incorrect Value");
            users[msg.sender].levelExpired[1] = users[msg.sender].levelExpired[1].add(PERIOD_LENGTH);
            users[msg.sender].currentLevel = 1;
        } else {
            require(msg.value == LEVEL_PRICE[_level], "Incorrect Value");
            users[msg.sender].currentLevel = _level;
            /*for (uint i = _level - 1; i > 0; i--) */
            require(users[msg.sender].levelExpired[_level - 1] >= block.timestamp, "Buy the previous level");
            
            if (users[msg.sender].levelExpired[_level] == 0)
                users[msg.sender].levelExpired[_level] = block.timestamp.add(PERIOD_LENGTH);
            else 
                users[msg.sender].levelExpired[_level] = users[msg.sender].levelExpired[_level].add(PERIOD_LENGTH);
        }
        loopCheck[msg.sender] = 0;
       
        payForLevel(0, _level, msg.sender, ((LEVEL_PRICE[_level].mul(adminFee)).div(10**20)), msg.value);

        emit buyLevelEvent(msg.sender, _level, block.timestamp);
    }
    
    /**
     * @dev Internal function for payment
     */ 
     
    function payForLevel(uint _flag, uint _level, address _userAddress, uint _adminPrice, uint256 _amt) internal {
        address[6] memory referer;
        
        if (_flag == 0) {
            if (_level == 1 || _level == 7) {
                referer[0] = userList[users[_userAddress].referrerID];
            } else if (_level == 2 || _level == 8) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[0] = userList[users[referer[1]].referrerID];
            } else if (_level == 3 || _level == 9) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[0] = userList[users[referer[2]].referrerID];
            } else if (_level == 4 || _level == 10) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[3] = userList[users[referer[2]].referrerID];
                referer[0] = userList[users[referer[3]].referrerID];
            } else if (_level == 5 || _level == 11) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[3] = userList[users[referer[2]].referrerID];
                referer[4] = userList[users[referer[3]].referrerID];
                referer[0] = userList[users[referer[4]].referrerID];
            } else if (_level == 6 || _level == 12) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[3] = userList[users[referer[2]].referrerID];
                referer[4] = userList[users[referer[3]].referrerID];
                referer[5] = userList[users[referer[4]].referrerID];
                referer[0] = userList[users[referer[5]].referrerID];
            }
        } else if (_flag == 1) {
            referer[0] = userList[users[_userAddress].referrerID];
        }
        if (!users[referer[0]].isExist) referer[0] = userList[1];
        
        if (loopCheck[msg.sender] >= 12) {
            referer[0] = userList[1];
        }
        if (users[referer[0]].levelExpired[_level] >= block.timestamp) {
          
            // transactions 
            require((address(uint160(referer[0])).send(LEVEL_PRICE[_level].sub(_adminPrice))) && 
                    (address(uint160(ownerAddress)).send(_adminPrice)), "Transaction Failure");
           
            users[referer[0]].totalEarningEth = users[referer[0]].totalEarningEth.add(LEVEL_PRICE[_level].sub(_adminPrice));
            EarnedEth[referer[0]][_level] = EarnedEth[referer[0]][_level].add(LEVEL_PRICE[_level].sub(_adminPrice));
          
            emit getMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level, LEVEL_PRICE[_level].sub(_adminPrice), block.timestamp);
        } else {
            if (loopCheck[msg.sender] < 12) {
                loopCheck[msg.sender] = loopCheck[msg.sender].add(1);

            emit lostMoneyForLevelEvent(msg.sender, users[msg.sender].id, referer[0], users[referer[0]].id, _level, LEVEL_PRICE[_level].sub(_adminPrice),block.timestamp);
                
            payForLevel(1, _level, referer[0], _adminPrice, _amt);
            }
        }
    }

    /**
     * @dev Update old contract data
     */ 
    function oldETHMazeSync(uint limit) public {
        require(address(oldETHMaze) != address(0), "Initialize closed");
        require(msg.sender == ownerAddress, "Access denied");
        
        for (uint i = 0; i <= limit; i++) {
            UserStruct  memory olduser;
            address oldusers = oldETHMaze.userList(oldETHMazeId);
            (olduser.isExist, 
            olduser.id, 
            olduser.referrerID, 
            olduser.currentLevel,  
            olduser.totalEarningEth) = oldETHMaze.users(oldusers);
            address ref = oldETHMaze.userList(olduser.referrerID);

            if (olduser.isExist) {
                if (!users[oldusers].isExist) {
                    users[oldusers].isExist = true;
                    users[oldusers].id = oldETHMazeId;
                    users[oldusers].referrerID = olduser.referrerID;
                    users[oldusers].currentLevel = olduser.currentLevel;
                    users[oldusers].totalEarningEth = olduser.totalEarningEth;
                    userList[oldETHMazeId] = oldusers;
                    users[ref].referral.push(oldusers);
                    createdDate[oldusers] = block.timestamp;
                    
                    emit regLevelEvent(oldusers, ref, block.timestamp);
                    
                    for (uint j = 1; j <= 12; j++) {
                        users[oldusers].levelExpired[j] = oldETHMaze.viewUserLevelExpired(oldusers, j).add(50 days);
                        EarnedEth[oldusers][j] = oldETHMaze.EarnedEth(oldusers, j);
                    } 
                }
                oldETHMazeId++;
            } else {
                currentId = oldETHMazeId.sub(1);
                break;
                
            }
        }
    }
    
    
    /**
     * @dev Close old contract interaction
     */ 
    function oldETHMazeSyncClosed() external {
        require(address(oldETHMaze) != address(0), "Initialize already closed");
        require(msg.sender == ownerAddress, "Access denied");

        oldETHMaze = Ethermaze(0);
    }
    


    /**
     * @dev Contract balance withdraw
     */ 
    function failSafe(address payable _toUser, uint _amount) public returns (bool) {
        require(msg.sender == ownerAddress, "only Owner Wallet");
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    }
            
    /**
     * @dev Update admin fee percentage
     */ 
    function updateFeePercentage(uint256 _adminFee) public returns (bool) {
        require(msg.sender == ownerAddress, "only OwnerWallet");

        adminFee = _adminFee;
        return true;  
    }
    
    /**
     * @dev Update level price
     */ 
    function updatePrice(uint _level, uint _price) public returns (bool) {
        require(msg.sender == ownerAddress, "only OwnerWallet");

        LEVEL_PRICE[_level] = _price;
        return true;
    }

    /**
     * @dev Update contract status
     */ 
    function contractLock(bool _lockStatus) public returns (bool) {
        require(msg.sender == ownerAddress, "Invalid User");

        lockStatus = _lockStatus;
        return true;
    }

        
    /**
     * @dev View free Referrer Address
     */ 
    function findFreeReferrer(address _userAddress) public view returns (address) {
        if (users[_userAddress].referral.length < referrer1Limit) 
            return _userAddress;

        address[] memory referrals = new address[](254);
        referrals[0] = users[_userAddress].referral[0];
        referrals[1] = users[_userAddress].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint i = 0; i < 254; i++) { 
            if (users[referrals[i]].referral.length == referrer1Limit) {
                if (i < 126) {
                    referrals[(i+1)*2] = users[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].referral[1];
                }
            } else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, "No Free Referrer");
        return freeReferrer;
    }
    
    /**
     * @dev Total earned ETH
     */
    function getTotalEarnedEther() public view returns (uint) {
        uint totalEth;
        for (uint i = 1; i <= currentId; i++) {
            totalEth = totalEth.add(users[userList[i]].totalEarningEth);
        }
        return totalEth;
    }
        
   /**
     * @dev View referrals
     */ 
    function viewUserReferral(address _userAddress) external view returns (address[] memory) {
        return users[_userAddress].referral;
    }
    
    /**
     * @dev View level expired time
     */ 
    function viewUserLevelExpired(address _userAddress,uint _level) external view returns (uint) {
        return users[_userAddress].levelExpired[_level];
    }

    // fallback
    function () external payable {
        revert("Invalid Transaction");
    }
}