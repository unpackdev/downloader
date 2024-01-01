// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library SharesRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Head {
        uint16 class; // 股票类别/轮次编号
        uint32 seqOfShare; // 股票序列号
        uint32 preSeq; // 前序股票序列号（股转时原标的股序列号）
        uint48 issueDate; // 股票签发日期（秒时间戳）
        uint40 shareholder; // 股东代码
        uint32 priceOfPaid; // 发行价格（实缴出资价）
        uint32 priceOfPar; // 发行价格（认缴出资价）
        uint16 votingWeight; // 表决权重（百分点）
        uint8 argu;
    }

    struct Body {
        uint48 payInDeadline; // 出资期限（秒时间戳）
        uint64 paid; // 实缴出资
        uint64 par; // 认缴出资（注册资本面值）
        uint64 cleanPaid; // 清洁实缴出资（扣除出质、远期、销售要约金额）
        uint8 state;
        uint8 para;
    }

    //Share 股票
    struct Share {
        Head head; //出资证明书编号（股票编号）
        Body body;
    }

    struct Class{
        Share info;
        EnumerableSet.UintSet seqList;
    }

    struct Repo {
        // seqOfClass => Class
        mapping(uint256 => Class) classes;
        // seqOfShare => Share
        mapping(uint => Share) shares;
    }

    //####################
    //##    Modifier    ##
    //####################

    modifier shareExist(
        Repo storage repo,
        uint seqOfShare
    ) {
        require(isShare(repo, seqOfShare),
            "SR.shareExist: not");
        _;
    }

    //#################
    //##    Write    ##
    //#################

    function snParser(bytes32 sn) public pure returns(Head memory head)
    {
        uint _sn = uint(sn);
        
        head = Head({
            class: uint16(_sn >> 240),
            seqOfShare: uint32(_sn >> 208),
            preSeq: uint32(_sn >> 176),
            issueDate: uint48(_sn >> 128),
            shareholder: uint40(_sn >> 88),
            priceOfPaid: uint32(_sn >> 56),
            priceOfPar: uint32(_sn >> 24),
            votingWeight: uint16(_sn >> 8),
            argu: uint8(_sn)
        });
    }

    function codifyHead(Head memory head) public pure returns (bytes32 sn)
    {
        bytes memory _sn = 
            abi.encodePacked(
                head.class, 
                head.seqOfShare, 
                head.preSeq, 
                head.issueDate, 
                head.shareholder, 
                head.priceOfPaid, 
                head.priceOfPar, 
                head.votingWeight, 
                head.argu
            );

        assembly {
            sn := mload(add(_sn, 0x20))
        }

    }

    // ==== issue/regist share ====

    function createShare(
        bytes32 sharenumber, 
        uint payInDeadline, 
        uint paid, 
        uint par
    ) public pure returns (Share memory share) {

        share.head = snParser(sharenumber);

        share.body = Body({
            payInDeadline: uint48(payInDeadline),
            paid: uint64(paid),
            par: uint64(par),
            cleanPaid: uint64(paid),
            state: 0,
            para: 0
        });
    }

    function addShare(Repo storage repo, Share memory share)
        public returns(Share memory newShare) 
    {
        newShare = regShare(repo, share);

        Share storage info = repo.classes[newShare.head.class].info;

        if (info.head.issueDate == 0) 
            repo.classes[newShare.head.class].info.head = 
                newShare.head;
    }

    function regShare(Repo storage repo, Share memory share)
        public returns(Share memory)
    {
        require(share.head.class > 0, "SR.regShare: zero class");
        require(share.body.par > 0, "SR.regShare: zero par");
        require(share.body.par >= share.body.paid, "SR.regShare: paid overflow");
        require(share.head.issueDate <= block.timestamp, "SR.regShare: future issueDate");
        require(share.head.issueDate <= share.body.payInDeadline, "SR.regShare: issueDate later than payInDeadline");
        require(share.head.shareholder > 0, "SR.regShare: zero shareholder");
        require(share.head.votingWeight > 0, "SR.regShare: zero votingWeight");

        if (share.head.class > counterOfClasses(repo))
            share.head.class = _increaseCounterOfClasses(repo);

        Class storage class = repo.classes[share.head.class];

        if (!class.seqList.contains(share.head.seqOfShare)) {
            share.head.seqOfShare = _increaseCounterOfShares(repo);
                        
            if (share.head.issueDate == 0)
                share.head.issueDate = uint48(block.timestamp);

            class.seqList.add(share.head.seqOfShare);
            repo.classes[0].seqList.add(share.head.seqOfShare);
        }

        repo.shares[share.head.seqOfShare] = share;

        return share;
    }

    // ==== counters ====

    function _increaseCounterOfShares(
        Repo storage repo
    ) private returns(uint32) {

        Head storage h = repo.shares[0].head;

        do {
            unchecked {
                h.seqOfShare++;                
            }
        } while (isShare(repo, h.seqOfShare) || 
            h.seqOfShare == 0);

        return h.seqOfShare;
    }

    function _increaseCounterOfClasses(Repo storage repo) 
        private returns(uint16)
    {
        repo.shares[0].head.class++;
        return repo.shares[0].head.class;
    }

    // ==== amountChange ====

    function payInCapital(
        Repo storage repo,
        uint seqOfShare,
        uint amt
    ) public shareExist(repo, seqOfShare) {

        Share storage share = repo.shares[seqOfShare];

        uint64 deltaPaid = uint64(amt);

        require(deltaPaid > 0, "SR.payInCap: zero amt");

        require(block.timestamp <= share.body.payInDeadline, 
            "SR.payInCap: missed deadline");

        require(share.body.paid + deltaPaid <= share.body.par, 
            "SR.payInCap: amt overflow");

        share.body.paid += deltaPaid;
        share.body.cleanPaid += deltaPaid;

    }

    function subAmtFromShare(
        Repo storage repo,
        uint seqOfShare,
        uint paid, 
        uint par
    ) public shareExist(repo, seqOfShare) {

        Share storage share = repo.shares[seqOfShare];
        Class storage class = repo.classes[share.head.class];

        uint64 deltaPaid = uint64(paid);
        uint64 deltaPar = uint64(par);

        require(deltaPar > 0, "SR.subAmt: zero par");
        require(share.body.cleanPaid >= deltaPaid, "SR.subAmt: insufficient cleanPaid");

        if (deltaPar == share.body.par) {            
            class.seqList.remove(seqOfShare);
            repo.classes[0].seqList.remove(seqOfShare);
            delete repo.shares[seqOfShare];
        } else {
            share.body.paid -= deltaPaid;
            share.body.par -= deltaPar;
            share.body.cleanPaid -= deltaPaid;

            require(share.body.par >= share.body.paid,
                "SR.subAmt: result paid overflow");
        }
    }

    function increaseCleanPaid(
        Repo storage repo,
        bool isIncrease,
        uint seqOfShare,
        uint paid
    ) public shareExist(repo, seqOfShare) {

        Share storage share = repo.shares[seqOfShare];

        uint64 deltaClean = uint64(paid);

        require(deltaClean > 0, "SR.incrClean: zero amt");

        if (isIncrease && share.body.cleanPaid + deltaClean <= share.body.paid) 
            share.body.cleanPaid += deltaClean;
        else if(!isIncrease && share.body.cleanPaid >= deltaClean)
            share.body.cleanPaid -= deltaClean;
        else revert("SR.incrClean: clean overflow");
    }

    // ---- EquityOfClass ----

    function increaseEquityOfClass(
        Repo storage repo,
        bool isIncrease,
        uint classOfShare,
        uint deltaPaid,
        uint deltaPar,
        uint deltaCleanPaid
    ) public {

        Body storage equity = repo.classes[classOfShare].info.body;

        if (isIncrease) {
            equity.paid += uint64(deltaPaid);
            equity.par += uint64(deltaPar);
            equity.cleanPaid += uint64(deltaCleanPaid);
        } else {
            equity.paid -= uint64(deltaPaid);
            equity.par -= uint64(deltaPar);
            equity.cleanPaid -= uint64(deltaCleanPaid);            
        }
    }

    function updatePriceOfPaid(
        Repo storage repo,
        uint seqOfShare,
        uint newPrice
    ) public shareExist(repo, seqOfShare) {
        Share storage share = repo.shares[seqOfShare];
        share.head.priceOfPaid = uint32(newPrice);
    }

    function updatePayInDeadline(
        Repo storage repo,
        uint seqOfShare,
        uint deadline
    ) public shareExist(repo, seqOfShare) {

        Share storage share = repo.shares[seqOfShare];

        uint48 newLine = uint48(deadline);

        require (block.timestamp < newLine, 
            "SR.updatePayInDeadline: not future");

        share.body.payInDeadline = newLine;
    }

    //####################
    //##    Read I/O    ##
    //####################

    // ---- Counter ----

    function counterOfShares(
        Repo storage repo
    ) public view returns(uint32) {
        return repo.shares[0].head.seqOfShare;
    }

    function counterOfClasses(
        Repo storage repo
    ) public view returns(uint16) {
        return repo.shares[0].head.class;
    }

    // ---- Share ----

    function isShare(
        Repo storage repo, 
        uint seqOfShare
    ) public view returns(bool) {
        return repo.shares[seqOfShare].head.issueDate > 0;
    }

    function getShare(
        Repo storage repo, 
        uint seqOfShare
    ) public view shareExist(repo, seqOfShare) returns (
        Share memory
    ) {
        return repo.shares[seqOfShare];
    }

    function getQtyOfShares(
        Repo storage repo
    ) public view returns(uint) {
        return repo.classes[0].seqList.length();
    }

    function getSeqListOfShares(
        Repo storage repo
    ) public view returns(uint[] memory) {
        return repo.classes[0].seqList.values();
    }

    function getSharesList(
        Repo storage repo
    ) public view returns(Share[] memory) {
        uint[] memory seqList = repo.classes[0].seqList.values();
        return _getShares(repo, seqList);
    }

    // ---- Class ----    

    function getQtyOfSharesInClass(
        Repo storage repo, 
        uint classOfShare
    ) public view returns (uint) {
        return repo.classes[classOfShare].seqList.length();
    }

    function getSeqListOfClass(
        Repo storage repo, 
        uint classOfShare
    ) public view returns (uint[] memory) {
        return repo.classes[classOfShare].seqList.values();
    }

    function getInfoOfClass(
        Repo storage repo,
        uint classOfShare
    ) public view returns (Share memory) {
        return repo.classes[classOfShare].info;
    }

    function getSharesOfClass(
        Repo storage repo, 
        uint classOfShare
    ) public view returns (Share[] memory) {
        uint[] memory seqList = 
            repo.classes[classOfShare].seqList.values();
        return _getShares(repo, seqList);
    }

    function _getShares(
        Repo storage repo,
        uint[] memory seqList
    ) private view returns(Share[] memory list) {

        uint len = seqList.length;
        list = new Share[](len);

        while(len > 0) {
            list[len - 1] = repo.shares[seqList[len - 1]];
            len--;
        }
    }

}
