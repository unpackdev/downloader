pragma solidity ^0.4.24;

contract QuantumSC {
  uint public quantityLevelsPool;
  address private ownerAddress;
  address private investorsAddress;
  address private adminAddress;
  uint public controllerUserId;

  struct LevelPool {
    uint level;
    bool status;
    uint price;
    uint reinvestments;
    mapping(uint => address[]) partners;
  }

  struct User {
    uint id;
    address userAddress;
    address sponsor;
    uint balance;
    mapping(uint => LevelPool) levelsPool;
  }

  mapping(address => User) public users;

  struct LevelManagerPool {
    uint usersQuantityController;
    uint currentTurnContoller;
    uint accumulateBalanceLevel;
    mapping(uint => address) userAddressForTurn;
  }

  mapping(uint => LevelManagerPool) public levelManagerPool;

  mapping(uint => uint) public levelPricesMigratePool;
  mapping(uint => uint) public buyLevelSurplusBalancePool;

  event UserRegisterEvent(address indexed user, uint id);
  event BuyLevelEvent(address indexed user, uint id, uint level);

  constructor() public {
    setInitialData();
    setTurnsPool();
    setLevelPricesMigrateAndSurplus();
    adminUsersRegistration(ownerAddress, true);
    adminUsersRegistration(investorsAddress, false);
  }

  function setLevelPricesMigrateAndSurplus() private {
    for (uint i = 1; i <= quantityLevelsPool; i++) {
      if (i == 1) {
        levelPricesMigratePool[i] = 0.04 ether;
      } else if(i == 2) {
        levelPricesMigratePool[i] = levelPricesMigratePool[i-1] * 2;
        buyLevelSurplusBalancePool[i] = 0.02 ether;
      } else {
        levelPricesMigratePool[i] = levelPricesMigratePool[i-1] * 2;
        buyLevelSurplusBalancePool[i] = buyLevelSurplusBalancePool[i-1] * 2;
      }
    }
  }

  function setInitialData() private {
    ownerAddress = msg.sender;
    investorsAddress = 0x0E5ae5a5CF40351A80c039CFA05266565bc0be62;
    adminAddress = 0x1c1399229ca9CB653f23fdE549bC3Ab79D8A9E7a;
    quantityLevelsPool = 13;
    controllerUserId = 0;
  }

  function setTurnsPool() private {
    for (uint i = 1; i <= quantityLevelsPool; i++) {
      levelManagerPool[i].usersQuantityController = 0;
      levelManagerPool[i].currentTurnContoller = 1;
      levelManagerPool[i].accumulateBalanceLevel = 0 ether;
    }
  }

  function adminUsersRegistration(address userAddress, bool isOwner) private {
    controllerUserId ++;
    for (uint j = 1; j <= quantityLevelsPool; j++) {
      levelManagerPool[j].usersQuantityController ++;
    }
    User memory temporaryUser = User(controllerUserId, userAddress, address(0), 0);
    users[userAddress] = temporaryUser;
    setDataLevelsPool(userAddress);
    for (uint k = 1; k <= quantityLevelsPool; k++) {
      users[userAddress].levelsPool[k].status = true;
    }
    for (uint i = 1; i <= quantityLevelsPool; i++) {
      if (isOwner) {
        levelManagerPool[i].userAddressForTurn[1] = userAddress;
      } else {
        levelManagerPool[i].userAddressForTurn[2] = userAddress;
      }
    }
  }

  function usersRegistration(address sponsor) public validUserRegistration(sponsor) payable {
    controllerUserId ++;
    levelManagerPool[1].usersQuantityController ++;
    User memory temporaryUser = User(controllerUserId, msg.sender, sponsor, 0);
    users[msg.sender] = temporaryUser;
    setDataLevelsPool(msg.sender);
    users[msg.sender].levelsPool[1].status = true;
    levelManagerPool[1].userAddressForTurn[levelManagerPool[1].usersQuantityController] = msg.sender;
    levelManagerPool[1].accumulateBalanceLevel += 0.04 ether;
    transferBalance(adminAddress, 0.03 ether);
    transferBalance(users[msg.sender].sponsor, 0.01 ether);
    validateStatusAllLevels(msg.sender, 1, true);
  }

  function validateStatusAllLevels(address userAddress, uint startLevel, bool isRegister) private {
    for (uint i = startLevel; i <= quantityLevelsPool; i++) {
      address turnAddress = levelManagerPool[i].userAddressForTurn[levelManagerPool[i].currentTurnContoller];
      uint lengthPartnersArray = users[turnAddress].levelsPool[i].partners[
        users[turnAddress].levelsPool[i].reinvestments
      ].length;
      uint acumulateBalanceInLevel = levelManagerPool[i].accumulateBalanceLevel;

      uint highestAccumulated = (levelPricesMigratePool[i] + levelPricesMigratePool[i]/2);
      
      if (
        (lengthPartnersArray == 0 && acumulateBalanceInLevel == levelPricesMigratePool[i]) ||
        (lengthPartnersArray == 0 && acumulateBalanceInLevel == highestAccumulated)
      ) {
        if (i == 1) {
          users[turnAddress].levelsPool[i].partners[users[turnAddress].levelsPool[i].reinvestments].push(
            userAddress
          );
        } else {
          users[turnAddress].levelsPool[i].partners[users[turnAddress].levelsPool[i].reinvestments].push(
            levelManagerPool[i].userAddressForTurn[levelManagerPool[i].usersQuantityController]
          );
        }

        transferBalance(turnAddress, (levelPricesMigratePool[i]*80)/100);
        
        if (users[turnAddress].id == 1 || users[turnAddress].id == 2) {
          transferBalance(ownerAddress, (levelPricesMigratePool[i]*20)/100);
        } else {
          transferBalance(users[turnAddress].sponsor, (levelPricesMigratePool[i]*20)/100);
        }

        if (acumulateBalanceInLevel == highestAccumulated) {
          levelManagerPool[i].accumulateBalanceLevel = levelPricesMigratePool[i]/2;
        } else {
          levelManagerPool[i].accumulateBalanceLevel = 0 ether;
        }
      } else if (
        (lengthPartnersArray == 1 && acumulateBalanceInLevel == levelPricesMigratePool[i]) ||
        (lengthPartnersArray == 1 && acumulateBalanceInLevel == highestAccumulated)
      ) {
        if (i == 1) {
          users[turnAddress].levelsPool[i].partners[users[turnAddress].levelsPool[i].reinvestments].push(
            userAddress
          );
        } else {
          users[turnAddress].levelsPool[i].partners[users[turnAddress].levelsPool[i].reinvestments].push(
            levelManagerPool[i].userAddressForTurn[levelManagerPool[i].usersQuantityController]
          );
        }
        
        if (i < 13) {
          levelManagerPool[i+1].accumulateBalanceLevel += levelPricesMigratePool[i];
        } else {
          transferBalance(adminAddress, levelPricesMigratePool[i]);
        }

        if (acumulateBalanceInLevel == highestAccumulated) {
          levelManagerPool[i].accumulateBalanceLevel = levelPricesMigratePool[i]/2;
        } else {
          levelManagerPool[i].accumulateBalanceLevel = 0 ether;
        }
      } else if (
        (lengthPartnersArray == 2 && acumulateBalanceInLevel == levelPricesMigratePool[i]) ||
        (lengthPartnersArray == 2 && acumulateBalanceInLevel == highestAccumulated)
      ) {
        if (i == 1) {
          users[turnAddress].levelsPool[i].partners[users[turnAddress].levelsPool[i].reinvestments].push(
            userAddress
          );
        } else {
          users[turnAddress].levelsPool[i].partners[users[turnAddress].levelsPool[i].reinvestments].push(
            levelManagerPool[i].userAddressForTurn[levelManagerPool[i].usersQuantityController]
          );
        }
        
        if (i < 13) {
          levelManagerPool[i+1].accumulateBalanceLevel += levelPricesMigratePool[i];
          users[turnAddress].levelsPool[i+1].status = true;
          levelManagerPool[i+1].usersQuantityController ++;
          levelManagerPool[i+1].userAddressForTurn[levelManagerPool[i+1].usersQuantityController] = turnAddress;
          levelManagerPool[i].currentTurnContoller ++;
        } else {
          transferBalance(adminAddress, levelPricesMigratePool[i]);
        }

        if (acumulateBalanceInLevel == highestAccumulated) {
          levelManagerPool[i].accumulateBalanceLevel = levelPricesMigratePool[i]/2;
        } else {
          levelManagerPool[i].accumulateBalanceLevel = 0 ether;
        }

        users[turnAddress].levelsPool[i].reinvestments ++;
      }
    }

    if (isRegister) {
      emit UserRegisterEvent(userAddress, users[userAddress].id);
    } else {
      emit BuyLevelEvent(userAddress, users[userAddress].id, startLevel);
    }
  }
  
  function buyLevelPool(uint level) public validLevelBuy(level) payable {
    levelManagerPool[level].usersQuantityController ++;
    users[msg.sender].levelsPool[level].status = true;
    levelManagerPool[level].userAddressForTurn[levelManagerPool[level].usersQuantityController] = msg.sender;
    levelManagerPool[level].accumulateBalanceLevel += levelPricesMigratePool[level];
    transferBalance(users[msg.sender].sponsor, buyLevelSurplusBalancePool[level]);
    validateStatusAllLevels(msg.sender, level, false);
  }

  function setDataLevelsPool(address userAddress) private {
    uint price = 0.05 ether;

    for (uint i = 1; i <= quantityLevelsPool; i++) {
      if (i > 1) {
        price = price * 2;
      }

      users[userAddress].levelsPool[i].level = i;
      users[userAddress].levelsPool[i].status = false;
      users[userAddress].levelsPool[i].price = price;
      users[userAddress].levelsPool[i].reinvestments = 1;
    }
  }

  function validateUserExists(address userAddress) public view returns(bool) {
    return (users[userAddress].id != 0);
  }

  function transferBalance(address transferAddress, uint amount) private {
    transferAddress.transfer(amount);
    users[transferAddress].balance += amount;
  }

  function getDataLevel(address myAddress, uint level, uint reivestment) public view returns(uint, bool, uint, uint, address[]) {
    return (
      users[myAddress].levelsPool[level].level,
      users[myAddress].levelsPool[level].status,
      users[myAddress].levelsPool[level].price,
      users[myAddress].levelsPool[level].reinvestments,
      users[myAddress].levelsPool[level].partners[reivestment]
    );
  }

  function getTurnUser(uint level) public view returns(address) {
    return (
      levelManagerPool[level].userAddressForTurn[levelManagerPool[level].currentTurnContoller]
    );
  }

  modifier validUserRegistration(address sponsor) {
    require(msg.value == 0.08 ether, "0.08 ether is required");
    require(validateUserExists(sponsor), "Sponsor does not exists");
    require(!(validateUserExists(msg.sender)), "User already exists");
    _;
  }

  modifier validLevelBuy(uint level) {
    require((level > 0 && level <= quantityLevelsPool), "The level does not exist");
    require(validateUserExists(msg.sender), "Invalid user");
    require(!users[msg.sender].levelsPool[level].status, "Level already purchased");
    if (level > 1) { require(users[msg.sender].levelsPool[level - 1].status, "Can not buy this level"); }
    require(msg.value == users[msg.sender].levelsPool[level].price, "Value level purchase does not match");
    _;
  }
  
  function getAccumulateBalanceContract() public view returns(uint) {
    return address(this).balance;
  }
  
  function sendToOwnerAccumulateBalanceContract() validateIsOwner() public {
    ownerAddress.transfer(address(this).balance);
  }

  modifier validateIsOwner() {
    require((msg.sender == ownerAddress), "This action in only allowed for owner");
    _;
  }
}