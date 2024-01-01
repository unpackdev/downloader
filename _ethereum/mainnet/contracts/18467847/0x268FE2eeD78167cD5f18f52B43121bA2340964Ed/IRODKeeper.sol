// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfDirectors.sol";

// import "./UsersRepo.sol";
// import "./MotionsRepo.sol";
// import "./RulesParser.sol";

interface IRODKeeper {

    // ==== Directors ====

    function takeSeat(
        uint256 seqOfMotion,
        uint256 seqOfPos,
        uint caller 
    ) external;

    function removeDirector (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        uint caller
    ) external;

    // ==== Officers ====

    function takePosition(
        uint256 seqOfMotion,
        uint256 seqOfPos,
        uint caller 
    ) external;

    function removeOfficer (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        uint caller
    ) external;

    // ==== Quit ====

    function quitPosition(uint256 seqOfPos, uint caller) external;

}
