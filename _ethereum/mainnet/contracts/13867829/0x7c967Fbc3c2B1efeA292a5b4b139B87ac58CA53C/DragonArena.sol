// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./Math.sol";
import "./DragonInfo.sol";
import "./FightInfo.sol";
import "./Random.sol";
import "./LockableReceiver.sol";
import "./DragonToken.sol";

contract DragonArena is LockableReceiver { 

    using SafeMath for uint;
    using Address for address payable;

    mapping(uint => uint) private _fights;
    mapping(uint => uint) private _dragonFights;
    mapping(uint => uint) private _attackers;

    uint private _fightPrice;

    event JoinFight(address indexed originator, uint fightId, uint dragonId);
    event FightFinished(address indexed operator, uint fightId, uint winnerId, bool technicalDefeat);
    event FightCancelled(address indexed operator, uint fightId);

    constructor(address accessControl, address dragonToken, uint weiFightPrice) 
    LockableReceiver(accessControl, dragonToken) {
        _fightPrice = weiFightPrice;
    }

    function price() external view returns(uint) {
        return _fightPrice;
    }

    function attackerFight(uint attackerId) public view returns (uint) {
        return _attackers[attackerId];
    }

    function fightOf(uint dragonId) public view returns (uint) {
        return _dragonFights[dragonId];
    }

    function setPrice(uint newPrice) external onlyRole(CFO_ROLE) {
        uint previousPrice = _fightPrice;
        _fightPrice = newPrice;
        emit ValueChanged("fightPrice", previousPrice, newPrice);
    }

    function getFightId(bytes calldata fightToken) public pure returns (uint) {
        return uint(keccak256(fightToken));
    }

    function fightInfo(uint fightId) external view returns (FightInfo.Details memory) {
        return FightInfo.getDetails(_fights[fightId]);
    }

    function joinFight(uint dragonId, bytes calldata fightToken) 
    external payable
    onlyHolder(dragonId) {
        require(fightOf(dragonId) == 0, "DragonArena: a dragon with the given id has already joined another fight");
        (uint value, FightInfo.Details memory fight) = FightInfo.readDetailsFromToken(fightToken);
        require(fight.dragon1Id > 0 && fight.dragon2Id > 0 
            && fight.dragon1Id != fight.dragon2Id 
            && ((fight.fightType == FightInfo.Types.Regular && fight.betAmount == 0)
                || (fight.fightType == FightInfo.Types.Money && fight.betAmount > 0)), "DragonArena: bad fight token");
        require(dragonId == fight.dragon1Id || dragonId == fight.dragon2Id, 
            "DragonArena: a dragon with the given id is not associated with this fight");
        require(msg.value >= (_fightPrice + fight.betAmount), "DragonArena: incorrect amount sent to the contract");

        uint fightId = getFightId(fightToken);
        // if it's an attacker dragon and a dragon-defender hasn't joined the fight yet then revert the transaction
        if (dragonId == fight.dragon1Id && fightOf(fight.dragon2Id) != fightId) { 
            revert("DragonArena: the dragon-defender must accept the fight first");
        }
        // if there is another record with the same dragon-attacker
        if (dragonId == fight.dragon2Id && attackerFight(fight.dragon1Id) > 0) { 
            revert("DragonArena: there is another fight with the same dragon-attacker");
        }
        
        if (_fights[fightId] == 0) {
            _fights[fightId] = value;
        }
        _attackers[fight.dragon1Id] = fightId;
        _dragonFights[dragonId] = fightId;

        emit JoinFight(_msgSender(), fightId, dragonId);
    }

    function startFight(uint fightId) external onlyRole(COO_ROLE) {
        uint fightValue = _fights[fightId];
        require(fightValue > 0, "DragonArena: a fight with the given id doesn't exist");
        FightInfo.Details memory fight = FightInfo.getDetails(fightValue);

        require(isLocked(fight.dragon1Id) && isLocked(fight.dragon2Id), 
            "DragonArena: both the dragons must be locked on the contract before starting a fight");
        
        DragonToken dragonToken = DragonToken(tokenContract());

        //init the strengths before fighting
        dragonToken.setStrength(fight.dragon1Id);
        dragonToken.setStrength(fight.dragon2Id);

        (uint winnerId, uint loserId, bool technicalDefeat) = _checkTechnicalDefeat(fight);

        if (!technicalDefeat) {
            DragonInfo.Details memory dd1 = dragonToken.dragonInfo(fight.dragon1Id);
            DragonInfo.Details memory dd2 = dragonToken.dragonInfo(fight.dragon2Id);
            (winnerId, loserId) = 
                _randomFightResult(fight.dragon1Id, dd1.strength, fight.dragon2Id, dd2.strength, fightId);
        }

        _transferTrophy(winnerId, loserId, fight, technicalDefeat);
        
        delete _attackers[fight.dragon1Id];
        delete _dragonFights[fight.dragon1Id];
        delete _dragonFights[fight.dragon2Id];
        delete _fights[fightId];

        emit FightFinished(_msgSender(), fightId, winnerId, technicalDefeat);
    }

    function cancelFight(uint fightId) external onlyRole(COO_ROLE) {
        uint fightValue = _fights[fightId];
        require(fightValue > 0, "DragonArena: a fight with the given id doesn't exist");
        FightInfo.Details memory fight = FightInfo.getDetails(fightValue);
        
        delete _attackers[fight.dragon1Id];
        delete _dragonFights[fight.dragon1Id];
        delete _dragonFights[fight.dragon2Id];
        delete _fights[fightId];

        emit FightCancelled(_msgSender(), fightId);
    }

    function withdraw(uint tokenId) public override virtual  {
        require(fightOf(tokenId) == 0 && attackerFight(tokenId) == 0, "DragonArena: unable to withdraw");
        super.withdraw(tokenId);
    }

    function _checkTechnicalDefeat(FightInfo.Details memory fight) internal view returns (uint, uint, bool) {
        uint f1 = _dragonFights[fight.dragon1Id];
        uint f2 = _dragonFights[fight.dragon2Id];
        require(f1 > 0 || f2 > 0, "DragonArena: none of the dragons has joined the fight");
        return  (f1 == 0) ? (fight.dragon2Id, fight.dragon1Id, true) : 
                (f2 == 0) ? (fight.dragon1Id, fight.dragon2Id, true) : 
                (0, 0, false);
    }

    function _transferTrophy(uint winnerId, uint loserId, FightInfo.Details memory fight, bool technicalDefeat) internal {
        if (fight.fightType == FightInfo.Types.Regular || technicalDefeat) {
            _lock(loserId, holderOf(winnerId));
            _transferTokenToHolder(loserId);
        }
        else if (fight.fightType == FightInfo.Types.Money) {
            payable(holderOf(winnerId)).sendValue(fight.betAmount*2);
        }
    }

    function _randomFightResult(uint dragon1Id, uint dragon1Strength, uint dragon2Id, uint dragon2Strength, uint salt)
    internal view returns (uint, uint) {

        uint totalStrength = dragon1Strength + dragon2Strength;
        uint result = Random.rand(salt ^ block.difficulty).mod(totalStrength);

        uint minId;
        uint maxId;
        uint minStrength;

        if (dragon1Strength < dragon2Strength) {
            minId = dragon1Id;
            minStrength = dragon1Strength;
            maxId = dragon2Id;
        } else {
            minId = dragon2Id;
            minStrength = dragon2Strength;
            maxId = dragon1Id;
        }

        if (result < minStrength) {
            return (minId, maxId);
        }
        else {
            return (maxId, minId);
        }
    }
}