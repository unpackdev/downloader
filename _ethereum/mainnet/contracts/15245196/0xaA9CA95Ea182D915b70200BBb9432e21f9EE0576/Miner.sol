//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

struct Miner {
    int16 baseHealth;
    int16 baseArmor;
    int16 health;
    int16 armor;
    int16 attack;
    int16 speed;
    uint16 gold;
    uint8 genderId;
    uint8 classId;
    uint8 skintoneId;
    uint8 hairColorId;
    uint8 hairTypeId;
    uint8 eyeColorId;
    uint8 eyeTypeId;
    uint8 mouthId;
    uint8 headgearId;
    uint8 armorId;
    uint8 pantsId;
    uint8 footwearId;
    uint8 weaponId;
    uint8 curseTurns;
    uint8 buffTurns;
    uint8 debuffTurns;
    uint8 revives;
    uint8 currentChamber;
}