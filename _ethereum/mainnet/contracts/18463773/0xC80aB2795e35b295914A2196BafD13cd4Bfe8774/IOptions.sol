// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./OptionsRepo.sol";
import "./EnumerableSet.sol";

interface IOptions {
    // ################
    // ## Write I/O ##
    // ################

    function createOption(
        bytes32 snOfOpt,
        bytes32 snOfCond,
        uint rightholder,
        uint paid,
        uint par
    ) external returns (OptionsRepo.Head memory head); 

    function delOption(uint256 seqOfOpt) external returns(bool flag);

    function addObligorIntoOpt(
        uint256 seqOfOpt,
        uint256 obligor
    ) external returns (bool flag);

    function removeObligorFromOpt(
        uint256 seqOfOpt,
        uint256 obligor
    ) external returns (bool flag);


    // ################
    // ##  查询接口   ##
    // ################

    // ==== Option ====

    function counterOfOptions() external view returns (uint32);

    function qtyOfOptions() external view returns (uint);

    function isOption(uint256 seqOfOpt) external view returns (bool);

    function getOption(uint256 seqOfOpt) external view
        returns (OptionsRepo.Option memory option); 

    function getAllOptions() external view returns (OptionsRepo.Option[] memory);

    // ==== Obligor ====

    function isObligor(uint256 seqOfOpt, uint256 acct) external 
        view returns (bool); 

    function getObligorsOfOption(uint256 seqOfOpt) external view
        returns (uint256[] memory);

    // ==== snOfOpt ====
    function getSeqList() external view returns(uint[] memory);

}
