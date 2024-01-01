// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library PledgesRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    enum StateOfPld {
        Pending,
        Issued,
        Locked,
        Released,
        Executed,
        Revoked
    }

    struct Head {
        uint32 seqOfShare;
        uint16 seqOfPld;
        uint48 createDate;
        uint16 daysToMaturity;
        uint16 guaranteeDays;
        uint40 creditor;
        uint40 debtor;
        uint40 pledgor;
        uint8 state;
    }

    struct Body {
        uint64 paid;
        uint64 par;
        uint64 guaranteedAmt;
        uint16 preSeq;
        uint16 execDays;
        uint16 para;
        uint16 argu;
    }

    //Pledge 质权
    struct Pledge {
        Head head; //质押编号
        Body body;
        bytes32 hashLock;
    }

    struct Repo{
        // seqOfShare => seqOfPld => Pledge
        mapping(uint256 => mapping(uint256 => Pledge)) pledges;
        EnumerableSet.Bytes32Set snList;
    }

    //##################
    //##  Write I/O  ##
    //##################

    function snParser(bytes32 sn) public pure returns (Head memory head) {
        uint _sn = uint(sn);
        
        head = Head({
            seqOfShare: uint32(_sn >> 224),
            seqOfPld: uint16(_sn >> 208),
            createDate: uint48(_sn >> 160),
            daysToMaturity: uint16(_sn >> 144),
            guaranteeDays: uint16(_sn >> 128),
            creditor: uint40(_sn >> 88),
            debtor: uint40(_sn >> 48),
            pledgor: uint40(_sn >> 8),
            state: uint8(_sn)
        });
    } 

    function codifyHead(Head memory head) public pure returns (bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.seqOfShare,
                            head.seqOfPld,
                            head.createDate,
                            head.daysToMaturity,
                            head.guaranteeDays,
                            head.creditor,
                            head.pledgor,
                            head.debtor,
                            head.state);        
        assembly {
            sn := mload(add(_sn, 0x20))
        }

    } 

    function createPledge(
            Repo storage repo, 
            bytes32 snOfPld, 
            uint paid,
            uint par,
            uint guaranteedAmt,
            uint execDays
    ) public returns (Head memory head) 
    {
        head = snParser(snOfPld);
        head = issuePledge(repo, head, paid, par, guaranteedAmt, execDays);
    }

    function issuePledge(
        Repo storage repo,
        Head memory head,
        uint paid,
        uint par,
        uint guaranteedAmt,
        uint execDays
    ) public returns(Head memory regHead) {

        require (guaranteedAmt > 0, "PR.issuePld: zero guaranteedAmt");
        require (par > 0, "PR.issuePld: zero par");
        require (par >= paid, "PR.issuePld: paid overflow");

        Pledge memory pld;

        pld.head = head;

        pld.head.createDate = uint48(block.timestamp);
        pld.head.state = uint8(StateOfPld.Issued);

        pld.body = Body({
            paid: uint64(paid),
            par: uint64(par),
            guaranteedAmt: uint64(guaranteedAmt),
            preSeq:0,
            execDays: uint16(execDays),
            para:0,
            argu:0
        });

        regHead = regPledge(repo, pld);
    }

    function regPledge(
        Repo storage repo,
        Pledge memory pld
    ) public returns(Head memory){

        require(pld.head.seqOfShare > 0,"PR.regPledge: zero seqOfShare");
    
        pld.head.seqOfPld = _increaseCounterOfPld(repo, pld.head.seqOfShare);

        repo.pledges[pld.head.seqOfShare][pld.head.seqOfPld] = pld;
        repo.snList.add(codifyHead(pld.head));

        return pld.head;
    }

    // ==== Update Pledge ====

    function splitPledge(
        Repo storage repo,
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint buyer,
        uint amt,
        uint caller
    ) public returns(Pledge memory newPld) {

        Pledge storage pld = repo.pledges[seqOfShare][seqOfPld];

        require(caller == pld.head.creditor, "PR.splitPld: not creditor");

        require(!isExpired(pld), "PR.splitPld: pledge expired");
        require(pld.head.state == uint8(StateOfPld.Issued) ||
            pld.head.state == uint8(StateOfPld.Locked), "PR.splitPld: wrong state");
        require(amt > 0, "PR.splitPld: zero amt");
        // require(amt <= pld.body.guaranteedAmt, "PR.splitPld: amt overflow");

        newPld = pld;

        if (amt < pld.body.guaranteedAmt) {
            uint64 ratio = uint64(amt) * 10000 / newPld.body.guaranteedAmt;

            newPld.body.paid = pld.body.paid * ratio / 10000;
            newPld.body.par = pld.body.par * ratio / 10000;
            newPld.body.guaranteedAmt = uint64(amt);

            pld.body.paid -= newPld.body.paid;
            pld.body.par -= newPld.body.par;
            pld.body.guaranteedAmt -= newPld.body.guaranteedAmt;

        } else if (amt == pld.body.guaranteedAmt) {

            pld.head.state = uint8(StateOfPld.Released);

        } else revert("PR.splitPld: amt overflow");

        if (buyer > 0) {
            newPld.body.preSeq = pld.head.seqOfPld;

            newPld.head.creditor = uint40(buyer);
            newPld.head = regPledge(repo, newPld);
        }
    }

    function extendPledge(
        Pledge storage pld,
        uint extDays,
        uint caller
    ) public {
        require(caller == pld.head.pledgor, "PR.extendPld: not pledgor");
        require(pld.head.state == uint8(StateOfPld.Issued) ||
            pld.head.state == uint8(StateOfPld.Locked), "PR.EP: wrong state");
        require(!isExpired(pld), "PR.UP: pledge expired");
        pld.head.guaranteeDays += uint16(extDays);
    }

    // ==== Lock & Release ====

    function lockPledge(
        Pledge storage pld,
        bytes32 hashLock,
        uint caller
    ) public {
        require(caller == pld.head.creditor, "PR.lockPld: not creditor");        
        require (!isExpired(pld), "PR.lockPld: pledge expired");
        require (hashLock != bytes32(0), "PR.lockPld: zero hashLock");

        if (pld.head.state == uint8(StateOfPld.Issued)){
            pld.head.state = uint8(StateOfPld.Locked);
            pld.hashLock = hashLock;
        } else revert ("PR.lockPld: wrong state");
    }

    function releasePledge(
        Pledge storage pld,
        string memory hashKey
    ) public {
        require (pld.head.state == uint8(StateOfPld.Locked), "PR.RP: wrong state");
        if (pld.hashLock == keccak256(bytes(hashKey))) {
            pld.head.state = uint8(StateOfPld.Released);
        } else revert("PR.releasePld: wrong Key");
    }

    function execPledge(Pledge storage pld, uint caller) public {

        require(caller == pld.head.creditor, "PR.execPld: not creditor");
        require(isTriggerd(pld), "PR.execPld: pledge not triggered");
        require(!isExpired(pld), "PR.execPld: pledge expired");

        if (pld.head.state == uint8(StateOfPld.Issued) ||
            pld.head.state == uint8(StateOfPld.Locked))
        {
            pld.head.state = uint8(StateOfPld.Executed);
        } else revert ("PR.execPld: wrong state");
    }

    function revokePledge(Pledge storage pld, uint caller) public {
        require(caller == pld.head.pledgor, "PR.revokePld: not pledgor");
        require(isExpired(pld), "PR.revokePld: pledge not expired");

        if (pld.head.state == uint8(StateOfPld.Issued) || 
            pld.head.state == uint8(StateOfPld.Locked)) 
        {
            pld.head.state = uint8(StateOfPld.Revoked);
        } else revert ("PR.revokePld: wrong state");
    }

    // ==== Counter ====

    function _increaseCounterOfPld(Repo storage repo, uint256 seqOfShare) 
        private returns (uint16 seqOfPld) 
    {
        repo.pledges[seqOfShare][0].head.seqOfPld++;
        seqOfPld = repo.pledges[seqOfShare][0].head.seqOfPld;
    }

    //#################
    //##    读接口    ##
    //#################

    function isTriggerd(Pledge storage pld) public view returns(bool) {
        uint64 triggerDate = pld.head.createDate + uint48(pld.head.daysToMaturity) * 86400;
        return block.timestamp >= triggerDate;
    }

    function isExpired(Pledge storage pld) public view returns(bool) {
        uint64 expireDate = pld.head.createDate + uint48(pld.head.daysToMaturity + pld.head.guaranteeDays) * 86400;
        return block.timestamp >= expireDate;
    }

    function counterOfPld(Repo storage repo, uint256 seqOfShare) 
        public view returns (uint16) 
    {
        return repo.pledges[seqOfShare][0].head.seqOfPld;
    }

    function isPledge(Repo storage repo, uint seqOfShare, uint seqOfPledge) 
        public view returns (bool)
    {
        return repo.pledges[seqOfShare][seqOfPledge].head.createDate > 0;
    }

    function getSNList(Repo storage repo) public view returns (bytes32[] memory list)
    {
        list = repo.snList.values();
    }

    function getPledge(Repo storage repo, uint256 seqOfShare, uint seqOfPld) 
        public view returns (Pledge memory)
    {
        return repo.pledges[seqOfShare][seqOfPld];
    } 

    function getPledgesOfShare(Repo storage repo, uint256 seqOfShare) 
        public view returns (Pledge[] memory) 
    {
        uint256 len = counterOfPld(repo, seqOfShare);

        // require(len > 0, "PR.getPldsOfShare: no pledges found");

        Pledge[] memory output = new Pledge[](len);

        while (len > 0) {
            output[len - 1] = repo.pledges[seqOfShare][len];
            len--;
        }

        return output;
    }

    function getAllPledges(Repo storage repo) 
        public view returns (Pledge[] memory)
    {
        bytes32[] memory snList = getSNList(repo);
        uint len = snList.length;
        Pledge[] memory ls = new Pledge[](len);

        while( len > 0 ) {
            Head memory head = snParser(snList[len - 1]);
            ls[len - 1] = repo.pledges[head.seqOfShare][head.seqOfPld];
            len--;
        }

        return ls;
    }
}
