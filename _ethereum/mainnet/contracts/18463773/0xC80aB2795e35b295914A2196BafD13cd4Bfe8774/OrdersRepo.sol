// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./GoldChain.sol";
import "./EnumerableSet.sol";

library OrdersRepo {
    using EnumerableSet for EnumerableSet.UintSet;
    using GoldChain for GoldChain.Chain;
    using GoldChain for GoldChain.Node;

    enum StateOfInvestor {
        Pending,
        Approved,
        Revoked
    }

    struct Investor {
        uint40 userNo;
        uint40 groupRep;
        uint48 regDate;
        uint40 verifier;
        uint48 approveDate;
        uint32 data;
        uint8 state;
        bytes32 idHash;
    }

    struct Deal {
        uint16 classOfShare;
        uint32 seqOfShare;
        uint40 buyer;
        uint40 groupRep;
        uint64 paid;
        uint32 price;
        uint16 votingWeight;
    }

    struct Repo {
        // class => Chain
        mapping(uint256 => GoldChain.Chain) ordersOfClass;
        EnumerableSet.UintSet classesList;
        mapping(uint256 => Investor) investors;
        uint[] investorsList;
        // ---- tempArry ----
        GoldChain.Node[] expired;
        Deal[] deals;
    }

    //################
    //##  Modifier  ##
    //################

    modifier investorExist(
        Repo storage repo,
        uint acct
    ) {
        require(isInvestor(repo, acct),
            "OR.investorExist: not");
        _;
    }

    modifier classExist(
        Repo storage repo,
        uint classOfShare
    ) {
        require (isClass(repo, classOfShare),
            "OR.classExist: not");
        _;
    }

    //#################
    //##  Write I/O  ##
    //#################

    // ==== Codify & Parse ====

    function parseSn(bytes32 sn) public pure returns(
        Deal memory deal
    ) {
        uint _sn = uint(sn);

        deal.classOfShare = uint16(_sn >> 240);
        deal.seqOfShare = uint32(_sn >> 208);
        deal.buyer = uint40(_sn >> 168);
        deal.groupRep = uint40(_sn >> 128);
        deal.paid = uint64(_sn >> 64);
        deal.price = uint32(_sn >> 32);
        deal.votingWeight = uint16(_sn >> 16);
    }

    function codifyDeal(
        Deal memory deal
    ) public pure returns(bytes32 sn) {
        bytes memory _sn = 
            abi.encodePacked(
                deal.classOfShare,
                deal.seqOfShare,
                deal.buyer,
                deal.groupRep,
                deal.paid,
                deal.price,
                deal.votingWeight
            );

        assembly {
            sn := mload(add(_sn, 0x20))
        }                        
    }

    // ==== Investor ====

    function regInvestor(
        Repo storage repo,
        uint userNo,
        uint groupRep,
        bytes32 idHash
    ) public {
        require(idHash != bytes32(0), 
            "OR.regInvestor: zero idHash");
        
        uint40 user = uint40(userNo);

        require(user > 0,
            "OR.regInvestor: zero userNo");

        Investor storage investor = repo.investors[user];
        
        investor.userNo = user;
        investor.groupRep = uint40(groupRep);
        investor.idHash = idHash;

        if (!isInvestor(repo, userNo)) {
            repo.investorsList.push(user);
            investor.regDate = uint48(block.timestamp);
        } else {
            if (investor.state == uint8(StateOfInvestor.Approved))
                _decreaseQtyOfInvestors(repo);
            investor.state = uint8(StateOfInvestor.Pending);
        }
    }

    function approveInvestor(
        Repo storage repo,
        uint acct,
        uint verifier
    ) public investorExist(repo, acct) {

        Investor storage investor = repo.investors[acct];

        require(investor.state != uint8(StateOfInvestor.Approved),
            "OR,apprInv: wrong state");

        investor.verifier = uint40(verifier);
        investor.approveDate = uint48(block.timestamp);
        investor.state = uint8(StateOfInvestor.Approved);

        _increaseQtyOfInvestors(repo);
    }

    function revokeInvestor(
        Repo storage repo,
        uint acct,
        uint verifier
    ) public {

        Investor storage investor = repo.investors[acct];

        require(investor.state == uint8(StateOfInvestor.Approved),
            "OR,revokeInvestor: wrong state");

        investor.verifier = uint40(verifier);
        investor.approveDate = uint48(block.timestamp);
        investor.state = uint8(StateOfInvestor.Revoked);

        _decreaseQtyOfInvestors(repo);
    }

    

    // ==== Order ====

    function placeSellOrder(
        Repo storage repo,
        uint classOfShare,
        uint seqOfShare,
        uint votingWeight,
        uint paid,
        uint price,
        uint execHours,
        bool sortFromHead
    ) public returns (bytes32 sn) {

        repo.classesList.add(classOfShare);

        GoldChain.Chain storage chain = 
            repo.ordersOfClass[classOfShare];

        sn = chain.createNode(
            seqOfShare,
            votingWeight,
            paid,
            price,
            execHours,
            sortFromHead
        );
    }

    function withdrawSellOrder(
        Repo storage repo,
        uint classOfShare,
        uint seqOfOrder
    ) public classExist(repo, classOfShare) 
        returns (GoldChain.Node memory) 
    {
        return repo.ordersOfClass[classOfShare].offChain(seqOfOrder);
    }

    function placeBuyOrder(
        Repo storage repo,
        uint acct,
        uint classOfShare,
        uint paid,
        uint price
    ) public classExist(repo, classOfShare) returns (
        Deal[] memory deals,
        Deal memory call,
        GoldChain.Node[] memory expired
    ) {

        Investor memory investor = 
            getInvestor(repo, acct);

        require (investor.state == uint8(StateOfInvestor.Approved),
            "OR.placeBuyOrder: wrong stateOfInvestor");

        call.classOfShare = uint16(classOfShare);
        call.paid = uint64(paid);
        call.price = uint32(price);
        call.buyer = investor.userNo;
        call.groupRep = investor.groupRep;         

        _checkOffers(repo, call);
        
        deals = repo.deals;
        delete repo.deals;

        expired = repo.expired;
        delete repo.expired;
    }

    function _checkOffers(
        Repo storage repo,
        Deal memory call
    ) private {

        GoldChain.Chain storage chain = 
            repo.ordersOfClass[call.classOfShare];

        uint32 seqOfOffer = chain.head();

        while(seqOfOffer > 0 && call.paid > 0) {

            GoldChain.Node memory offer = chain.nodes[seqOfOffer];

            if (offer.expireDate <= block.timestamp) {

                repo.expired.push(
                    chain.offChain(seqOfOffer)
                );
                seqOfOffer = offer.next;
                
                continue;
            }
            
            if (offer.price <= call.price) {

                bool paidAsPut = offer.paid <= call.paid;

                Deal memory deal = Deal({
                    classOfShare: call.classOfShare,
                    seqOfShare: offer.seqOfShare,
                    buyer: call.buyer,
                    groupRep: call.groupRep,
                    paid: paidAsPut ? offer.paid : call.paid,
                    price: offer.price,
                    votingWeight: offer.votingWeight
                });

                repo.deals.push(deal);

                if (paidAsPut) {
                    chain.offChain(seqOfOffer);
                    seqOfOffer = offer.next;
                } else {
                    chain.nodes[seqOfOffer].paid -= deal.paid;
                }

                call.paid -= deal.paid;
            } else break;
        }
    }

    function _increaseQtyOfInvestors(
        Repo storage repo
    ) private {
        repo.investors[0].verifier++;
    }

    function _decreaseQtyOfInvestors(
        Repo storage repo
    ) private {
        repo.investors[0].verifier--;
    }


    //################
    //##  Read I/O  ##
    //################

    // ==== Investor ====

    function isInvestor(
        Repo storage repo,
        uint acct
    ) public view returns(bool) {
        return repo.investors[acct].regDate > 0;
    }

    function getInvestor(
        Repo storage repo,
        uint acct
    ) public view investorExist(repo, acct) returns(Investor memory) {
        return repo.investors[acct];
    }

    function getQtyOfInvestors(
        Repo storage repo
    ) public view returns(uint) {
        return repo.investors[0].verifier;
    }

    function investorList(
        Repo storage repo
    ) public view returns(uint[] memory) {
        return repo.investorsList;
    }

    function investorInfoList(
        Repo storage repo
    ) public view returns(Investor[] memory list) {
        uint[] memory seqList = repo.investorsList;
        uint len = seqList.length;

        list = new Investor[](len);

        while (len > 0) {
            list[len - 1] = repo.investors[seqList[len - 1]];
            len--;
        }

        return list;
    }

    // ==== Class ====

    function isClass(
        Repo storage repo,
        uint classOfShare
    ) public view returns (bool) {
        return repo.classesList.contains(classOfShare);
    }

    function getClassesList(
        Repo storage repo    
    ) public view returns (uint[] memory) {
        return repo.classesList.values();
    }

    // ==== TempArrays ====

    function getExpired(
        Repo storage repo
    ) public view returns (GoldChain.Node[] memory) {
        return repo.expired;
    }

    function getDeals(
        Repo storage repo
    ) public view returns(Deal[] memory) {
        return repo.deals;
    }

}