// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IFilesFolder.sol";
import "./IInvestmentAgreement.sol";

import "./DTClaims.sol";
import "./FRClaims.sol";
import "./TopChain.sol";

interface IRegisterOfAgreements is IFilesFolder {

    //#################
    //##    Event    ##
    //#################

    event ClaimFirstRefusal(address indexed ia, uint256 indexed seqOfDeal, uint256 indexed caller);

    event AcceptAlongClaims(address indexed ia, uint indexed seqOfDeal);

    event ExecAlongRight(address indexed ia, bytes32 indexed snOfDTClaim, bytes32 sigHash);

    event ComputeFirstRefusal(address indexed ia, uint256 indexed seqOfDeal);

    //#################
    //##  Write I/O  ##
    //#################

    // ======== RegisterOfAgreements ========

    // function circulateIA(address ia, bytes32 docUrl, bytes32 docHash) external;

    function claimFirstRefusal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external;

    function computeFirstRefusal(
        address ia,
        uint256 seqOfDeal
    ) external returns (FRClaims.Claim[] memory output);

    function execAlongRight(
        address ia,
        bool dragAlong,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint paid,
        uint par,
        uint256 caller,
        bytes32 sigHash
    ) external;

    function acceptAlongClaims(
        address ia, 
        uint seqOfDeal
    ) external returns(DTClaims.Claim[] memory);

    function createMockOfIA(address ia) external;

    function mockDealOfSell (address ia, uint seller, uint amount) external; 

    function mockDealOfBuy (address ia, uint buyer, uint groupRep, uint amount) external;

    // function addAlongDeal(
    //     address ia,
    //     uint256 seqOfLinkRule,
    //     uint32 seqOfShare,
    //     uint64 amount
    // ) external returns (bool flag);

    //##################
    //##    读接口    ##
    //##################

    // ==== FR Claims ====

    function hasFRClaims(address ia, uint seqOfDeal) external view returns (bool);

    function isFRClaimer(address ia, uint256 acct) external returns (bool);

    function getSubjectDealsOfFR(address ia) external view returns(uint[] memory);

    function getFRClaimsOfDeal(address ia, uint256 seqOfDeal)
        external view returns(FRClaims.Claim[] memory);

    function allFRClaimsAccepted(address ia) external view returns (bool);

    // ==== DT Claims ====

    function hasDTClaims(address ia, uint256 seqOfDeal) 
        external view returns(bool);

    function getSubjectDealsOfDT(address ia)
        external view returns(uint256[] memory);

    function getDTClaimsOfDeal(address ia, uint256 seqOfDeal)
        external view returns(DTClaims.Claim[] memory);

    function getDTClaimForShare(address ia, uint256 seqOfDeal, uint256 seqOfShare)
        external view returns(DTClaims.Claim memory);

    function allDTClaimsAccepted(address ia) external view returns(bool);

    // ==== Mock Results ====

    function mockResultsOfIA(address ia) 
        external view 
        returns (uint40 controllor, uint16 ratio);

    function mockResultsOfAcct(address ia, uint256 acct) 
        external view 
        returns (uint40 groupRep, uint16 ratio);

    // ==== AllClaimsAccepted ====

    function allClaimsAccepted(address ia) external view returns(bool);

}
