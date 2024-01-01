// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./PledgesRepo.sol";

interface IRegisterOfPledges {

    //##################
    //##    Event     ##
    //##################

    event CreatePledge(
        uint256 indexed seqOfShare,
        uint256 indexed seqOfPld,
        uint256 creditor,
        uint256 indexed paid,
        uint256 par
    );

    event TransferPledge(
        uint256 indexed seqOfShare,
        uint256 indexed seqOfPld,
        uint256 indexed newSeqOfPld,
        uint256 buyer,
        uint256 paid,
        uint256 par
    );

    event RefundDebt(
        uint256 indexed seqOfShare,
        uint256 indexed seqOfPld,
        uint256 indexed refundAmt
    );

    event ExtendPledge(
        uint256 indexed seqOfShare,
        uint256 indexed seqOfPld,
        uint256 indexed extDays
    );

    event LockPledge(uint256 indexed seqOfShare, uint256 indexed seqOfPld, bytes32 indexed hashLock);

    event ReleasePledge(uint256 indexed seqOfShare, uint256 indexed seqOfPld, string indexed hashKey);

    event ExecPledge(uint256 indexed seqOfShare, uint256 indexed seqOfPld);

    event RevokePledge(uint256 indexed seqOfShare, uint256 indexed seqOfPld);

    //##################
    //##  Write I/O  ##
    //##################

    function createPledge(
        bytes32 snOfPld,
        uint paid,
        uint par,
        uint guaranteedAmt,
        uint execDays
    ) external returns(PledgesRepo.Head memory head);

    function issuePledge(
        PledgesRepo.Head memory head,
        uint paid,
        uint par,
        uint guaranteedAmt,
        uint execDays
    ) external returns(PledgesRepo.Head memory regHead);

    function regPledge(
        PledgesRepo.Pledge memory pld
    ) external returns(PledgesRepo.Head memory head);

    function transferPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint buyer,
        uint amt,
        uint caller
    ) external returns (PledgesRepo.Pledge memory newPld);

    function refundDebt(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint amt,
        uint caller
    ) external returns (PledgesRepo.Pledge memory newPld);

    function extendPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint extDays,
        uint caller
    ) external;

    // ==== Lock/Release/Exec/Revoke ====

    function lockPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        bytes32 hashLock,
        uint caller
    ) external;

    function releasePledge(uint256 seqOfShare, uint256 seqOfPld, string memory hashKey)
        external returns (uint64);

    function execPledge(
        uint seqOfShare, 
        uint256 seqOfPld,
        uint caller
    ) external;

    function revokePledge(uint256 seqOfShare, uint256 seqOfPld, uint caller)
        external; 

    //##################
    //##    读接口    ##
    //##################

    function counterOfPledges(uint256 seqOfShare) 
        external view returns (uint16);

    function isPledge(uint256 seqOfShare, uint256 seqOfPld) 
        external view returns (bool);

    function getSNList() external view
        returns(bytes32[] memory);

    function getPledge(uint256 seqOfShare, uint256 seqOfPld)
        external view returns (PledgesRepo.Pledge memory);

    function getPledgesOfShare(uint256 seqOfShare) 
        external view returns (PledgesRepo.Pledge[] memory);

    function getAllPledges() external view 
        returns (PledgesRepo.Pledge[] memory);

}
