// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";
import "./MotionsRepo.sol";
import "./SwapsRepo.sol";
import "./SharesRepo.sol";

import "./IMeetingMinutes.sol";
import "./IRegisterOfShares.sol";


library DealsRepo {
    using EnumerableSet for EnumerableSet.UintSet;
    using SwapsRepo for SwapsRepo.Repo;

    // _deals[0].head {
    //     seqOfDeal: counterOfClosedDeal;
    //     preSeq: counterOfDeal;
    //     typeOfDeal: typeOfIA;
    // }    

    enum TypeOfDeal {
        ZeroPoint,
        CapitalIncrease,
        ShareTransferExt,
        ShareTransferInt,
        PreEmptive,
        TagAlong,
        DragAlong,
        FirstRefusal,
        FreeGift
    }

    enum TypeOfIA {
        ZeroPoint,
        CapitalIncrease,
        ShareTransferExt,
        ShareTransferInt,
        CI_STint,
        SText_STint,
        CI_SText_STint,
        CI_SText
    }

    enum StateOfDeal {
        Drafting,
        Locked,
        Cleared,
        Closed,
        Terminated
    }

    struct Head {
        uint8 typeOfDeal;
        uint16 seqOfDeal;
        uint16 preSeq;
        uint16 classOfShare;
        uint32 seqOfShare;
        uint40 seller;
        uint32 priceOfPaid;
        uint32 priceOfPar;
        uint48 closingDeadline;
        uint16 votingWeight;
    }

    struct Body {
        uint40 buyer;
        uint40 groupOfBuyer;
        uint64 paid;
        uint64 par;
        uint8 state;
        uint16 para;
        uint16 argu;
        bool flag;
    }

    struct Deal {
        Head head;
        Body body;
        bytes32 hashLock;
    }

    struct Repo {
        mapping(uint256 => Deal) deals;
        mapping(uint256 => SwapsRepo.Repo) swaps;
        //seqOfDeal => seqOfShare => bool
        mapping(uint => mapping(uint => bool)) priceDiffRequested;
        EnumerableSet.UintSet seqList;
    }

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyCleared(Repo storage repo, uint256 seqOfDeal) {
        require(
            repo.deals[seqOfDeal].body.state == uint8(StateOfDeal.Cleared),
            "DR.mf.OC: wrong stateOfDeal"
        );
        _;
    }

    modifier dealExist(Repo storage repo, uint seqOfDeal) {
        require(isDeal(repo, seqOfDeal), "DR.mf.dealExist: not");
        _;
    }

    //#################
    //##  Write I/O  ##
    //#################

    function snParser(bytes32 sn) public pure returns(Head memory head) {
        uint _sn = uint(sn);

        head = Head({
            typeOfDeal: uint8(_sn >> 248),
            seqOfDeal: uint16(_sn >> 232),
            preSeq: uint16(_sn >> 216),
            classOfShare: uint16(_sn >> 200),
            seqOfShare: uint32(_sn >> 168),
            seller: uint40(_sn >> 128),
            priceOfPaid: uint32(_sn >> 96),
            priceOfPar: uint32(_sn >> 64),
            closingDeadline: uint48(_sn >> 16),
            votingWeight: uint16(_sn) 
        });

    } 

    function codifyHead(Head memory head) public pure returns(bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.typeOfDeal,
                            head.seqOfDeal,
                            head.preSeq,
                            head.classOfShare,
                            head.seqOfShare,
                            head.seller,
                            head.priceOfPaid,
                            head.priceOfPaid,
                            head.closingDeadline,
                            head.votingWeight);        
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    }

    function addDeal(
        Repo storage repo,
        bytes32 sn,
        uint buyer,
        uint groupOfBuyer,
        uint paid,
        uint par
    ) public returns (uint16 seqOfDeal)  {

        Deal memory deal;

        deal.head = snParser(sn);

        deal.body.buyer = uint40(buyer);
        deal.body.groupOfBuyer = uint40(groupOfBuyer);
        deal.body.paid = uint64(paid);
        deal.body.par = uint64(par);

        seqOfDeal = regDeal(repo, deal);
    }

    function regDeal(Repo storage repo, Deal memory deal) 
        public returns(uint16 seqOfDeal) 
    {
        require(deal.body.par > 0, "DR.RD: zero par");
        require(deal.body.par >= deal.body.paid, "DR.RD: paid overflow");

        // if (!repo.seqList.contains(deal.head.seqOfDeal)) {
        deal.head.seqOfDeal = _increaseCounterOfDeal(repo);
        repo.seqList.add(deal.head.seqOfDeal);
        // }
        repo.deals[deal.head.seqOfDeal] = Deal({
            head: deal.head,
            body: deal.body,
            hashLock: bytes32(0)
        });
        seqOfDeal = deal.head.seqOfDeal;
    }

    function _increaseCounterOfDeal(Repo storage repo) private returns(uint16 seqOfDeal){
        repo.deals[0].head.preSeq++;
        seqOfDeal = repo.deals[0].head.preSeq;
    }

    function delDeal(Repo storage repo, uint256 seqOfDeal) public returns (bool flag) {
        if (repo.seqList.remove(seqOfDeal)) {
            delete repo.deals[seqOfDeal];
            repo.deals[0].head.preSeq--;
            flag = true;
        }
    }

    function lockDealSubject(Repo storage repo, uint256 seqOfDeal) public returns (bool flag) {
        if (repo.deals[seqOfDeal].body.state == uint8(StateOfDeal.Drafting)) {
            repo.deals[seqOfDeal].body.state = uint8(StateOfDeal.Locked);
            flag = true;
        }
    }

    function releaseDealSubject(Repo storage repo, uint256 seqOfDeal) public returns (bool flag)
    {
        uint8 state = repo.deals[seqOfDeal].body.state;

        if ( state < uint8(StateOfDeal.Closed) ) {

            repo.deals[seqOfDeal].body.state = uint8(StateOfDeal.Drafting);
            flag = true;

        } else if (state == uint8(StateOfDeal.Terminated)) {

            flag = true;            
        }
    }

    function clearDealCP(
        Repo storage repo,
        uint256 seqOfDeal,
        bytes32 hashLock,
        uint closingDeadline
    ) public {
        Deal storage deal = repo.deals[seqOfDeal];

        require(deal.body.state == uint8(StateOfDeal.Locked), 
            "IA.CDCP: wrong Deal state");

        deal.body.state = uint8(StateOfDeal.Cleared);
        deal.hashLock = hashLock;

        if (closingDeadline > 0) {
            if (block.timestamp < closingDeadline) 
                deal.head.closingDeadline = uint48(closingDeadline);
            else revert ("IA.clearDealCP: updated closingDeadline not FUTURE time");
        }
    }

    function closeDeal(Repo storage repo, uint256 seqOfDeal, string memory hashKey)
        public onlyCleared(repo, seqOfDeal) returns (bool flag)
    {
        require(
            repo.deals[seqOfDeal].hashLock == keccak256(bytes(hashKey)),
            "IA.closeDeal: hashKey NOT correct"
        );

        return _closeDeal(repo, seqOfDeal);
    }

    function directCloseDeal(Repo storage repo, uint seqOfDeal) 
        public returns (bool flag) 
    {
        require(repo.deals[seqOfDeal].body.state == uint8(StateOfDeal.Locked), 
            "IA.directCloseDeal: wrong state of deal");
        
        return _closeDeal(repo, seqOfDeal);
    }

    function _closeDeal(Repo storage repo, uint seqOfDeal)
        private returns(bool flag) 
    {
    
        Deal storage deal = repo.deals[seqOfDeal];

        require(
            block.timestamp < deal.head.closingDeadline,
            "IA.closeDeal: MISSED closing date"
        );

        deal.body.state = uint8(StateOfDeal.Closed);

        _increaseCounterOfClosedDeal(repo);

        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    function terminateDeal(Repo storage repo, uint256 seqOfDeal) public returns(bool flag){
        Body storage body = repo.deals[seqOfDeal].body;

        require(body.state == uint8(StateOfDeal.Locked) ||
            body.state == uint8(StateOfDeal.Cleared)
            , "DR.TD: wrong stateOfDeal");

        body.state = uint8(StateOfDeal.Terminated);

        _increaseCounterOfClosedDeal(repo);
        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    function takeGift(Repo storage repo, uint256 seqOfDeal)
        public returns (bool flag)
    {
        Deal storage deal = repo.deals[seqOfDeal];

        require(
            deal.head.typeOfDeal == uint8(TypeOfDeal.FreeGift),
            "not a gift deal"
        );

        require(
            repo.deals[deal.head.preSeq].body.state == uint8(StateOfDeal.Closed),
            "Capital Increase not closed"
        );

        require(deal.body.state == uint8(StateOfDeal.Locked), "wrong state");

        deal.body.state = uint8(StateOfDeal.Closed);

        _increaseCounterOfClosedDeal(repo);
        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    function _increaseCounterOfClosedDeal(Repo storage repo) private {
        repo.deals[0].head.seqOfDeal++;
    }

    function calTypeOfIA(Repo storage repo) public {
        uint[3] memory types;

        uint[] memory seqList = repo.seqList.values();
        uint len = seqList.length;
        
        while (len > 0) {
            uint typeOfDeal = repo.deals[seqList[len-1]].head.typeOfDeal;
            len--;

            if (typeOfDeal == 1) {
                if (types[0] == 0) types[0] = 1;
                continue;
            } else if (typeOfDeal == 2) {
                if (types[1] == 0) types[1] = 2;
                continue;
            } else if (typeOfDeal == 3) {
                if (types[2] == 0) types[2] = 3;
                continue;
            }
        }

        uint8 sum = uint8(types[0] + types[1] + types[2]);
        repo.deals[0].head.typeOfDeal = (sum == 3)
                ? (types[2] == 0)
                    ? 7
                    : 3
                : sum;
    }

    // ==== Swap ====

    function createSwap(
        Repo storage repo,
        uint seqOfMotion,
        uint seqOfDeal,
        uint paidOfTarget,
        uint seqOfPledge,
        uint caller,
        IRegisterOfShares _ros,
        IMeetingMinutes _gmm
    ) public returns(SwapsRepo.Swap memory swap) {
        Deal storage deal = repo.deals[seqOfDeal];

        require(caller == deal.head.seller, 
            "DR.createSwap: not seller");

        require(deal.body.state == uint8(StateOfDeal.Terminated),
            "DR.createSwap: wrong state");

        MotionsRepo.Motion memory motion = 
            _gmm.getMotion(seqOfMotion);

        require(
            motion.body.state == uint8(MotionsRepo.StateOfMotion.Rejected_ToBuy),
            "DR.createSwap: NO need to buy"
        );

        require(block.timestamp < motion.body.voteEndDate + 
            uint48(motion.votingRule.execDaysForPutOpt) * 86400, 
            "DR.createSwap: missed deadline");


        swap = SwapsRepo.Swap({
            seqOfSwap: 0,
            seqOfPledge: uint32(seqOfPledge),
            paidOfPledge: 0,
            seqOfTarget: deal.head.seqOfShare,
            paidOfTarget: uint64(paidOfTarget),
            priceOfDeal: deal.head.priceOfPaid,
            isPutOpt: true,
            state: uint8(SwapsRepo.StateOfSwap.Issued)
        });

        SharesRepo.Head memory headOfPledge = _ros.getShare(swap.seqOfPledge).head;

        require(_gmm.getBallot(seqOfMotion, _gmm.getDelegateOf(seqOfMotion, 
            headOfPledge.shareholder)).attitude == 2,
            "DR.createSwap: not vetoer");

        require (deal.body.paid >= repo.swaps[seqOfDeal].sumPaidOfTarget() +
            swap.paidOfTarget, "DR.createSwap: paidOfTarget overflow");

        swap.paidOfPledge = (swap.priceOfDeal - _ros.getShare(swap.seqOfTarget).head.priceOfPaid) * 
            swap.paidOfTarget / headOfPledge.priceOfPaid;

        return repo.swaps[seqOfDeal].regSwap(swap);
    }

    function payOffSwap(
        Repo storage repo,
        uint seqOfMotion,
        uint seqOfDeal,
        uint seqOfSwap,
        uint msgValue,
        uint centPrice,
        IMeetingMinutes _gmm
    ) public returns(SwapsRepo.Swap memory){

        MotionsRepo.Motion memory motion = _gmm.getMotion(seqOfMotion);

        require(block.timestamp < motion.body.voteEndDate + 
            uint48(motion.votingRule.execDaysForPutOpt) * 86400, 
            "DR.payOffSwap: missed deadline");
 
        return repo.swaps[seqOfDeal].payOffSwap(seqOfSwap, msgValue, centPrice);
    }

    function terminateSwap(
        Repo storage repo,
        uint seqOfMotion,
        uint seqOfDeal,
        uint seqOfSwap,
        IMeetingMinutes _gmm
    ) public returns (SwapsRepo.Swap memory){

        MotionsRepo.Motion memory motion = _gmm.getMotion(seqOfMotion);

        require(block.timestamp >= motion.body.voteEndDate + 
            uint48(motion.votingRule.execDaysForPutOpt) * 86400, 
            "DR.terminateSwap: still in exec period");

        return repo.swaps[seqOfDeal].terminateSwap(seqOfSwap);
    }

    function payOffApprovedDeal(
        Repo storage repo,
        uint seqOfDeal,
        // uint msgValue,
        // uint centPrice,
        uint caller
    ) public returns (bool flag){

        Deal storage deal = repo.deals[seqOfDeal];

        require(deal.head.typeOfDeal != uint8(TypeOfDeal.FreeGift),
            "DR.payApprDeal: free gift");

        require(caller == deal.body.buyer,
            "DR.payApprDeal: not buyer");

        require(deal.body.state == uint8(StateOfDeal.Locked) ||
            deal.body.state == uint8(StateOfDeal.Cleared) , 
            "DR.payApprDeal: wrong state");

        require(block.timestamp < deal.head.closingDeadline,
            "DR.payApprDeal: missed closingDeadline");

        // require((uint(deal.body.paid) * deal.head.priceOfPaid + 
        //     uint(deal.body.par - deal.body.paid) * deal.head.priceOfPar) * 
        //     centPrice / 100 <= msgValue, "DR.payApprDeal: insufficient msgValue");

        deal.body.state = uint8(StateOfDeal.Closed);

        _increaseCounterOfClosedDeal(repo);

        flag = (counterOfDeal(repo) == counterOfClosedDeal(repo));
    }

    function requestPriceDiff(
        Repo storage repo,
        uint seqOfDeal,
        uint seqOfShare
    ) public dealExist(repo, seqOfDeal) {
        require(!repo.priceDiffRequested[seqOfDeal][seqOfShare],
            "DR.requestPriceDiff: already requested");
        repo.priceDiffRequested[seqOfDeal][seqOfShare] = true;      
    }


    //  ################################
    //  ##       查询接口              ##
    //  ###############################

    function getTypeOfIA(Repo storage repo) external view returns (uint8) {
        return repo.deals[0].head.typeOfDeal;
    }

    function counterOfDeal(Repo storage repo) public view returns (uint16) {
        return repo.deals[0].head.preSeq;
    }

    function counterOfClosedDeal(Repo storage repo) public view returns (uint16) {
        return repo.deals[0].head.seqOfDeal;
    }

    function isDeal(Repo storage repo, uint256 seqOfDeal) public view returns (bool) {
        return repo.seqList.contains(seqOfDeal);
    }

    // function getHeadOfDeal(Repo storage repo, uint256 seq) 
    //     external view dealExist(repo, seq) returns (Head memory)
    // {
    //     return repo.deals[seq].head;
    // }

    // function getBodyOfDeal(Repo storage repo,  uint256 seq) 
    //     external view dealExist(repo, seq) returns (Body memory)
    // {
    //     return repo.deals[seq].body;
    // }

    // function getHashLockOfDeal(Repo storage repo, uint256 seq) 
    //     external view dealExist(repo, seq) returns (bytes32)
    // {
    //     return repo.deals[seq].hashLock;
    // }
    
    function getDeal(Repo storage repo, uint256 seq) 
        external view dealExist(repo, seq) returns (Deal memory)
    {
        return repo.deals[seq];
    }

    function getSeqList(Repo storage repo) external view returns (uint[] memory) {
        return repo.seqList.values();
    }
    
    // ==== Swap ====

    function counterOfSwaps(Repo storage repo, uint seqOfDeal)
        public view returns (uint16)
    {
        return repo.swaps[seqOfDeal].counterOfSwaps();
    }

    function sumPaidOfTarget(Repo storage repo, uint seqOfDeal)
        public view returns (uint64)
    {
        return repo.swaps[seqOfDeal].sumPaidOfTarget();
    }

    function isSwap(Repo storage repo, uint seqOfDeal, uint256 seqOfSwap)
        public view returns (bool)
    {
        return repo.swaps[seqOfDeal].isSwap(seqOfSwap);
    }

    function getSwap(Repo storage repo, uint seqOfDeal, uint256 seqOfSwap)
        public view returns (SwapsRepo.Swap memory)
    {
        return repo.swaps[seqOfDeal].getSwap(seqOfSwap);
    }

    function getAllSwaps(Repo storage repo, uint seqOfDeal)
        public view returns (SwapsRepo.Swap[] memory )
    {
        return repo.swaps[seqOfDeal].getAllSwaps();
    }

    function allSwapsClosed(Repo storage repo, uint seqOfDeal)
        public view returns (bool)
    {
        return repo.swaps[seqOfDeal].allSwapsClosed();
    }

    // ==== Value Calculation ==== 

    function checkValueOfSwap(
        Repo storage repo,
        uint seqOfDeal,
        uint seqOfSwap,
        uint centPrice
    ) public view dealExist(repo, seqOfDeal) returns (uint) {
        return repo.swaps[seqOfDeal].checkValueOfSwap(seqOfSwap, centPrice);
    }

    function checkValueOfDeal(
        Repo storage repo, 
        uint seqOfDeal, 
        uint centPrice
    ) public view returns (uint) {
        Deal memory deal = repo.deals[seqOfDeal];

        return (uint(deal.body.paid * deal.head.priceOfPaid) + 
            uint((deal.body.par - deal.body.paid) * deal.head.priceOfPar)) *
            centPrice / 100;
    }    
}
