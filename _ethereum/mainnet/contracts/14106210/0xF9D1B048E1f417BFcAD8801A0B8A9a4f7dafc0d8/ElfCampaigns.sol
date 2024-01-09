// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./DataStructures.sol";
//import "./console.sol";

contract ElfCampaigns {

struct Camps {
            uint32 baseRewards; 
            uint32 creatureCount; 
            uint32 creatureHealth; 
            uint32 expPoints; 
            uint32 minLevel;
    }

    bool private initialized;
    address elfcontract;
    
    uint256 public MAX_LEVEL;
    uint256 public TIME_CONSTANT; 
    uint256 public REGEN_TIME; 
    address admin;
    
    mapping(uint256 => Camps) public camps; //memory slot for campaigns
    
    bytes32 internal ketchup;

    //EVENTS
    event LastKill(address indexed from); 
    event AddCamp(uint256 indexed id, uint256 baseRewards, uint256 creatureCount, uint256 creatureHealth, uint256 expPoints, uint256 minLevel);



function initialize(address _elfcontract) public {
    
    require(!initialized, "Already initialized");
     
        camps[1] = Camps({baseRewards: 10, creatureCount: 6000, creatureHealth: 12,  expPoints:9,   minLevel:1});
        camps[2] = Camps({baseRewards: 20, creatureCount: 3000, creatureHealth: 72,  expPoints:9,   minLevel:15});
        camps[3] = Camps({baseRewards: 30, creatureCount: 3000, creatureHealth: 132, expPoints:9,   minLevel:30});
        MAX_LEVEL = 100;
        TIME_CONSTANT = 1 hours; 
        REGEN_TIME = 300 hours; 
        admin = msg.sender;
        elfcontract = _elfcontract;
        initialized = true;
     
    }


function gameEngine(uint256 _campId, uint256 _sector, uint256 _level, uint256 _attackPoints, uint256 _healthPoints, uint256 _inventory, bool _useItem) external 
returns(uint256 level, uint256 rewards, uint256 timestamp, uint256 inventory){
  
  Camps memory camp = camps[_campId];  
  
  require(elfcontract == msg.sender, "not elf contract"); 
  require(camp.minLevel <= _level, "level too low");
  require(camp.creatureCount > 0, "no creatures left");
  
  camps[_campId].creatureCount = camp.creatureCount - 1;

  rewards = camp.baseRewards + (2 * (_sector - 1));
  
  rewards = rewards * (1 ether);
 
  if(_useItem){
         _attackPoints = _inventory == 1 ? _attackPoints * 2   : _attackPoints;
         _healthPoints = _inventory == 2 ? _healthPoints * 2   : _healthPoints; 
          rewards      = _inventory == 3 ?  rewards * 2        : rewards;
          level        = _inventory == 4 ? _level * 2          : _level;
         _healthPoints = _inventory == 5 ? _healthPoints + 200 : _healthPoints; 
         _attackPoints = _inventory == 6 ? _attackPoints * 3   : _attackPoints;
         
         inventory = 0;
  }

  level = level < MAX_LEVEL ? level + (uint256(camp.expPoints)/3) : level;
                             
  uint256 creatureHealth =  ((_sector - 1) * 12) + camp.creatureHealth; 
  uint256 attackTime = creatureHealth/_attackPoints;
  
  attackTime = attackTime > 0 ? attackTime * TIME_CONSTANT : 0;
  
  timestamp = REGEN_TIME/(_healthPoints) + (block.timestamp + attackTime);
  
  if(camp.creatureCount == 0){    
    emit LastKill(msg.sender);
  }

}


function addCamp(uint256 id, uint16 baseRewards_, uint16 creatureCount_, uint16 expPoints_, uint16 creatureHealth_, uint16 minLevel_) external      
    {
        require(admin == msg.sender);
        Camps memory newCamp = Camps({
            baseRewards:    baseRewards_, 
            creatureCount:  creatureCount_, 
            expPoints:      expPoints_,
            creatureHealth: creatureHealth_, 
            minLevel:       minLevel_
            });

        camps[id] = newCamp;
         emit AddCamp(id, baseRewards_, creatureCount_, expPoints_, creatureHealth_, minLevel_);
    }

  

//////Random Number Generator/////

    function _randomize(uint256 ran, string memory dom, uint256 ness) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(ran,dom,ness)));}

    function _rand() internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp, block.basefee, ketchup)));}


}

