// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfDirectors.sol";
import "./AccessControl.sol";

contract RegisterOfDirectors is IRegisterOfDirectors, AccessControl {
    using OfficersRepo for OfficersRepo.Repo;

    OfficersRepo.Repo private _repo;

    //#################
    //##  Write I/O  ##
    //#################

    // ==== PositionSetting ====
    function createPosition(bytes32 snOfPos) external onlyKeeper { 
            _repo.createPosition(snOfPos);
        emit AddPosition(snOfPos);
    }

    function updatePosition(OfficersRepo.Position memory pos) external onlyKeeper {
        _repo.addPosition(pos);
        emit AddPosition(OfficersRepo.codifyPosition(pos));
    }

    function removePosition(uint256 seqOfPos) external onlyKeeper {
        if (_repo.removePosition(seqOfPos))
            emit RemovePosition(seqOfPos);
    }

    // ---- Officers ----

    function takePosition (uint256 seqOfPos, uint caller) external onlyDK()
    {
        if (_repo.takePosition(seqOfPos, caller)) 
            emit TakePosition(seqOfPos, caller);
    }

    function quitPosition (uint256 seqOfPos, uint caller) external onlyDK
    {
        if (_repo.quitPosition(seqOfPos, caller))
            emit QuitPosition(seqOfPos, caller);
    }

    function removeOfficer (uint256 seqOfPos) external onlyDK()
    {
        if (_repo.vacatePosition(seqOfPos))
            emit RemoveOfficer(seqOfPos);
    }

    //##################
    //##    读接口    ##
    //##################

    // ==== Positions ====
    
    function posExist(uint256 seqOfPos) external view returns (bool) {
        return _repo.posExist(seqOfPos);
    }

    function isOccupied(uint256 seqOfPos) external view returns (bool) {
        return _repo.isOccupied(seqOfPos);
    } 

    function getPosition(uint256 seqOfPos) external view 
        returns (OfficersRepo.Position memory) 
    {
        return _repo.getPosition(seqOfPos);
    }

    // ==== Managers ====

    function isManager(uint256 acct) external view returns (bool) {
        return _repo.isManager(acct);
    }

    function getNumOfManagers() external view returns (uint256) {
        return _repo.getNumOfManagers();
    }

    function getManagersList() external view returns (uint256[] memory) {
        return _repo.getManagersList();
    }

    function getManagersPosList() external view returns(uint[] memory) {
        return _repo.getManagersPosList();
    }

    // function getManagersFullPosInfo() public view 
    //     returns(OfficersRepo.Position[] memory) 
    // {
    //     return _repo.getManagersFullPosInfo();
    // }

    // ==== Directors ====

    function isDirector(uint256 acct) external view returns (bool) {
        return _repo.isDirector(acct);
    }

    function getNumOfDirectors() external view returns (uint256) {
        return _repo.getNumOfDirectors();
    }

    function getDirectorsList() external view 
        returns (uint256[] memory) 
    {
        return _repo.getDirectorsList();
    }

    function getDirectorsPosList() external view 
        returns (uint256[] memory ) 
    {
        return _repo.getDirectorsPosList();
    }

    // function getDirectorsFullPosInfo() external view 
    //     returns(OfficersRepo.Position[] memory) 
    // {
    //     return _repo.getDirectorsFullPosInfo();
    // }

    // ==== Executives ====

    function hasPosition(uint256 acct, uint256 seqOfPos)
        external view returns(bool)
    {
        return _repo.hasPosition(acct, seqOfPos);
    }

    function getPosInHand(uint256 acct) 
        external view returns (uint256[] memory) 
    {
        return _repo.getPosInHand(acct);
    }

    function getFullPosInfoInHand(uint acct) 
        external view returns (OfficersRepo.Position[] memory) 
    {
        return _repo.getFullPosInfoInHand(acct);
    }

    function hasTitle(uint acct, uint title) external view returns (bool flag)
    {
        flag = _repo.hasTitle(acct, title, _gk.getROM());
    }

    function hasNominationRight(uint seqOfPos, uint acct) external view returns (bool)
    {
        return _repo.hasNominationRight(seqOfPos, acct, _gk.getROM());
    }

    // ==== seatsCalculator ====

    // function getBoardSeatsQuota(uint256 acct) external view 
    //     returns(uint256) 
    // {
    //     return _repo.getBoardSeatsQuota(acct);
    // } 

    function getBoardSeatsOccupied(uint acct) external view 
        returns (uint256 )
    {
        return _repo.getBoardSeatsOccupied(acct);
    }
}
