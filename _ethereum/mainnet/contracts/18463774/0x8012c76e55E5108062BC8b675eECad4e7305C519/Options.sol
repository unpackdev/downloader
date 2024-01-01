// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./AccessControl.sol";

import "./IOptions.sol";

contract Options is IOptions, AccessControl {
    using OptionsRepo for OptionsRepo.Repo;
    using OptionsRepo for OptionsRepo.Option;
    using OptionsRepo for OptionsRepo.Head;
    using OptionsRepo for bytes32;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;

    OptionsRepo.Repo private _repo;

    // ################
    // ## Write I/O  ##
    // ################

    function createOption(
        bytes32 snOfOpt,
        bytes32 snOfCond,
        uint rightholder,
        uint paid,
        uint par
    ) external onlyAttorney returns (OptionsRepo.Head memory head) {
        head = _repo.createOption(snOfOpt, snOfCond, rightholder, paid, par);
    }

    function delOption(uint256 seqOfOpt) external onlyAttorney returns(bool flag){
        flag = _repo.removeOption(seqOfOpt);
    }

    function addObligorIntoOpt(
        uint256 seqOfOpt,
        uint256 obligor
    ) external onlyAttorney returns (bool flag) {
        if (isOption(seqOfOpt)) 
            flag = _repo.records[seqOfOpt].obligors.add(obligor);
    }

    function removeObligorFromOpt(
        uint256 seqOfOpt,
        uint256 obligor
    ) external onlyAttorney returns (bool flag) {
        if (isOption(seqOfOpt)) 
            flag = _repo.records[seqOfOpt].obligors.remove(obligor);
    }

    // ################
    // ##  查询接口   ##
    // ################

    // ==== Option ====

    function counterOfOptions() external view returns (uint32) {
        return _repo.counterOfOptions();
    }

    function qtyOfOptions() external view returns (uint) {
        return _repo.qtyOfOptions();
    }

    function isOption(uint256 seqOfOpt) public view returns (bool) {
        return _repo.isOption(seqOfOpt);
    }

    function getOption(uint256 seqOfOpt) external view
        returns (OptionsRepo.Option memory option)   
    {
        return _repo.getOption(seqOfOpt);
    }

    function getAllOptions() external view returns (OptionsRepo.Option[] memory) 
    {
        return _repo.getAllOptions();
    }

    // ==== Obligor ====

    function isObligor(uint256 seqOfOpt, uint256 acct) external 
        view returns (bool) 
    {
        return _repo.isObligor(seqOfOpt, acct);
    }

    function getObligorsOfOption(uint256 seqOfOpt) external view
        returns (uint256[] memory)
    {
        return _repo.getObligorsOfOption(seqOfOpt);
    }

    function getSeqList() external view returns(uint[] memory) {
        return _repo.getSeqList();
    }

}
