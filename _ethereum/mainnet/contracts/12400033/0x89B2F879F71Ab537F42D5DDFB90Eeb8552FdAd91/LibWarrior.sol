// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

library LibWarrior {
	
    //////////////////////////////////////////////////////////////////////////////////////////
    // Config
    //////////////////////////////////////////////////////////////////////////////////////////
    
    //Warrior Attribute Factors
    uint8 constant hpConFactor = 3;
    uint8 constant hpStrFactor = 1;
    uint16 constant startingStr = 5;
    uint16 constant startingDex = 5;
    uint16 constant startingCon = 5;
    uint16 constant startingLuck = 5;
    uint16 constant startingPoints = 500;

    //Warrior Advancement
    uint8 constant levelExponent = 4;
    uint8 constant levelOffset = 4;
    uint8 constant killLevelOffset = 4;
    uint8 constant levelPointsExponent = 2;
    uint8 constant pointsLevelOffset = 6;
    uint8 constant pointsLevelMultiplier = 2;
    uint8 constant practiceLevelOffset = 1;
    uint32 constant trainingTimeFactor = 1 minutes; 
    uint16 constant intPotionFactor = 10;
    
    //Costing Config (costs are in FAME tokens)
    uint constant warriorCost = 100;
    uint constant warriorReviveBaseCost = warriorCost/20;
    uint constant strCostExponent = 2;
    uint constant dexCostExponent = 2;
    uint constant conCostExponent = 2;
    uint constant luckCostExponent = 3;
    uint constant potionCost = 100;
    uint constant intPotionCost = 500;
    uint constant armorCost = 10;
    uint constant weaponCost = 10;
    uint constant shieldCost = 10;
    uint constant armorCostExponent = 3;
    uint constant shieldCostExponent = 3;
    uint constant weaponCostExponent = 3;
    uint constant armorCostOffset = 2;
    uint constant shieldCostOffset = 2;
    uint constant weaponCostOffset = 2;

    //Value Constraints
    uint8 constant maxPotions = 5;
    uint8 constant maxIntPotions = 10;
    uint16 constant maxWeapon = 10;
    uint16 constant maxArmor = 10;
    uint16 constant maxShield = 10;

    //Misc Config
    uint32 constant cashoutDelay = 24 hours;
    uint16 constant wearPercentage = 10;
    uint16 constant potionHealAmount = 100;

    //////////////////////////////////////////////////////////////////////////////////////////
    // Enums
    //////////////////////////////////////////////////////////////////////////////////////////

    enum warriorState { 
        Idle, 
        Busy, 
        Incapacitated, 
        Retired
    }

    enum ArmorType {
        Minimal,
        Light,
        Medium,
        Heavy
    }

    enum ShieldType {
        None,
        Light,
        Medium,
        Heavy
    }

    enum WeaponClass {
        Slashing,
        Cleaving,
        Bludgeoning,
        ExtRange
    }

    enum WeaponType {
        //Slashing
        Sword,              //0
        Falchion,           //1
        //Cleaving
        Broadsword,         //2
        Axe,                //3
        //Bludgeoning
        Mace,               //4
        Hammer,             //5
        Flail,              //6
        //Extended-Reach
        Trident,            //7
        Halberd,            //8
        Spear               //9
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Structs
    //////////////////////////////////////////////////////////////////////////////////////////

    struct warriorStats {
        uint64 baseHP;
        uint64 dmg; 
        uint64 xp;
        uint16 str;
        uint16 dex;
        uint16 con;
        uint16 luck;
        uint64 points;
        uint16 level;
    }

    struct warriorEquipment {
        uint8 potions;
        uint8 intPotions;
        ArmorType armorType;
        ShieldType shieldType;
        WeaponType weaponType;
        uint8 armorStrength;
        uint8 shieldStrength;
        uint8 weaponStrength;
        uint8 armorWear;
        uint8 shieldWear;
        uint8 weaponWear;
        bool helmet;
    }

    struct warrior {
        //Header
        address owner;
        bytes32 bytesName;
        uint balance;
        uint cosmeticSeed;
        uint16 colorHue;
        warriorState state;
        uint32 creationTime;
        //Stats
        warriorStats stats;
        //Equipment
        warriorEquipment equipment;
        uint32 trainingUntil;
        bool special;
        uint32 generation;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Warrior Constructors
    //////////////////////////////////////////////////////////////////////////////////////////

    function newWarriorFixed(address owner, uint32 generation, bool special, uint randomSeed, uint16 colorHue, uint8 armorType, uint8 shieldType, uint8 weaponType) internal view returns (warrior memory theWarrior) {
        theWarrior = warrior(
			owner,                                              //owner
            bytes32(0),	                                        //bytesName Empty to start
			0,						                            //balance
            random(randomSeed,1),                               //cosmeticSeed
            colorHue,                                           //colorHue
			warriorState.Idle,		                            //state
			uint32(block.timestamp),                            //creationTime
            warriorStats(
                uint64(calcBaseHP(0,startingCon,startingStr)),  //BaseHP
    			0,						                        //dmg
                0,						                        //xp
                startingStr,			                        //str
                startingDex,			                        //dex
                startingCon,			                        //con
                startingLuck,			                        //luck
                startingPoints,			                        //points
                0						                        //level
            ),
            warriorEquipment(
                0,						                        //potions
                0,						                        //intPotions
                ArmorType(armorType),                           //armorType
                ShieldType(shieldType),                         //shieldType
                WeaponType(weaponType),                         //weaponType
                0,                                              //armorStrength
                0,                                              //shieldStrength
                0,                                              //weaponStrength
                0,                                              //armorWear
                0,                                              //shieldWear
                0,                                              //weaponWear
                false                                           //helmet
            ),
			0,      				                            //trainingUntil
			special,				                            //special flag
			generation				                            //generation
        );
    }

    function newWarrior(address owner, uint randomSeed) internal view returns (warrior memory theWarrior) {
        uint8 armorTypeCount = uint8(ArmorType.Heavy)+1; //Count enum states allowed by last item
        uint8 shieldTypeCount = uint8(ShieldType.Heavy)+1; //Count enum states allowed by last item
        uint8 weaponTypeCount = uint8(WeaponType.Spear)+1; //Count enum states allowed by last item

        //Randomly Generate main attributes/cosmetics:
        uint16 colorHue = uint16(random(randomSeed,0));
        uint8 armorType = uint8(random(randomSeed,1)%armorTypeCount);
        uint8 shieldType = uint8(random(randomSeed,2)%shieldTypeCount);
        uint8 weaponType = uint8(random(randomSeed,3)%weaponTypeCount);
        //Then construct:
        theWarrior = newWarriorFixed(owner, 0, false, randomSeed, colorHue, armorType, shieldType, weaponType);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Utilities
    //////////////////////////////////////////////////////////////////////////////////////////

    function random(uint seeda, uint seedb) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seeda,seedb)));  
    }

	function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 source) internal pure returns (string memory result) {
        uint8 len = 32;
        for(uint8 i;i<32;i++){
            if(source[i]==0){
                len = i;
                break;
            }
        }
        bytes memory bytesArray = new bytes(len);
        for (uint8 i=0;i<len;i++) {
            bytesArray[i] = source[i];
        }
        result = string(bytesArray);
    }

    function getWarriorCost() public pure returns(uint) {
        return warriorCost;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Derivation / Calaculation Pure Functions
    //////////////////////////////////////////////////////////////////////////////////////////

    function calcBaseHP(uint16 level, uint16 con, uint16 str) internal pure returns (uint) {
		return (con*(hpConFactor+level)) + (str*hpStrFactor);
    }

    function calcXPTargetForLevel(uint16 level) internal pure returns(uint64) {
        return (level+levelOffset) ** levelExponent;
    }

    function calcXPForPractice(uint16 level) internal pure returns (uint64) {
        return calcXPTargetForLevel(level)/(((level+practiceLevelOffset)**2)+1);
    }

    function calcDominantStatValue(uint16 con, uint16 dex, uint16 str) internal pure returns(uint16) {
        if(con>dex&&con>str) return con;
        else if(dex>con&&dex>str) return dex;
        else return str;
    }

    function calcTimeToPractice(uint16 level) internal pure returns(uint) {
		return trainingTimeFactor * ((level**levelExponent)+levelOffset);
    }

    function calcAttributeCost(uint8 amount, uint16 stat_base, uint costExponent) internal pure returns (uint cost) {
        for(uint i=0;i<amount;i++){
            cost += (stat_base + i) ** costExponent;
        }
    }
    
    function calcItemCost(uint8 amount, uint8 currentVal, uint baseCost, uint offset, uint exponent) internal pure returns (uint cost) {
        for(uint i=0;i<amount;i++){
            cost += ((i + 1 + currentVal + offset) ** exponent) * baseCost;
        }
    }

    function calcReviveCost(uint16 level) internal pure returns(uint) {
        return ((level ** 2) +1) * warriorReviveBaseCost;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Derived/Calculated Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    function getName(warrior memory w) public pure returns(string memory name) {
        name = bytes32ToString(w.bytesName);
    }

    function getHP(warrior memory w) public pure returns (int) {
        return int(int64(w.stats.baseHP) - int64(w.stats.dmg));
    }

    function getWeaponClass(warrior memory w) public pure returns (WeaponClass) {
        if((w.equipment.weaponType==WeaponType.Broadsword || w.equipment.weaponType==WeaponType.Axe)) return WeaponClass.Cleaving;
        if((w.equipment.weaponType==WeaponType.Mace || w.equipment.weaponType==WeaponType.Hammer || w.equipment.weaponType==WeaponType.Flail)) return WeaponClass.Bludgeoning;
        if((w.equipment.weaponType==WeaponType.Trident || w.equipment.weaponType==WeaponType.Halberd || w.equipment.weaponType==WeaponType.Spear)) return WeaponClass.ExtRange;        
        //Default, (w.weaponType==WeaponType.Sword || w.weaponType==WeaponType.Falchion):
        return WeaponClass.Slashing;
    }
   
    function canLevelUp(warrior memory w) public pure returns(bool) {
        return (w.stats.xp >= calcXPTargetForLevel(w.stats.level));
    }

    function getCosmeticProperty(warrior memory w, uint propertyIndex) public pure returns (uint) {
        return random(w.cosmeticSeed,propertyIndex);
    }

    function getEquipLevel(warrior memory w) public pure returns (uint) {
        if(w.equipment.weaponStrength>w.equipment.armorStrength && w.equipment.weaponStrength>w.equipment.shieldStrength){
            return w.equipment.weaponStrength;
        }else{
            if(w.equipment.armorStrength>w.equipment.shieldStrength){
                return w.equipment.armorStrength;
            }else{
                return w.equipment.shieldStrength;
            }
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Costing Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    function getStatsCost(warrior memory w, uint8 strAmount, uint8 dexAmount, uint8 conAmount, uint8 luckAmount) public pure returns (uint) {
        return (
            calcAttributeCost(strAmount,w.stats.str,strCostExponent)+
            calcAttributeCost(dexAmount,w.stats.dex,dexCostExponent)+
            calcAttributeCost(conAmount,w.stats.con,conCostExponent)+
            calcAttributeCost(luckAmount,w.stats.luck,luckCostExponent)
        );
    }
    
    function getEquipCost(warrior memory w, uint8 armorAmount, uint8 shieldAmount, uint8 weaponAmount, uint8 potionAmount, uint8 intPotionAmount) public pure returns(uint) {
        return (
            calcItemCost(armorAmount,w.equipment.armorStrength,armorCost,armorCostOffset,armorCostExponent)+
            calcItemCost(shieldAmount,w.equipment.shieldStrength,shieldCost,shieldCostOffset,shieldCostExponent)+
            calcItemCost(weaponAmount,w.equipment.weaponStrength,weaponCost,weaponCostOffset,weaponCostExponent)+
            (potionCost*potionAmount)+
            (intPotionCost+intPotionAmount)
        );
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Setters
    //////////////////////////////////////////////////////////////////////////////////////////

    function setName(warrior memory w, string memory name) public pure returns (warrior memory) {
        require(w.bytesName==bytes32(0));
        w.bytesName = stringToBytes32(name);
        return w;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Buying Things
    //////////////////////////////////////////////////////////////////////////////////////////

    function buyStats(warrior memory w, uint8 strAmount, uint8 dexAmount, uint8 conAmount, uint8 luckAmount) public pure returns (warrior memory) {
        require(strAmount>0 || dexAmount>0 || conAmount>0 || luckAmount>0); //Require buying at least something, otherwise you are wasting gas!
        w.stats.str += strAmount;
        w.stats.dex += dexAmount;
        w.stats.con += conAmount;
        w.stats.luck += luckAmount;
        w.stats.baseHP = uint64(calcBaseHP(w.stats.level,w.stats.con,w.stats.str));
        return w;
    }

    function buyEquipment(warrior memory w, uint8 armorAmount, uint8 shieldAmount, uint8 weaponAmount, uint8 potionAmount, uint8 intPotionAmount) public pure returns (warrior memory) {
        require(armorAmount>0 || shieldAmount>0 || weaponAmount>0 || potionAmount>0 || intPotionAmount>0); //Require buying at least something, otherwise you are wasting gas!
        require((w.equipment.potions+potionAmount) <= maxPotions);
        require((w.equipment.intPotions+intPotionAmount) <= maxIntPotions);
        w.equipment.armorStrength += armorAmount;
        w.equipment.shieldStrength += shieldAmount;
        w.equipment.weaponStrength += weaponAmount;
        w.equipment.potions += potionAmount;
        w.equipment.intPotions += intPotionAmount;
        return w;
    }    

    //////////////////////////////////////////////////////////////////////////////////////////
    // Actions/Activities/Effects
    //////////////////////////////////////////////////////////////////////////////////////////

    function levelUp(warrior memory w) public pure returns (warrior memory) {
        require(w.stats.xp >= calcXPTargetForLevel(w.stats.level));
        w.stats.level++;
        w.stats.str++;
        w.stats.dex++;
        w.stats.con++;
        w.stats.points += ((w.stats.level+pointsLevelOffset) * pointsLevelMultiplier) ** levelPointsExponent;
        w.stats.baseHP = uint64(calcBaseHP(w.stats.level,w.stats.con,w.stats.str));
        return w;
    }

	function awardXP(warrior memory w, uint64 amount) public pure returns (warrior memory) {
		w.stats.xp += amount;
        if(canLevelUp(w)) {
            return levelUp(w);
        }else{
            return w;
        }
    }

    function practice(warrior memory w) public view returns (warrior memory) {
        require(uint32(block.timestamp)>w.trainingUntil,"BUSY_TRAINING!");
        if(w.equipment.intPotions>0){
            w.equipment.intPotions--;
            w.trainingUntil = uint32(block.timestamp + (calcTimeToPractice(w.stats.level)/intPotionFactor));
        }else{
            w.trainingUntil = uint32(block.timestamp + calcTimeToPractice(w.stats.level)); 
        }
        return awardXP(w,calcXPForPractice(w.stats.level));
    }

    function revive(warrior memory w) public pure returns (warrior memory) {
		w.state = warriorState.Idle;
        w.stats.dmg = 0;
        return w;
    }

    function kill(warrior memory w) public pure returns (warrior memory) {
		w.state = warriorState.Incapacitated;
        return w;
    }

    function drinkPotion(warrior memory w) public pure returns (warrior memory) {
		require(w.equipment.potions>0);
        require(w.stats.dmg>0);
        w.equipment.potions--;
        if(w.stats.dmg>potionHealAmount){
            w.stats.dmg -= potionHealAmount;
        }else{
            w.stats.dmg = 0;
        }
        return w;
    }

    function applyDamage(warrior memory w, uint damage) public pure returns (warrior memory) {
		w.stats.dmg += uint64(damage);
        if(w.stats.dmg >= w.stats.baseHP) {
            w.stats.dmg = w.stats.baseHP;
            kill(w);
        }
        return w;
    }

    function wearWeapon(warrior memory w) public pure returns (warrior memory) {
        if(w.equipment.weaponStrength>0){
            w.equipment.weaponWear++;
            if(w.equipment.weaponWear>((maxWeapon+1)-w.equipment.weaponStrength)){ //Wear increases as you approach max level
                w.equipment.weaponStrength--;
                w.equipment.weaponWear=0;
            }
        }
        return w;
    }

    function wearArmor(warrior memory w) public pure returns (warrior memory) {
        if(w.equipment.armorStrength>0){
            w.equipment.armorWear++;
            if(w.equipment.armorWear>((maxArmor+1)-w.equipment.armorStrength)){ //Wear increases as you approach max level
                w.equipment.armorStrength--;
                w.equipment.armorWear=0;
            }
        }
        return w;
    }

    function wearShield(warrior memory w) public pure returns (warrior memory) {
        if(w.equipment.shieldStrength>0){
            w.equipment.shieldWear++;
            if(w.equipment.shieldWear>((maxShield+1)-w.equipment.shieldStrength)){ //Wear increases as you approach max level
                w.equipment.shieldStrength--;
                w.equipment.shieldWear=0;
            }
        }
        return w;
    }
}