pragma solidity >=0.4.22 <0.6.0;


contract UsdMonster {
    
    address public owner;
    mapping(uint => Monster) public monsterIds;
     uint public monsterCount = 1;
    uint public lastMonsterId = 1;

    
     struct Monster {
        uint monster_id;
        address monster_address;
		uint referrer_id;
        address referrer_address;
        
        uint monsterLevel;
    }
    
    
    constructor() public { 
        owner = msg.sender;
       
          Monster memory monster = Monster({
            monster_id: 1,
            monster_address:owner,
            referrer_id: 0,
            referrer_address: address(0),
          
            monsterLevel:900
        });
        
        monsterIds[1] = monster;
        }
       
    function catchMonster(uint userId,address userAddress,uint referrerId, address referrerAddress,uint level) public {
            Monster memory monster = Monster({
            monster_id: userId,
            monster_address:userAddress,
            referrer_id: referrerId,
            referrer_address: referrerAddress,
            monsterLevel:level
        });
        monsterIds[userId] = monster;
         monsterCount += 1;
         lastMonsterId = userId;
        
        
    }
    
    function isMonsterExists(uint id) public view returns (bool) {
        return (monsterIds[id].monster_id != 0);
    }
   
    function getMonster(uint8 id) public view returns (uint,address,uint,address,uint)  {
        return (monsterIds[id].monster_id,monsterIds[id].monster_address,monsterIds[id].referrer_id,monsterIds[id].referrer_address,monsterIds[id].monsterLevel);
    }
  
    function totalmonster() public view returns (uint) {
        return monsterCount;
    }
    
  
    
}