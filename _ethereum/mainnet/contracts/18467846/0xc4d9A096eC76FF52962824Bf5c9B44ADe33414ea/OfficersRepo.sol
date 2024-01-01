// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";
import "./IRegisterOfMembers.sol";

library OfficersRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;

    enum TitleOfOfficers {
        ZeroPoint,
        Shareholder,
        Chairman,
        ViceChairman,
        ManagingDirector,
        Director,
        CEO,
        CFO,
        COO,
        CTO,
        President,
        VicePresident,
        Supervisor,
        SeniorManager,
        Manager,
        ViceManager      
    }

    struct Position {
        uint16 title;
        uint16 seqOfPos;
        uint40 acct;
        uint40 nominator;
        uint48 startDate;
        uint48 endDate;
        uint16 seqOfVR;
        uint16 titleOfNominator;
        uint16 argu;
    }

    struct Group {
        // seqList
        EnumerableSet.UintSet posList;
        // acctList
        EnumerableSet.UintSet acctList;
    }

    struct Repo {
        //seqOfPos => Position
        mapping(uint => Position)  positions;
        // acct => seqOfPos
        mapping(uint => EnumerableSet.UintSet) posInHand;
        Group directors;
        Group managers;
    }

    //#################
    //##   Modifier  ##
    //#################

    modifier isVacant(Repo storage repo, uint256 seqOfPos) {
        require(!isOccupied(repo, seqOfPos), 
            "OR.mf.IV: position occupied");
        _;
    }

    //#################
    //##    Write    ##
    //#################

    // ==== snParser ====

    function snParser(bytes32 sn) public pure returns (Position memory position) {
        uint _sn = uint(sn);

        position = Position({
            title: uint16(_sn >> 240),
            seqOfPos: uint16(_sn >> 224),
            acct: uint40(_sn >> 184),
            nominator: uint40(_sn >> 144),
            startDate: uint48(_sn >> 96),
            endDate: uint48(_sn >> 48),
            seqOfVR: uint16(_sn >> 32),
            titleOfNominator: uint16(_sn >> 16),
            argu: uint16(_sn)
        });
    }

    function codifyPosition(Position memory position) public pure returns (bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            position.title,
                            position.seqOfPos,
                            position.acct,
                            position.nominator,
                            position.startDate,
                            position.endDate,
                            position.seqOfVR,
                            position.titleOfNominator,
                            position.argu);  
        assembly {
            sn := mload(add(_sn, 0x20))
        }                
    }

    // ======== Setting ========

    function createPosition (Repo storage repo, bytes32 snOfPos) 
        public 
    {
        Position memory pos = snParser(snOfPos);
        addPosition(repo, pos);
    }

    function addPosition(
        Repo storage repo,
        Position memory pos
    ) public {
        require (pos.title > uint8(TitleOfOfficers.Shareholder), "OR.addPosition: title overflow");
        require (pos.seqOfPos > 0, "OR.addPosition: zero seqOfPos");
        require (pos.titleOfNominator > 0, "OR.addPosition: zero titleOfNominator");
        require (pos.endDate > pos.startDate, "OR.addPosition: endDate <= startDate");
        require (pos.endDate > block.timestamp, "OR.addPosition: endDate not future");

        Position storage p = repo.positions[pos.seqOfPos];
        
        if (p.seqOfPos == 0) {
            if (pos.title <= uint8(TitleOfOfficers.Director)) 
                repo.directors.posList.add(pos.seqOfPos);
            else repo.managers.posList.add(pos.seqOfPos); 
        } else require (p.seqOfPos == pos.seqOfPos,
            "OR.addPosition: remove pos first");

        repo.positions[pos.seqOfPos] = pos;
    }

    function removePosition(Repo storage repo, uint256 seqOfPos) 
        public isVacant(repo, seqOfPos) returns (bool flag)
    {
        if (repo.directors.posList.remove(seqOfPos) ||
            repo.managers.posList.remove(seqOfPos)) 
        {
            delete repo.positions[seqOfPos];
            flag = true;
        }
    }

    function takePosition (
        Repo storage repo,
        uint256 seqOfPos,
        uint acct
    ) public returns (bool flag) {
        require (seqOfPos > 0, "OR.takePosition: zero seqOfPos");
        require (acct > 0, "OR.takePosition: zero acct");
        
        Position storage pos = repo.positions[seqOfPos];

        if (repo.directors.posList.contains(seqOfPos))
            repo.directors.acctList.add(acct);
        else if (repo.managers.posList.contains(seqOfPos))
            repo.managers.acctList.add(acct);
        else revert("OR.takePosition: pos not exist");

        pos.acct = uint40(acct);
        pos.startDate = uint48(block.timestamp);

        repo.posInHand[acct].add(seqOfPos);

        flag = true;
    }

    function quitPosition(
        Repo storage repo, 
        uint256 seqOfPos,
        uint acct
    ) public returns (bool flag)
    {
        Position memory pos = repo.positions[seqOfPos];
        require(acct == pos.acct, 
            "OR.quitPosition: not the officer");
        flag = vacatePosition(repo, seqOfPos);
    }

    function vacatePosition (
        Repo storage repo,
        uint seqOfPos
    ) public returns (bool flag)
    {
        Position storage pos = repo.positions[seqOfPos];

        uint acct = pos.acct;
        require (acct > 0, "OR.vacatePosition: empty pos");

        if (repo.posInHand[acct].remove(seqOfPos)) {
            pos.acct = 0;

            if (pos.title <= uint8(TitleOfOfficers.Director))
                repo.directors.acctList.remove(acct);
            else if (repo.posInHand[acct].length() == 0) {
                repo.managers.acctList.remove(acct);
            }
                
            flag = true;
        }        
    }

    //##################
    //##    读接口    ##
    //##################

    // ==== Positions ====

    function posExist(Repo storage repo, uint256 seqOfPos) public view returns (bool flag) {
        flag = repo.positions[seqOfPos].endDate > block.timestamp;
    } 

    function isOccupied(Repo storage repo, uint256 seqOfPos) public view returns (bool flag) {
        flag = repo.positions[seqOfPos].acct > 0;
    }

    function getPosition(Repo storage repo, uint256 seqOfPos) public view returns (Position memory pos) {
        pos = repo.positions[seqOfPos];
    }

    function getFullPosInfo(Repo storage repo, uint[] memory pl) 
        public view returns(Position[] memory) 
    {
        uint256 len = pl.length;
        Position[] memory ls = new Position[](len);

        while (len > 0) {
            ls[len-1] = repo.positions[pl[len-1]];
            len--;
        }

        return ls;        
    }

    // ==== Managers ====

    function isManager(Repo storage repo, uint256 acct) public view returns (bool flag) {
        flag = repo.managers.acctList.contains(acct);
    }

    function getNumOfManagers(Repo storage repo) public view returns (uint256 num) {
        num = repo.managers.acctList.length();
    }

    function getManagersList(Repo storage repo) public view returns (uint256[] memory ls) {
        ls = repo.managers.acctList.values();
    }

    function getManagersPosList(Repo storage repo) public view returns(uint[] memory list) {
        list = repo.managers.posList.values();
    }

    function getManagersFullPosInfo(Repo storage repo) public view 
        returns(Position[] memory output) 
    {
        uint[] memory pl = repo.managers.posList.values();
        output = getFullPosInfo(repo, pl);
    }

    // ==== Directors ====

    function isDirector(Repo storage repo, uint256 acct) 
        public view returns (bool flag) 
    {
        flag = repo.directors.acctList.contains(acct);
    }

    function getNumOfDirectors(Repo storage repo) public view 
        returns (uint256 num) 
    {
        num = repo.directors.acctList.length();
    }

    function getDirectorsList(Repo storage repo) public view 
        returns (uint256[] memory ls) 
    {
        ls = repo.directors.acctList.values();
    }

    function getDirectorsPosList(Repo storage repo) public view 
        returns (uint256[] memory ls) 
    {
        ls = repo.directors.posList.values();
    }

    function getDirectorsFullPosInfo(Repo storage repo) public view 
        returns(Position[] memory output) 
    {
        uint[] memory pl = repo.directors.posList.values();
        output = getFullPosInfo(repo, pl);
    }

    // ==== Executives ====

    function hasPosition(Repo storage repo, uint256 acct, uint256 seqOfPos) 
        public view returns (bool flag) 
    {
        flag = repo.posInHand[acct].contains(seqOfPos);
    }

    function getPosInHand(Repo storage repo, uint256 acct) 
        public view returns (uint256[] memory ls) 
    {
        ls = repo.posInHand[acct].values();
    }

    function getFullPosInfoInHand(Repo storage repo, uint acct) 
        public view returns (Position[] memory output) 
    {
        uint256[] memory pl = repo.posInHand[acct].values();
        output = getFullPosInfo(repo, pl);
    }

    function hasTitle(Repo storage repo, uint acct, uint title, IRegisterOfMembers _rom)
        public view returns (bool)
    {
        if (title == uint8(TitleOfOfficers.Shareholder))
            return _rom.isMember(acct);

        if (title == uint8(TitleOfOfficers.Director))
            return isDirector(repo, acct);
        
        Position[] memory list = getFullPosInfoInHand(repo, acct);
        uint len = list.length;
        while (len > 0) {
            if (list[len-1].title == uint16(title))
                return true;
            len --;
        }
        return false;
    }

    function hasNominationRight(Repo storage repo, uint seqOfPos, uint acct, IRegisterOfMembers _rom)
        public view returns (bool)
    {
        Position memory pos = repo.positions[seqOfPos];
        if (pos.endDate <= block.timestamp) return false;
        else if (pos.nominator == 0)
            return hasTitle(repo, acct, pos.titleOfNominator, _rom);
        else return (pos.nominator == acct);
    }

    // ==== seatsCalculator ====

    function getBoardSeatsQuota(Repo storage repo, uint256 acct) public view 
        returns (uint256 quota)
    {
        uint[] memory pl = repo.directors.posList.values();
        uint256 len = pl.length;
        while (len > 0) {
            Position memory pos = repo.positions[pl[len-1]];
            if (pos.nominator == acct) quota++;
            len--;
        }       
    }

    function getBoardSeatsOccupied(Repo storage repo, uint acct) public view 
        returns (uint256 num)
    {
        uint256[] memory dl = repo.directors.acctList.values();
        uint256 lenOfDL = dl.length;

        while (lenOfDL > 0) {
            uint256[] memory pl = repo.posInHand[dl[lenOfDL-1]].values();
            uint256 lenOfPL = pl.length;

            while(lenOfPL > 0) {
                Position memory pos = repo.positions[pl[lenOfPL-1]];
                if ( pos.title <= uint8(TitleOfOfficers.Director)) { 
                    if (pos.nominator == acct) num++;
                    break;
                }
                lenOfPL--;
            }

            lenOfDL--;
        }
    }
}
