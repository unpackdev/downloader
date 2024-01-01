// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./AccessControl.sol";

import "./ILOOKeeper.sol";

contract LOOKeeper is ILOOKeeper, AccessControl {
    using RulesParser for bytes32;

    //##################
    //##   Modifier   ##
    //##################

    //###############
    //##   Write   ##
    //###############

    function regInvestor(
        uint caller,
        uint groupRep,
        bytes32 idHash
    ) external onlyDK {
        
        IListOfOrders _loo = _gk.getLOO();

        _loo.regInvestor(caller, groupRep, idHash);
    }

    function approveInvestor(
        uint userNo,
        uint caller,
        uint seqOfLR
    ) external onlyDK {

        IListOfOrders _loo = _gk.getLOO();

        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        require(_gk.getROD().hasTitle(caller, lr.titleOfVerifier),
            "LOOK.apprInv: no rights");

        require(lr.maxQtyOfInvestors == 0 ||
            _loo.getQtyOfInvestors() < lr.maxQtyOfInvestors,
            "LOOK.apprInv: no quota");

        _gk.getLOO().approveInvestor(userNo, caller);
    }

    function revokeInvestor(
        uint userNo,
        uint caller,
        uint seqOfLR
    ) external onlyDK {

        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        require(_gk.getROD().hasTitle(caller, lr.titleOfVerifier),
            "LOOK.revokeInv: wrong titl");

        _gk.getLOO().revokeInvestor(userNo, caller);
    }

    function placeInitialOffer(
        uint caller,
        uint classOfShare,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external onlyDK {

        IRegisterOfShares _ros = _gk.getROS();
        
        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        require(_gk.getROD().hasTitle(caller, lr.titleOfIssuer),
            "LOOK.placeIO: not entitled");

        require(lr.classOfShare == classOfShare,
            "LOOK.placeIO: wrong class");
        
        require(uint32(price) >= lr.floorPrice,
            "LOOK.placeIO: lower than floor");

        require(lr.ceilingPrice == 0 ||
            uint32(price) <= lr.ceilingPrice,
            "LOOK.placeIO: higher than ceiling");

        require (_ros.getInfoOfClass(classOfShare).body.cleanPaid +
            paid <= lr.maxTotalPar, "LOOK.placeIO: paid overflow");

        _gk.getLOO().placeSellOrder(
            classOfShare,
            0,
            lr.votingWeight,
            paid,
            price,
            execHours,
            true
        );

        _ros.increaseEquityOfClass(true, classOfShare, 0, 0, paid);
    }

    function withdrawInitialOffer(
        uint caller,
        uint classOfShare,
        uint seqOfOrder,
        uint seqOfLR
    ) external onlyDK {

        IListOfOrders _loo = _gk.getLOO();
        IRegisterOfShares _ros = _gk.getROS();

        GoldChain.Node memory order = 
            _loo.getOrder(classOfShare, seqOfOrder);

        require(order.seqOfShare == 0,
            "LOOK.withdrawInitOrder: not initOrder");

        RulesParser.ListingRule memory lr =
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();
        
        require(_gk.getROD().hasTitle(caller, lr.titleOfIssuer),
            "LOOK.withdrawInitOrder: has no title");

        order = _loo.withdrawSellOrder(classOfShare, seqOfOrder);

        _ros.increaseEquityOfClass(false, classOfShare, 0, 0, order.paid);
    }

    function placeSellOrder(
        uint caller,
        uint seqOfClass,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR,
        bool sortFromHead
    ) external onlyDK {
        
        IRegisterOfShares _ros = _gk.getROS();

        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        require(seqOfClass == lr.classOfShare,
            "LOOK.placePut: wrong class");

        require(uint32(price) >= lr.offPrice,
            "LOOK.placePut: lower than offPrice");

        uint[] memory sharesInhand = 
            _gk.getROM().sharesInClass(caller, lr.classOfShare);

        uint len = sharesInhand.length;

        while (len > 0 && paid > 0) {

            SharesRepo.Share memory share = 
                _ros.getShare(sharesInhand[len - 1]);
            len--;

            if(lr.lockupDays == 0 ||
                share.head.issueDate + 
                uint48(lr.lockupDays) * 86400 < block.timestamp) 
            {
                if (share.body.cleanPaid > 0) {
                    if (paid >= share.body.cleanPaid) {
                        _createSellOrder(
                            share, 
                            share.body.cleanPaid, 
                            price, 
                            execHours, 
                            sortFromHead, 
                            _ros
                        );
                        paid -=share.body.cleanPaid;
                    } else {
                        _createSellOrder(
                            share, 
                            paid, 
                            price, 
                            execHours, 
                            sortFromHead, 
                            _ros
                        );
                        break;
                    }
                } 
            }
        }
    }

    function _createSellOrder(
        SharesRepo.Share memory share, 
        uint paid,
        uint price,
        uint execHours,
        bool sortFromHead,
        IRegisterOfShares _ros
    ) private {
        _ros.decreaseCleanPaid(share.head.seqOfShare, paid);

        _gk.getLOO().placeSellOrder(
            share.head.class,
            share.head.seqOfShare,
            share.head.votingWeight,
            paid,
            price,
            execHours,
            sortFromHead
        );
    }

    function withdrawSellOrder(
        uint caller,
        uint classOfShare,
        uint seqOfOrder
    ) external onlyDK {

        IListOfOrders _loo = _gk.getLOO();
        IRegisterOfShares _ros = _gk.getROS();

        GoldChain.Node memory order = 
            _loo.getOrder(classOfShare, seqOfOrder);

        require(order.seqOfShare > 0,
            "LOOK.withdrawSellOrder: zero seqOfShare");

        SharesRepo.Share memory share =
            _ros.getShare(order.seqOfShare);
        
        require(share.head.shareholder == caller,
            "LOOK.withdrawSellOrder: not shareholder");
        
        order = _loo.withdrawSellOrder(classOfShare, seqOfOrder);

        _ros.increaseCleanPaid(order.seqOfShare, order.paid);
    }

    function placeBuyOrder(
        uint caller,
        uint classOfShare,
        uint paid,
        uint price,
        uint msgValue
    ) external onlyDK {
        
        IRegisterOfShares _ros = _gk.getROS();
        IRegisterOfMembers _rom = _gk.getROM();
        uint centPrice = _gk.getCentPrice();

        require(paid * price * centPrice / 100 <= msgValue,
            "LOOK.placeCall: insufficient value");
        
        (OrdersRepo.Deal[] memory deals, GoldChain.Node[] memory expired) = 
            _gk.getLOO().placeBuyOrder(
                caller,
                classOfShare,
                paid,
                price
            );

        uint len = deals.length;
        while (len > 0) {
            OrdersRepo.Deal memory deal = deals[len - 1];
            len--;

            uint valueOfDeal = deal.paid * deal.price * centPrice / 100;

            msgValue -= valueOfDeal;

            if (deal.seqOfShare > 0) {
                SharesRepo.Share memory share = _ros.getShare(deal.seqOfShare);
                _gk.saveToCoffer(share.head.shareholder, valueOfDeal);
                _ros.increaseCleanPaid(deal.seqOfShare, deal.paid);
                _ros.transferShare(
                    deal.seqOfShare,
                    deal.paid,
                    deal.paid,
                    deal.buyer,
                    deal.price,
                    deal.price
                );
            } else {
                SharesRepo.Share memory share;
                
                share.head = SharesRepo.Head({
                    class: uint16(classOfShare),
                    seqOfShare: 0,
                    preSeq: 0,
                    issueDate: 0,
                    shareholder: deal.buyer,
                    priceOfPaid: deal.price,
                    priceOfPar: deal.price,
                    votingWeight: deal.votingWeight,
                    argu: 0
                });

                share.body = SharesRepo.Body({
                    payInDeadline: uint48(block.timestamp + 86400),
                    paid: deal.paid,
                    par: deal.paid,
                    cleanPaid: deal.paid,
                    state: 0,
                    para: 0
                });

                _ros.addShare(share);
            }

            if (deal.groupRep != deal.buyer && 
                deal.groupRep != _rom.groupRep(deal.buyer))
                    _rom.addMemberToGroup(deal.buyer, deal.groupRep);
            
            // _loo.removeDeals();
        }

        if (msgValue > 0) 
            _gk.saveToCoffer(caller, msgValue);

        len = expired.length;
        while (len > 0) {
            GoldChain.Node memory offer = expired[len - 1];
            len--;
            if (offer.seqOfShare > 0)
                _ros.increaseCleanPaid(offer.seqOfShare, offer.paid);
            else 
                _ros.increaseEquityOfClass(false, classOfShare, 0, 0, offer.paid);
        }

    }

}
