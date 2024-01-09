// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./console.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";


//  /$$      /$$                       /$$                                   /$$$$$$$                     
// | $$$    /$$$                      | $$                                  | $$__  $$                    
// | $$$$  /$$$$ /$$   /$$  /$$$$$$$ /$$$$$$    /$$$$$$   /$$$$$$  /$$   /$$| $$  \ $$  /$$$$$$  /$$   /$$
// | $$ $$/$$ $$| $$  | $$ /$$_____/|_  $$_/   /$$__  $$ /$$__  $$| $$  | $$| $$$$$$$  /$$__  $$|  $$ /$$/
// | $$  $$$| $$| $$  | $$|  $$$$$$   | $$    | $$$$$$$$| $$  \__/| $$  | $$| $$__  $$| $$  \ $$ \  $$$$/ 
// | $$\  $ | $$| $$  | $$ \____  $$  | $$ /$$| $$_____/| $$      | $$  | $$| $$  \ $$| $$  | $$  >$$  $$ 
// | $$ \/  | $$|  $$$$$$$ /$$$$$$$/  |  $$$$/|  $$$$$$$| $$      |  $$$$$$$| $$$$$$$/|  $$$$$$/ /$$/\  $$
// |__/     |__/ \____  $$|_______/    \___/   \_______/|__/       \____  $$|_______/  \______/ |__/  \__/
//               /$$  | $$                                         /$$  | $$                              
//              |  $$$$$$/                                        |  $$$$$$/                              
//               \______/                                          \______/                               


interface ILoomi {
  function spendLoomi(address user, uint256 amount) external;
}

contract MysteryBox is Context, Ownable, ReentrancyGuard  {
    int256[10][] public points;

    uint256 private constant WEEK_LENGTH = 1 weeks;
    uint256 public constant SHARDS_INDEX = 4;
    uint256 public constant ITEMS_PER_WEEK = 10;

    uint256 public startTimestamp;
    uint256 public pointLoomiPrice;
    uint256 public shardsPrice;
    uint256 public spinPrice;
    uint256 private _nonce;

    bool public boxOpened;
    bool public isPaused;
    bool public shardSaleIsActive;

    ILoomi public loomi;

    mapping(uint256 => mapping(address => uint256)) private _tokenToUserBalance;
    mapping(address => int256) public userPoints;
    mapping (address => bool) private _isAuthorised;

    event SpinMysteryBox(address indexed user);
    event SacrificeLoomi(address indexed user);
    event AddPoints(address indexed user);
    event RemovePoints(address indexed user);
    event Authorise(address indexed user, bool isAuth);

    constructor (address _loomi) {
        // adds points for the first week
        points.push([int256(1),int256(-2),int256(3),int256(2),int256(0),int256(0),int256(1),int256(-1),int256(-4),int256(10)]);
        loomi = ILoomi(_loomi);

        pointLoomiPrice = 3000 ether;
        spinPrice = 2000 ether;
    }

    /*
      MODIFIERS
    */
    modifier whenNotPaused {
      require(!isPaused, "Tax collection paused!");
      _;
    }

    modifier authorised {
      require(_isAuthorised[_msgSender()], "Not Authorised");
      _;
    }

    /*
      PUBLIC FUNCTIONS
    */
    function random() internal view returns(uint){
      return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _nonce, _msgSender())));
    }

    /**
    * @dev Function allows user to spin the mystery box and get points 
    */
    function spinMysteryBox(uint256 numberOfSpins) public nonReentrant whenNotPaused {
      require(boxOpened, "Mystery box is closed");
      uint256 currentWeek = getCurrentWeek();
      require(points.length > currentWeek, "Prizes for this week are not set");

      loomi.spendLoomi(_msgSender(), spinPrice * numberOfSpins);

      for (uint256 i; i < numberOfSpins; i++) {
        _nonce++;
        uint256 rand = random() % ITEMS_PER_WEEK;
        _tokenToUserBalance[currentWeek * ITEMS_PER_WEEK + rand][_msgSender()] += 1;
      }

      emit SpinMysteryBox(_msgSender());
    }

    /**
    * @dev Function allows user to sacrifice loomi and get points 
    */
    function sacrifice(uint256 numberOfPoints) public nonReentrant whenNotPaused {
      require(boxOpened, "Mystery box is closed");

      uint256 loomiAmount = pointLoomiPrice * numberOfPoints;
      loomi.spendLoomi(_msgSender(), loomiAmount);

      userPoints[_msgSender()] += int256(numberOfPoints);

      emit SacrificeLoomi(_msgSender());
    }

    /**
    * @dev Function allows user to purchase shards
    */
    function purchaseShards(uint256 shardId, uint256 shardsNumber) public nonReentrant {
      require(shardSaleIsActive, "Shard sale is not active");
      require(points.length > shardId, "Unknown shard");

      uint256 loomiAmount = shardsPrice * shardsNumber;
      loomi.spendLoomi(_msgSender(), loomiAmount);

      _tokenToUserBalance[shardId * ITEMS_PER_WEEK + SHARDS_INDEX][_msgSender()] += shardsNumber;
      emit AddPoints(_msgSender());
    }

    /**
    * @dev Function returns current week
    */
    function getCurrentWeek() internal view returns(uint256) {
      if (startTimestamp == 0) return 0;
      return (block.timestamp - startTimestamp) / WEEK_LENGTH;
    }

    /**
    * @dev Function returns user artifacts and it's amount
    */
    function getUserItems(address user) public view returns (uint256[] memory) {
      uint256 itemsInGame = points.length * ITEMS_PER_WEEK;
      uint256[] memory output = new uint256[](itemsInGame);

      for (uint256 i; i < itemsInGame; i++) {
        output[i] = _tokenToUserBalance[i][user];
      }
      return output;
    }

    /**
    * @dev Function returns user points balance
    */
    function getUserBalance(address user) public view returns (int256) {
      int256 balance;

      for (uint256 i; i < points.length; i++) {
        for (uint256 j; j < ITEMS_PER_WEEK; j++) {
          balance += int256(_tokenToUserBalance[i * ITEMS_PER_WEEK + j][user]) * points[i][j];
        }
      }

      return (balance + userPoints[user]) > 0 ?  (balance + userPoints[user]) : int256(0);
    }

    /**
    * @dev Function returns user shards
    */
    function getUserShards(address user) public view returns (uint256[] memory) {
      uint256[] memory shards = new uint256[](points.length);

      for (uint256 i; i < points.length; i++) {
        uint256 shardIndex = i * ITEMS_PER_WEEK + SHARDS_INDEX;
        shards[i] = _tokenToUserBalance[shardIndex][user];
      }

      return shards;
    }

    /*
      AUTHORISED FUNCTIONS
    */

    /**
    * @dev Function auth address to add/remove shards to the user
    */
    function addShards(uint256 shardId, uint256 shardsNumber, address user) public authorised {
      require(points.length > shardId, "Unknown shard");
      _tokenToUserBalance[shardId * ITEMS_PER_WEEK + SHARDS_INDEX][user] += shardsNumber;
      emit AddPoints(user);
    }

    function removeShards(uint256 shardId, uint256 shardsNumber, address user) public authorised {
      require(points.length > shardId, "Unknown shard");
      _tokenToUserBalance[shardId * ITEMS_PER_WEEK + SHARDS_INDEX][user] -= shardsNumber;
      emit RemovePoints(user);
    }

    /**
    * @dev Function auth address to add/remove points to the user
    */
    function addPoints(address user, int256 pointsToAdd) public authorised {
      userPoints[user] += pointsToAdd;
      emit AddPoints(user);
    }

    function removePoints(address user, int256 pointsToRemove) public authorised {
      userPoints[user] -= pointsToRemove;
      emit RemovePoints(user);
    }

    /*
      OWNER FUNCTIONS
    */

    /**
    * @dev Function allows admin add authorised address. The function also logs what addresses were authorised for transparancy.
    */
    function authorise(address addressToAuth) public onlyOwner {
      _isAuthorised[addressToAuth] = true;
      emit Authorise(addressToAuth, true);
    }

    /**
    * @dev Function allows admin add unauthorised address.
    */
    function unauthorise(address addressToUnAuth) public onlyOwner {
      _isAuthorised[addressToUnAuth] = false;
      emit Authorise(addressToUnAuth, false);
    }

    /**
    * @dev Function allows admin to launch mystery box
    */
    function openMysteryBox() public onlyOwner {
      require(startTimestamp == 0, "Already opened");
      startTimestamp = block.timestamp;
      boxOpened = true;
    }

    /**
    * @dev Function allows admin to pause contract
    */
    function pause(bool _pause) public onlyOwner {
      isPaused = _pause;
    }
    
    /**
    * @dev Function allows admin to turn on/off shards sale
    */
    function updateShardSaleStatus(bool _isActive) public onlyOwner {
      shardSaleIsActive = _isActive;
    }
    
    /**
    * @dev Function allows admin to update spin price
    */
    function updateSpinPrice(uint256 _newPrice) public onlyOwner {
      spinPrice = _newPrice;
    }

    /**
    * @dev Function allows admin to update point price
    */
    function updatePointPrice(uint256 _newPrice) public onlyOwner {
      pointLoomiPrice = _newPrice;
    }

    /**
    * @dev Function allows admin to update shard price
    */
    function updateShardsPrice(uint256 _newPrice) public onlyOwner {
      shardsPrice = _newPrice;
    }

    /**
    * @dev Function allows admin to add points to the next week
    */
    function addItemsForNextWeek(int256[10] memory itemsPoints) public onlyOwner {
      points.push(itemsPoints);
    }

    /**
    * @dev Function allows admin to remove points for the next week
    */
    function removeItemsForLastWeek() public onlyOwner {
      require(getCurrentWeek() < points.length - 1, "Cannot remove this week items");
      points.pop();
    }
}
