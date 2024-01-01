// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./Checkpoints.sol";
import "./EnumerableSet.sol";
import "./SharesRepo.sol";
import "./TopChain.sol";

library MembersRepo {
    using Checkpoints for Checkpoints.History;
    // using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;
    // using SharesRepo for SharesRepo.Head;
    using TopChain for TopChain.Chain;

    struct Member {
        Checkpoints.History votesInHand;
        // class => seqList
        mapping(uint => EnumerableSet.UintSet) sharesOfClass;
        EnumerableSet.UintSet classesBelonged;
    }

    /*
        members[0] {
            votesInHand: ownersEquity;
        }
    */

    /* Node[0] {
        prev: tail;
        next: head;
        ptr: pending;
        amt: pending;
        sum: totalVotes;
        cat: basedOnPar;
    } */

    struct Repo {
        TopChain.Chain chain;
        mapping(uint256 => Member) members;
        // class => membersList
        mapping(uint => EnumerableSet.UintSet) membersOfClass;
    }

    //###############
    //##  Modifer  ##
    //###############

    modifier memberExist(
        Repo storage repo,
        uint acct
    ) {
        require(isMember(repo, acct),
            "MR.memberExist: not");
        _;
    }

    //##################
    //##  Write I/O  ##
    //##################

    // ==== Zero Node Setting ====

    function setVoteBase(
        Repo storage repo, 
        bool _basedOnPar
    ) public returns (bool flag) {

        if (repo.chain.basedOnPar() != _basedOnPar) {
            uint256[] memory members = 
                repo.membersOfClass[0].values();
            uint256 len = members.length;

            while (len > 0) {
                uint256 cur = members[len - 1];

                Checkpoints.Checkpoint memory cp = 
                    repo.members[cur].votesInHand.latest();

                if (cp.paid != cp.par) {
                    if (_basedOnPar)
                        repo.chain.increaseAmt(cur, (cp.par - cp.paid) * cp.votingWeight / 100, true);
                    else repo.chain.increaseAmt(cur, (cp.par - cp.paid) * cp.votingWeight / 100, false);
                }

                len--;
            }

            repo.chain.setVoteBase(_basedOnPar);

            flag = true;
        }
    }

    // ==== Member ====

    function addMember(
        Repo storage repo, 
        uint acct
    ) public returns (bool flag) {
        if (repo.membersOfClass[0].add(acct)) {
            repo.chain.addNode(acct);
            flag = true;
        }
    }

    function delMember(
        Repo storage repo, 
        uint acct
    ) public {
        repo.chain.delNode(acct);

        uint[] memory classes = 
            repo.members[acct].classesBelonged.values();
        uint len = classes.length;
        
        while (len > 0) {
            repo.membersOfClass[classes[len - 1]].remove(acct);
            len--;
        }

        repo.membersOfClass[0].remove(acct);

        delete repo.members[acct];
    }

    function addShareToMember(
        Repo storage repo,
        SharesRepo.Head memory head
    ) public {

        Member storage member = repo.members[head.shareholder];

        if (member.sharesOfClass[0].add(head.seqOfShare)
            && member.sharesOfClass[head.class].add(head.seqOfShare)
            && member.classesBelonged.add(head.class))
                repo.membersOfClass[head.class].add(head.shareholder);
    }

    function removeShareFromMember(
        Repo storage repo,
        SharesRepo.Head memory head
    ) public {

        Member storage member = 
            repo.members[head.shareholder];
        
        if (member.sharesOfClass[head.class].remove(head.seqOfShare)
            && member.sharesOfClass[0].remove(head.seqOfShare)) {

            if(member.sharesOfClass[head.class].length() == 0) {
                repo.membersOfClass[head.class].remove(head.shareholder);
                member.classesBelonged.remove(head.class);
            }
        }

    }

    function increaseAmtOfMember(
        Repo storage repo,
        uint acct,
        uint votingWeight,
        uint deltaPaid,
        uint deltaPar,
        uint deltaClean,
        bool isIncrease
    ) public {

        if (deltaPaid > 0 || deltaPar > 0 ) {

            uint deltaAmt = repo.chain.basedOnPar() 
                ? deltaPar 
                : deltaPaid;

            repo.chain.increaseAmt(
                acct, 
                deltaAmt * votingWeight / 100, 
                isIncrease
            );
        }

        Checkpoints.Checkpoint memory cp = 
            repo.members[acct].votesInHand.latest();

        if (cp.votingWeight != votingWeight)
            cp.votingWeight = _calWeight(
                repo, 
                cp, 
                votingWeight, 
                deltaPaid, 
                deltaPar, 
                isIncrease
            );

        if (isIncrease) {
            cp.paid += uint64(deltaPaid);
            cp.par += uint64(deltaPar);
            cp.cleanPaid += uint64(deltaClean);
        } else {
            cp.paid -= uint64(deltaPaid);
            cp.par -= uint64(deltaPar);
            cp.cleanPaid -= uint64(deltaClean);
        }

        repo.members[acct].votesInHand.push(
            cp.votingWeight, 
            cp.paid, 
            cp.par, 
            cp.cleanPaid
        );
    }

    function increaseAmtOfCap(
        Repo storage repo,
        uint votingWeight,
        uint deltaPaid,
        uint deltaPar,
        bool isIncrease
    ) public {
        Checkpoints.Checkpoint memory cp = 
            repo.members[0].votesInHand.latest();

        if (cp.votingWeight != votingWeight)
            cp.votingWeight = _calWeight(
                repo, 
                cp, 
                votingWeight, 
                deltaPaid, 
                deltaPar, 
                isIncrease
            );

        if (isIncrease) {
            cp.paid += uint64(deltaPaid);
            cp.par += uint64(deltaPar);
        } else {
            cp.paid -= uint64(deltaPaid);
            cp.par -= uint64(deltaPar);
        }

        updateOwnersEquity(repo, cp);

        if (repo.chain.basedOnPar() && deltaPar > 0) {
            repo.chain.increaseTotalVotes(deltaPar * votingWeight / 100, isIncrease);
        } else if (!repo.chain.basedOnPar() && deltaPaid > 0) {
            repo.chain.increaseTotalVotes(deltaPaid * votingWeight / 100, isIncrease);
        }
    }

    function _calWeight(
        Repo storage repo,
        Checkpoints.Checkpoint memory cp,
        uint votingWeight,
        uint deltaPaid,
        uint deltaPar,
        bool isIncrease
    ) private view returns(uint16 output) {
        
        if (isIncrease) {
            output = repo.chain.basedOnPar()
                ? uint16(((cp.votingWeight * cp.par + votingWeight * deltaPar) * 100 / (cp.par + deltaPar) + 50) / 100)
                : uint16(((cp.votingWeight * cp.paid + votingWeight * deltaPaid) * 100 / (cp.paid + deltaPaid) + 50) / 100);
        } else {
            output = repo.chain.basedOnPar()
                ? uint16(((cp.votingWeight * cp.par - votingWeight * deltaPar) * 100 / (cp.par - deltaPar) + 50) / 100)
                : uint16(((cp.votingWeight * cp.paid - votingWeight * deltaPaid) * 100 / (cp.paid - deltaPaid) + 50) / 100);            
        }
    }

    // ==== Zero Node Setting ====

    function updateOwnersEquity(
        Repo storage repo,
        Checkpoints.Checkpoint memory cp
    ) public {
        repo.members[0].votesInHand.push(cp.votingWeight, cp.paid, cp.par, cp.cleanPaid);
    }

    //##################
    //##    读接口    ##
    //##################

    // ==== member ====

    function isMember(
        Repo storage repo,
        uint acct
    ) public view returns(bool) {
        return repo.membersOfClass[0].contains(acct);
    }
    
    function qtyOfMembers(
        Repo storage repo
    ) public view returns(uint) {
        return repo.membersOfClass[0].length();
    }

    function membersList(
        Repo storage repo
    ) public view returns(uint[] memory) {
        return repo.membersOfClass[0].values();
    }

    // ---- Votes ----

    function ownersEquity(
        Repo storage repo
    ) public view returns(Checkpoints.Checkpoint memory) {
        return repo.members[0].votesInHand.latest();
    }

    function capAtDate(
        Repo storage repo,
        uint date
    ) public view returns(Checkpoints.Checkpoint memory) {
        return repo.members[0].votesInHand.getAtDate(date);
    }

    function equityOfMember(
        Repo storage repo,
        uint acct
    ) public view memberExist(repo, acct) returns(
        Checkpoints.Checkpoint memory
    ) {
        return repo.members[acct].votesInHand.latest();
    }

    function equityAtDate(
        Repo storage repo,
        uint acct,
        uint date
    ) public view memberExist(repo, acct) returns(
        Checkpoints.Checkpoint memory
    ) {
        return repo.members[acct].votesInHand.getAtDate(date);
    }

    function votesAtDate(
        Repo storage repo,
        uint256 acct,
        uint date
    ) public view returns (uint64) {
        Checkpoints.Checkpoint memory cp = repo.members[acct].votesInHand.getAtDate(date);
        
        return repo.chain.basedOnPar() 
                ? (cp.par * cp.votingWeight + 50) / 100 
                : (cp.paid * cp.votingWeight + 50) / 100;
    }

    function votesHistory(
        Repo storage repo,
        uint acct
    ) public view memberExist(repo, acct) 
        returns (Checkpoints.Checkpoint[] memory) 
    {
        return repo.members[acct].votesInHand.pointsOfHistory();
    }

    // ---- Class ----

    function isClassMember(
        Repo storage repo, 
        uint256 acct, 
        uint class
    ) public view memberExist(repo, acct) returns (bool flag) {
        return repo.members[acct].classesBelonged.contains(class);
    }

    function classesBelonged(
        Repo storage repo, 
        uint256 acct
    ) public view memberExist(repo, acct) returns (uint[] memory) {
        return repo.members[acct].classesBelonged.values();
    }

    function qtyOfClassMember(
        Repo storage repo, 
        uint class
    ) public view returns(uint256) {
        return repo.membersOfClass[class].length();
    }

    function getMembersOfClass(
        Repo storage repo, 
        uint class
    ) public view returns(uint256[] memory) {
        return repo.membersOfClass[class].values();
    }

    // ---- Share ----

    function qtyOfSharesInHand(
        Repo storage repo, 
        uint acct
    ) public view memberExist(repo, acct) returns(uint) {
        return repo.members[acct].sharesOfClass[0].length();
    }

    function sharesInHand(
        Repo storage repo, 
        uint acct
    ) public view memberExist(repo, acct) returns(uint[] memory) {
        return repo.members[acct].sharesOfClass[0].values();
    }

    function qtyOfSharesInClass(
        Repo storage repo, 
        uint acct,
        uint class
    ) public view memberExist(repo, acct) returns(uint) {
        require(isClassMember(repo, acct, class), 
            "MR.qtyOfSharesInClass: not class member");
        return repo.members[acct].sharesOfClass[class].length();
    }

    function sharesInClass(
        Repo storage repo, 
        uint acct,
        uint class
    ) public view memberExist(repo, acct) returns(uint[] memory) {
        require(isClassMember(repo, acct, class),
            "MR.sharesInClass: not class member");
        return repo.members[acct].sharesOfClass[class].values();
    }



}
