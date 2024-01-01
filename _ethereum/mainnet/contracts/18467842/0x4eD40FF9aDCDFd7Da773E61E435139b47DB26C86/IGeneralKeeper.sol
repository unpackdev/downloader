// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IMeetingMinutes.sol";

import "./RolesRepo.sol";
import "./UsersRepo.sol";

import "./IROCKeeper.sol";
import "./IRODKeeper.sol";
import "./IBMMKeeper.sol";
import "./IROMKeeper.sol";
import "./IGMMKeeper.sol";
import "./IROAKeeper.sol";
import "./IROOKeeper.sol";
import "./IROPKeeper.sol";
import "./ISHAKeeper.sol";
import "./ILOOKeeper.sol";

import "./IRegisterOfAgreements.sol";
import "./IRegisterOfConstitution.sol";
import "./IRegisterOfDirectors.sol";
import "./IRegisterOfMembers.sol";
import "./IRegisterOfOptions.sol";
import "./IRegisterOfPledges.sol";
import "./IRegisterOfShares.sol";
import "./IListOfOrders.sol";

interface IGeneralKeeper {

    struct CompInfo {
        uint40 regNum;
        uint48 regDate;
        uint8 currency;
        bytes20 symbol;
        string name;
    }

    // ###############
    // ##   Event   ##
    // ###############

    event ExecAction(uint256 indexed contents, bool indexed result);

    // ######################
    // ##   AccessControl  ##
    // ######################

    function setCompInfo (
        uint8 _currency,
        bytes20 _symbol,
        string memory _name
    ) external;

    function createCorpSeal() external;

    function getCompInfo() external view returns(CompInfo memory);

    function getCompUser() external view returns (UsersRepo.User memory);

    function regKeeper(uint256 title, address keeper) external;

    function isKeeper(address caller) external view returns (bool flag);

    function getKeeper(uint256) external view returns(address keeper);

    function regBook(uint256 title, address keeper) external;

    function getBook(uint256 title) external view returns (address);

    // ##################
    // ##  ROCKeeper   ##
    // ##################

    function createSHA(uint version) external;

    function circulateSHA(address body, bytes32 docUrl, bytes32 docHash) external;

    function signSHA(address sha, bytes32 sigHash) external;

    function activateSHA(address body) external;

    function acceptSHA(bytes32 sigHash) external;

    // ###################
    // ##   RODKeeper   ##
    // ###################

    function takeSeat(uint256 seqOfMotion, uint256 seqOfPos) external;

    function removeDirector (uint256 seqOfMotion, uint256 seqOfPos) external;

    function takePosition(uint256 seqOfMotion, uint256 seqOfPos) external;

    function removeOfficer (uint256 seqOfMotion, uint256 seqOfPos) external;

    function quitPosition(uint256 seqOfPos) external;

    // ###################
    // ##   BMMKeeper   ##
    // ###################

    function nominateOfficer(uint256 seqOfPos, uint candidate) external;

    function createMotionToRemoveOfficer(uint256 seqOfPos) external;

    function createMotionToApproveDoc(uint doc, uint seqOfVR, uint executor) external;

    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external;

    function entrustDelegaterForBoardMeeting(uint256 seqOfMotion, uint delegate) external;

    function proposeMotionToBoard (uint seqOfMotion) external;

    function castVote(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external;

    function voteCounting(uint256 seqOfMotion) external;

    function execAction(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external;

    // ###################
    // ##   ROMKeeper   ##
    // ###################

    function setMaxQtyOfMembers(uint max) external;

    function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock) external;

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey) external;

    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external;

    function payInCapital(uint seqOfShare, uint amt) external payable;

    // function decreaseCapital(uint256 seqOfShare, uint paid, uint par) external;

    // ###################
    // ##   GMMKeeper   ##
    // ###################

    function nominateDirector(uint256 seqOfPos, uint candidate) external;

    function createMotionToRemoveDirector(uint256 seqOfPos) external;

    function proposeDocOfGM(uint doc, uint seqOfVR, uint executor) external;

    function createActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external;

    function entrustDelegaterForGeneralMeeting(uint256 seqOfMotion, uint delegate) external;

    function proposeMotionToGeneralMeeting(uint256 seqOfMotion) external;

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash
    ) external;

    function voteCountingOfGM(uint256 seqOfMotion) external;

    function execActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external;

    // ###################
    // ##   ROAKeeper   ##
    // ###################

    function createIA(uint256 snOfIA) external;

    function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external;

    function signIA(address ia, bytes32 sigHash) external;

    // ======== Deal Closing ========

    function pushToCoffer(address ia, uint256 seqOfDeal, bytes32 hashLock, uint closingDeadline) external;

    function closeDeal(address ia, uint256 seqOfDeal, string memory hashKey) external;

    function issueNewShare(address ia, uint256 seqOfDeal) external;

    function transferTargetShare(address ia, uint256 seqOfDeal) external;

    function terminateDeal(address ia, uint256 seqOfDeal) external;

    function requestToBuy(address ia, uint seqOfDeal, uint paidOfTarget, uint seqOfPledge) external;

    function payOffRejectedDeal(
        address ia,
        uint seqOfDeal,
        uint seqOfSwap
    ) external payable;

    function pickupPledgedShare(
        address ia,
        uint seqOfDeal,
        uint seqOfSwap
    ) external;

    function payOffApprovedDeal(
        address ia,
        uint seqOfDeal
    ) external payable;

    // #################
    // ##  ROOKeeper  ##
    // #################

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external;

    function execOption(uint256 seqOfOpt) external;

    function payOffSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap
    ) external payable;

    function terminateSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap
    ) external;

    // ###################
    // ##   ROPKeeper   ##
    // ###################

    function createPledge(bytes32 snOfPld, uint paid, uint par, uint guaranteedAmt, uint execDays) external;

    function transferPledge(uint256 seqOfShare, uint256 seqOfPld, uint buyer, uint amt) 
    external;

    function refundDebt(uint256 seqOfShare, uint256 seqOfPld, uint amt) external;

    function extendPledge(uint256 seqOfShare, uint256 seqOfPld, uint extDays) external;

    function lockPledge(uint256 seqOfShare, uint256 seqOfPld, bytes32 hashLock) external;

    function releasePledge(uint256 seqOfShare, uint256 seqOfPld, string memory hashKey) external;

    function execPledge(bytes32 snOfDeal, uint256 seqOfPld, uint version, uint buyer, uint groupOfBuyer) external;

    function revokePledge(uint256 seqOfShare, uint256 seqOfPld) external;


    // ###################
    // ##   SHAKeeper   ##
    // ###################

    // ======= TagAlong ========

    function execTagAlong(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint paid,
        uint par,
        bytes32 sigHash
    ) external;

    // ======= DragAlong ========

    function execDragAlong(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint paid,
        uint par,
        bytes32 sigHash
    ) external;

    function acceptAlongDeal(
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external;

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        bytes32 sigHash
    ) external;

    function takeGiftShares(address ia, uint256 seqOfDeal) external;

    // ======== First Refusal ========

    function execFirstRefusal(
        uint256 seqOfRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external;

    function computeFirstRefusal(
        address ia,
        uint256 seqOfDeal
    ) external;

    // ############
    // ##  Fund  ##
    // ############

    function getCentPrice() external view returns(uint);

    function saveToCoffer(uint acct, uint value) external;

    function pickupDeposit() external;

    function proposeToDistributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor
    ) external;

    function distributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfMotion
    ) external; 

    function proposeToTransferFund(
        bool toBMM,
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor
    ) external;

    function transferFund(
        bool fromBMM,
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion
    ) external;

    // #################
    // ##  LOOKeeper  ##
    // #################

    function regInvestor(uint groupRep, bytes32 idHash) external;

    function approveInvestor(uint userNo, uint seqOfLR) external;

    function revokeInvestor(uint userNo, uint seqOfLR) external;

    function placeInitialOffer(
        uint classOfShare,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external;

    function withdrawInitialOffer(
        uint classOfShare,
        uint seqOfOrder,
        uint seqOfLR
    ) external;

    function placeSellOrder(
        uint seqOfClass,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR,
        bool sortFromHead
    ) external;

    function withdrawSellOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external;    

    function placeBuyOrder(uint classOfShare, uint paid, uint price) external payable;
    
    // ###############
    // ##  Routing  ##
    // ###############

    function getROC() external view returns (IRegisterOfConstitution );

    function getSHA() external view returns (IShareholdersAgreement);

    function getROD() external view returns (IRegisterOfDirectors);

    function getBMM() external view returns (IMeetingMinutes);

    function getROM() external view returns (IRegisterOfMembers);

    function getGMM() external view returns (IMeetingMinutes);

    function getROA() external view returns (IRegisterOfAgreements);

    function getROO() external view returns (IRegisterOfOptions);

    function getROP() external view returns (IRegisterOfPledges);

    function getROS() external view returns (IRegisterOfShares);

    function getLOO() external view returns (IListOfOrders);

    function depositOfMine(uint user) external view returns(uint);
    
    function totalDeposits() external view returns(uint);
}
