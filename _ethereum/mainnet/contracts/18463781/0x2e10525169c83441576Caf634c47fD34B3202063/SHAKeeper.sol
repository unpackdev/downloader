// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./AccessControl.sol";

import "./ISHAKeeper.sol";

contract SHAKeeper is ISHAKeeper, AccessControl {
    using RulesParser for bytes32;

    // ======== TagAlong & DragAlong ========

    function execAlongRight(
        address ia,
        uint256 seqOfDeal,
        bool dragAlong,
        uint256 seqOfShare,
        uint paid,
        uint par,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDK {
        
        IRegisterOfAgreements _roa = _gk.getROA();
        IRegisterOfShares _ros = _gk.getROS();

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);
        SharesRepo.Share memory share = _ros.getShare(seqOfShare);
        uint16 subjectVW = _ros.getShare(deal.head.seqOfShare).head.votingWeight;

        require(deal.body.state == uint8(DealsRepo.StateOfDeal.Locked), 
            "SHAK.execAlongs: state not Locked");

        require(!_roa.isFRClaimer(ia, caller), 
            "SHAK.execAlongs: caller is frClaimer");

        require(!_roa.isFRClaimer(ia, share.head.shareholder), 
            "SHAK.execAlongs: shareholder is frClaimer");

        _roa.createMockOfIA(ia);

        _checkAlongDeal(dragAlong, ia, deal, share, caller, paid, par, subjectVW);

        _roa.execAlongRight(ia, dragAlong, seqOfDeal, seqOfShare, paid, par, caller, sigHash);
    }

    function _checkAlongDeal(
        bool dragAlong,
        address ia,
        DealsRepo.Deal memory deal,
        SharesRepo.Share memory share,
        uint256 caller,
        uint paid,
        uint par,
        uint16 subjectVW
    ) private view {
        

        IAlongs _al = dragAlong
            ? IAlongs(_gk.getSHA().
                getTerm(uint8(IShareholdersAgreement.TitleOfTerm.DragAlong)))
            : IAlongs(_gk.getSHA().
                getTerm(uint8(IShareholdersAgreement.TitleOfTerm.TagAlong)));

        require(
            _al.isFollower(deal.head.seller, share.head.shareholder),
            "SHAK.checkAlongs: NOT linked"
        );

        require(_al.isTriggered(ia, deal), "SHAK.checkAlongs: not triggered");

        if (dragAlong) {
            require(caller == deal.head.seller, "SHAK.checkAlongs: not drager");
        } else {
            require(caller == share.head.shareholder,
                "SHAK.checkAlongs: not follower");
            require(!ISigPage(ia).isBuyer(true, caller),
                "SHAK.checkAlongs: caller is Buyer");
        }

        if(_al.getLinkRule(deal.head.seller).proRata) {
            IRegisterOfMembers _rom = _gk.getROM();
            
            if (_rom.basedOnPar())
                require ( par <= 
                deal.body.par * subjectVW / 100 * share.body.par / _rom.votesOfGroup(deal.head.seller), 
                "SHAKeeper.checkAlong: par overflow");
            else require ( paid <=
                deal.body.paid * subjectVW / 100 * share.body.paid / _rom.votesOfGroup(deal.head.seller),
                "SHAKeeper.checkAlong: paid overflow");            
        }
    }

    function acceptAlongDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDK {
        
        IRegisterOfAgreements _roa = _gk.getROA();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        require(caller == deal.body.buyer, "SHAK.AAD: not buyer");

        DTClaims.Claim[] memory claims = _roa.acceptAlongClaims(ia, seqOfDeal);

        uint len = claims.length;
        while(len > 0) {
            DTClaims.Claim memory claim = claims[len - 1];

            SharesRepo.Share memory share = 
                _gk.getROS().getShare(claim.seqOfShare);

            _createAlongDeal(_ia, claim, deal, share);

            _ia.regSig(deal.head.seller, claim.sigDate, claim.sigHash);
            _ia.regSig(caller, uint48(block.timestamp), sigHash);

            len--;
        }

        // _ia.signDoc(false, caller, sigHash);

    }

    function _createAlongDeal(
        IInvestmentAgreement _ia,
        DTClaims.Claim memory claim,
        DealsRepo.Deal memory deal,
        SharesRepo.Share memory share
    ) private {
        deal.head = DealsRepo.Head({
            typeOfDeal: claim.typeOfClaim == 0 
                ? uint8(DealsRepo.TypeOfDeal.DragAlong) 
                : uint8(DealsRepo.TypeOfDeal.TagAlong),
            seqOfDeal: 0,
            preSeq: deal.head.seqOfDeal,
            classOfShare: share.head.class,
            seqOfShare: share.head.seqOfShare,
            seller: share.head.shareholder,
            priceOfPaid: deal.head.priceOfPaid,
            priceOfPar: deal.head.priceOfPar,
            closingDeadline: deal.head.closingDeadline,
            votingWeight: share.head.votingWeight
        });

        deal.body = DealsRepo.Body({
            buyer: deal.body.buyer,
            groupOfBuyer: deal.body.groupOfBuyer,
            paid: claim.paid,
            par: claim.par,
            state: uint8(DealsRepo.StateOfDeal.Locked),
            para: 0,
            argu: 0,
            flag: false
        });

        _ia.regDeal(deal);

        _gk.getROS().decreaseCleanPaid(share.head.seqOfShare, claim.paid);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDK {
        
        IRegisterOfShares _ros = _gk.getROS();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        SharesRepo.Share memory tShare = _ros.getShare(seqOfShare);

        require(caller == tShare.head.shareholder, "SHAK.execAD: not shareholder");
        require(!_ia.isInitSigner(caller), "SHAK.execAD: is InitSigner");

        require(_gk.getROA().getHeadOfFile(ia).state == 
            uint8(FilesRepo.StateOfFile.Circulated), "SHAK.execAD: wrong file state");

        _ia.requestPriceDiff(seqOfDeal, seqOfShare);

        IAntiDilution _ad = IAntiDilution(_gk.getSHA().getTerm(
            uint8(IShareholdersAgreement.TitleOfTerm.AntiDilution)
        ));

        uint64 giftPaid = _ad.getGiftPaid(ia, seqOfDeal, tShare.head.seqOfShare);
        uint256[] memory obligors = _ad.getObligorsOfAD(tShare.head.class);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);
        
        deal.head.typeOfDeal = uint8(DealsRepo.TypeOfDeal.FreeGift);
        deal.head.preSeq = deal.head.seqOfDeal;
        deal.head.seqOfDeal = 0;
        // deal.head.priceOfPaid = 0;
        deal.head.priceOfPar = tShare.head.seqOfShare;

        deal.body.buyer = tShare.head.shareholder;
        deal.body.state = uint8(DealsRepo.StateOfDeal.Locked);

        _deductShares(obligors, _gk, _ia, deal, giftPaid, _ros, sigHash);

    }

    function _deductShares(
        uint[] memory obligors,
        IGeneralKeeper _gk,
        IInvestmentAgreement _ia,
        DealsRepo.Deal memory deal,
        uint64 giftPaid,
        IRegisterOfShares _ros,
        bytes32 sigHash
    ) private {

        IRegisterOfMembers _rom = _gk.getROM();

        deal.body.groupOfBuyer = _rom.groupRep(deal.body.buyer);

        uint i = obligors.length;

        while (i > 0) {
            
            uint[] memory sharesInHand = _rom.sharesInHand(obligors[i - 1]);

            uint j = sharesInHand.length;

            while (j > 0) {

                giftPaid = _createGift(
                    _ia,
                    deal,
                    sharesInHand[j - 1],
                    giftPaid,
                    _ros,
                    sigHash
                );

                if (giftPaid == 0) break;
                j--;
            }

            if (giftPaid == 0) break;
            i--;
        }
    }


    function _createGift(
        IInvestmentAgreement _ia,
        DealsRepo.Deal memory deal,
        uint256 seqOfShare,
        uint64 giftPaid,
        IRegisterOfShares _ros,
        bytes32 sigHash
    ) private returns (uint64 result) {        
        SharesRepo.Share memory cShare = _ros.getShare(seqOfShare);

        uint64 lockAmount;

        if (cShare.body.cleanPaid > 0) {

            lockAmount = (cShare.body.cleanPaid < giftPaid) ? cShare.body.cleanPaid : giftPaid;

            deal.head.classOfShare = cShare.head.class;
            deal.head.seqOfShare = cShare.head.seqOfShare;
            deal.head.seller = cShare.head.shareholder;

            deal.body.paid = lockAmount;
            deal.body.par = lockAmount;
            
            _ia.regDeal(deal);
            _ia.regSig(deal.head.seller, uint48(block.timestamp), bytes32(uint(deal.head.seqOfShare)));
            _ia.regSig(deal.body.buyer, uint48(block.timestamp), sigHash);

            _ros.decreaseCleanPaid(cShare.head.seqOfShare, lockAmount);
        }
        result = giftPaid - lockAmount;
    }

    function takeGiftShares(
        address ia,
        uint256 seqOfDeal,
        uint caller
    ) external onlyDK {
        
        IRegisterOfShares _ros = _gk.getROS();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        require(caller == deal.body.buyer, "caller is not buyer");

        if (_ia.takeGift(seqOfDeal))
            _gk.getROA().setStateOfFile(ia, uint8(FilesRepo.StateOfFile.Closed));

        _ros.increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
        _ros.transferShare(
            deal.head.seqOfShare, 
            deal.body.paid, 
            deal.body.par, 
            deal.body.buyer, 
            deal.head.priceOfPaid, 
            deal.head.priceOfPaid
        );

        SharesRepo.Share memory tShare = _ros.getShare(deal.head.priceOfPar);
        if (tShare.head.priceOfPaid > deal.head.priceOfPaid)
            _ros.updatePriceOfPaid(tShare.head.seqOfShare, deal.head.priceOfPaid);
    }

    // ======== FirstRefusal ========

    function execFirstRefusal(
        uint256 seqOfFRRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDK {
        
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        require(!_ia.isSeller(true, caller), 
            "SHAK.EFR: frClaimer is seller");

        DealsRepo.Head memory headOfDeal = 
            _ia.getDeal(seqOfDeal).head;
        
        RulesParser.FirstRefusalRule memory rule = 
            _gk.getSHA().getRule(seqOfFRRule).firstRefusalRuleParser();

        require(rule.typeOfDeal == headOfDeal.typeOfDeal, 
            "SHAK.EFR: rule and deal are not same type");

        require(
            (rule.membersEqual && _gk.getROM().isMember(caller)) || 
            rule.rightholders[seqOfRightholder] == caller,
            "SHAK.EFR: caller NOT rightholder"
        );

        _gk.getROA().claimFirstRefusal(ia, seqOfDeal, caller, sigHash);

        if (_ia.getDeal(seqOfDeal).body.state != 
            uint8(DealsRepo.StateOfDeal.Terminated))
                _ia.terminateDeal(seqOfDeal); 
    }

    function computeFirstRefusal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller
    ) external onlyDK {
        
        IRegisterOfMembers _rom = _gk.getROM();
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        (,, bytes32 sigHashOfSeller) = _ia.getSigOfParty(true, deal.head.seller);

        require(_rom.isMember(caller), "SHAKeeper.computeFR: not member");

        if (deal.head.seqOfShare != 0) {
            deal.head.typeOfDeal = uint8(DealsRepo.TypeOfDeal.FirstRefusal);
        } else  deal.head.typeOfDeal = uint8(DealsRepo.TypeOfDeal.PreEmptive);

        deal.head.preSeq = deal.head.seqOfDeal;
        deal.body.state = uint8(DealsRepo.StateOfDeal.Locked);

        FRClaims.Claim[] memory cls = 
            _gk.getROA().computeFirstRefusal(ia, seqOfDeal);

        uint256 len = cls.length;
        while (len > 0) {
            _createFRDeal(_ia, deal, cls[len-1], _rom, sigHashOfSeller);
            len--;
        }

        // if (deal.head.seqOfShare > 0)
        //     _ia.signDoc(false, deal.head.seller, sigHashOfSeller);
    }

    function _createFRDeal(
        IInvestmentAgreement _ia,
        DealsRepo.Deal memory deal,
        FRClaims.Claim memory cl,
        IRegisterOfMembers _rom,
        bytes32 sigHashOfSeller
    ) private {

        uint64 orgPaid = deal.body.paid;
        uint64 orgPar = deal.body.par;
        
        deal.body.buyer = cl.claimer;
        deal.body.groupOfBuyer = _rom.groupRep(cl.claimer);
        deal.body.paid = (orgPaid * cl.ratio) / 10000;
        deal.body.par = (orgPar * cl.ratio) / 10000;

        _ia.regDeal(deal);
        _ia.regSig(cl.claimer, cl.sigDate, cl.sigHash);

        if (deal.head.seller > 0)
            _ia.regSig(deal.head.seller, uint48(block.timestamp), sigHashOfSeller);

        deal.body.paid = orgPaid;
        deal.body.par = orgPar;
    }
}
