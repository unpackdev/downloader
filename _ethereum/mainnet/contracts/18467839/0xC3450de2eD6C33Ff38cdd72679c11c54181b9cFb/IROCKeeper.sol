// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IShareholdersAgreement.sol";
import "./ILockUp.sol";

import "./ISigPage.sol";

import "./OfficersRepo.sol";
import "./RulesParser.sol";
import "./DocsRepo.sol";

interface IROCKeeper {
    // ############
    // ##  SHA   ##
    // ############

    // function setTempOfBOH(address temp, uint8 typeOfDoc) external;

    function createSHA(uint version, address primeKeyOfCaller, uint caller) external;

    // function removeSHA(address sha, uint256 caller) external;

    function circulateSHA(
        address sha,
        bytes32 docUrl,
        bytes32 docHash,
        uint256 caller
    ) external;

    function signSHA(
        address sha,
        bytes32 sigHash,
        uint256 caller
    ) external;

    function activateSHA(address sha, uint256 caller) external;

    function acceptSHA(bytes32 sigHash, uint256 caller) external;
}
