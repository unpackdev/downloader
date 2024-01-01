// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IAntiDilution.sol";
import "./IAlongs.sol";

import "./IShareholdersAgreement.sol";

import "./IInvestmentAgreement.sol";

import "./IFilesFolder.sol";
import "./ISigPage.sol";

import "./RulesParser.sol";
import "./SharesRepo.sol";
import "./FRClaims.sol";

interface ISHAKeeper {

    // ======== TagAlong & DragAlong ========

    function execAlongRight(
        address ia,
        uint256 seqOfDeal,
        bool dragAlong,
        uint256 seqOfShare,
        uint paid,
        uint par,
        uint256 caller,
        bytes32 sigHash
    ) external;

    function acceptAlongDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external;

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint256 caller,
        bytes32 sigHash
    ) external;

    function takeGiftShares(
        address ia,
        uint256 seqOfDeal,
        uint caller
    ) external;

    // ======== FirstRefusal ========

    function execFirstRefusal(
        uint256 seqOfFRRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external;

    function computeFirstRefusal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller
    ) external;
}
