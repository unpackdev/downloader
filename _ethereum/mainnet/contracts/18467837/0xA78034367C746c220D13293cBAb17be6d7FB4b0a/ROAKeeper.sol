// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IROAKeeper.sol";

import "./AccessControl.sol";

contract ROAKeeper is IROAKeeper, AccessControl {
    using RulesParser for bytes32;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyPartyOf(address ia, uint256 caller) {
        require(ISigPage(ia).isParty(caller), "BOIK.md.OPO: NOT Party");
        _;
    }

    // #############################
    // ##   InvestmentAgreement   ##
    // #############################

    function createIA(uint version, address primeKeyOfCaller, uint caller) external onlyDK {
 
        require(_gk.getROM().isMember(caller), "not MEMBER");
        
        bytes32 snOfDoc = bytes32((uint(uint8(IRegCenter.TypeOfDoc.IA)) << 224) +
            uint224(version << 192)); 

        DocsRepo.Doc memory doc = _rc.createDoc(
            snOfDoc,
            primeKeyOfCaller
        );

        IAccessControl(doc.body).init(
            primeKeyOfCaller,
            address(this),
            address(_rc),
            address(_gk)
        );

        _gk.getROA().regFile(DocsRepo.codifyHead(doc.head), doc.body);
    }

    // ======== Circulate IA ========

    function circulateIA(
        address ia,
        bytes32 docUrl,
        bytes32 docHash,
        uint256 caller
    ) external onlyDK onlyPartyOf(ia, caller){
        require(IAccessControl(ia).isFinalized(), 
            "BOIK.CIA: IA not finalized");

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        _ia.circulateDoc();
        uint16 signingDays = _ia.getSigningDays();
        uint16 closingDays = _ia.getClosingDays();

        

        RulesParser.VotingRule memory vr = 
            _gk.getSHA().getRule(_ia.getTypeOfIA()).votingRuleParser();

        _ia.setTiming(false, signingDays + vr.frExecDays + vr.dtExecDays + vr.dtConfirmDays, closingDays);

        _gk.getROA().circulateFile(ia, signingDays, closingDays, vr, docUrl, docHash);
    }

    // ======== Sign IA ========

    function signIA(
        address ia,
        uint256 caller,
        bytes32 sigHash
    ) external onlyDK onlyPartyOf(ia, caller) {
        IRegisterOfAgreements _roa = _gk.getROA();

        require(
            _roa.getHeadOfFile(ia).state == uint8(FilesRepo.StateOfFile.Circulated),
            "BOIK.signIA: wrong state"
        );

        _lockDealsOfParty(ia, caller);
        ISigPage(ia).signDoc(true, caller, sigHash);
    }

    function _lockDealsOfParty(address ia, uint256 caller) private {
        uint[] memory list = IInvestmentAgreement(ia).getSeqList();
        uint256 len = list.length;
        while (len > 0) {
            uint seq = list[len - 1];
            len--;

            DealsRepo.Deal memory deal = 
                IInvestmentAgreement(ia).getDeal(seq);

            if (deal.head.seller == caller) {
                if (IInvestmentAgreement(ia).lockDealSubject(seq)) {
                    _gk.getROS().decreaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
                }
            } else if (
                deal.body.buyer == caller &&
                deal.head.typeOfDeal ==
                uint8(DealsRepo.TypeOfDeal.CapitalIncrease)
            ) IInvestmentAgreement(ia).lockDealSubject(seq);
        }
    }

    // ======== Deal Closing ========

    function pushToCoffer(
        address ia,
        uint256 seqOfDeal,
        bytes32 hashLock,
        uint closingDeadline,
        uint256 caller
    ) external onlyDK {

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Head memory head = 
            _ia.getDeal(seqOfDeal).head;

        bool isST = (head.seqOfShare != 0);

        if (isST) require(caller == head.seller, "BOIK.PTC: not seller");
        else require(_gk.getROD().isDirector(caller), "BOIK.PTC: not director");

        _vrAndSHACheck(_ia, seqOfDeal, isST);

        _ia.clearDealCP(seqOfDeal, hashLock, closingDeadline);
    }

    function _vrAndSHACheck(IInvestmentAgreement _ia, uint256 seqOfDeal, bool isST) private view {
        

        IMeetingMinutes _bmm = _gk.getBMM();
        IMeetingMinutes _gmm = _gk.getGMM();
        IRegisterOfAgreements _roa = _gk.getROA();

        require(
            _roa.getHeadOfFile(address(_ia)).state == uint8(FilesRepo.StateOfFile.Approved),
            "BOAK.vrAndSHACheck: wrong state"
        );

        uint256 typeOfIA = _ia.getTypeOfIA();

        IShareholdersAgreement _sha = _gk.getSHA();

        RulesParser.VotingRule memory vr = 
            _sha.getRule(typeOfIA).votingRuleParser();

        uint seqOfMotion = _roa.getHeadOfFile(address(_ia)).seqOfMotion;

        if (vr.amountRatio > 0 || vr.headRatio > 0) {
            if (vr.authority == 1)
                require(_gmm.isPassed(seqOfMotion), 
                    "BOIK.vrCheck:  rejected by GM");
            else if (vr.authority == 2)
                require(_bmm.isPassed(seqOfMotion), 
                    "BOIK.vrCheck:  rejected by Board");
            else if (vr.authority == 3)
                require(_gmm.isPassed(seqOfMotion) && 
                    _bmm.isPassed(seqOfMotion), 
                    "BOIK.vrCheck: rejected by GM or Board");
            else revert("BOIK.vrCheck: authority overflow");
        }

        if (isST && _sha.hasTitle(uint8(IShareholdersAgreement.TitleOfTerm.LockUp))) {
            address lu = _sha.getTerm(uint8(IShareholdersAgreement.TitleOfTerm.LockUp));
            require(
                ILockUp(lu).isExempted(address(_ia), _ia.getDeal(seqOfDeal)),
                "ROAKeeper.lockUpCheck: not exempted");
        }
    }

    function closeDeal(
        address ia,
        uint256 seqOfDeal,
        string memory hashKey
    ) external onlyDK {

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        if (_ia.closeDeal(deal.head.seqOfDeal, hashKey))
            _gk.getROA().execFile(ia);

        if (deal.head.seqOfShare > 0) 
            _shareTransfer(_ia, deal.head.seqOfDeal);
        else _issueNewShare(_ia, deal.head.seqOfDeal);
    }

    function _shareTransfer(IInvestmentAgreement _ia, uint256 seqOfDeal) private {
        
        IRegisterOfShares _ros = _gk.getROS();
        IRegisterOfMembers _rom = _gk.getROM();

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        _ros.increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);
        _ros.transferShare(deal.head.seqOfShare, deal.body.paid, deal.body.par, 
            deal.body.buyer, deal.head.priceOfPaid, deal.head.priceOfPar);

        if (deal.body.buyer != deal.body.groupOfBuyer && 
            deal.body.groupOfBuyer != _rom.groupRep(deal.body.buyer)) 
                _rom.addMemberToGroup(deal.body.buyer, deal.body.groupOfBuyer);
    }

    function issueNewShare(address ia, uint256 seqOfDeal, uint caller) public onlyDK {
        
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        require(_gk.getROD().isDirector(caller) ||
            _gk.getROM().controllor() == caller, 
            "ROAK.issueNewShare: not director or controllor");

        _vrAndSHACheck(_ia, seqOfDeal, false);

        if (_ia.directCloseDeal(seqOfDeal)) _gk.getROA().execFile(ia);

        _issueNewShare(_ia, seqOfDeal);
    }

    function _issueNewShare(IInvestmentAgreement _ia, uint seqOfDeal) private {
        
        IRegisterOfShares _ros = _gk.getROS();
        IRegisterOfMembers _rom = _gk.getROM();

        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);
        SharesRepo.Share memory share;

        share.head = SharesRepo.Head({
            seqOfShare: 0,
            preSeq: 0,
            class: deal.head.classOfShare,
            issueDate: uint48(block.timestamp),
            shareholder: deal.body.buyer,
            priceOfPaid: deal.head.priceOfPaid,
            priceOfPar: deal.head.priceOfPar,
            votingWeight: deal.head.votingWeight,
            argu: 0
        });

        share.body = SharesRepo.Body({
            payInDeadline: uint48(block.timestamp) + 43200,
            paid: deal.body.paid,
            par: deal.body.par,
            cleanPaid: deal.body.paid,
            state: 0,
            para: 0
        });

        _ros.addShare(share);
        
        if (deal.body.buyer != deal.body.groupOfBuyer &&
            deal.body.groupOfBuyer != _rom.groupRep(deal.body.buyer))
                _rom.addMemberToGroup(deal.body.buyer, deal.body.groupOfBuyer);
    }


    function transferTargetShare(
        address ia,
        uint256 seqOfDeal,
        uint256 caller
    ) public onlyDK {
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        require(
            caller == _ia.getDeal(seqOfDeal).head.seller,
                "BOIK.TTS: not seller"
        );


        _vrAndSHACheck(_ia, seqOfDeal, true);

        if (_ia.directCloseDeal(seqOfDeal))
            _gk.getROA().execFile(ia);

        _shareTransfer(_ia, seqOfDeal);
    }

    function terminateDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller
    ) external onlyDK {
        
        IRegisterOfAgreements _roa = _gk.getROA();

        DealsRepo.Deal memory deal = IInvestmentAgreement(ia).getDeal(seqOfDeal);

        require(
            caller == deal.head.seller,
            "BOIK.TD: NOT seller"
        );

        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        uint8 state = _roa.getHeadOfFile(ia).state;

        if ((state < uint8(FilesRepo.StateOfFile.Proposed) &&
                block.timestamp >= _roa.terminateStartpoint(ia)) || 
            (state == uint8(FilesRepo.StateOfFile.Rejected)) ||
            (state == uint8(FilesRepo.StateOfFile.Approved) &&
                block.timestamp >= _ia.getDeal(seqOfDeal).head.closingDeadline)
        ) {
            if (_ia.terminateDeal(seqOfDeal))
                _roa.terminateFile(ia);
            if (_ia.releaseDealSubject(seqOfDeal))
                _gk.getROS().increaseCleanPaid(deal.head.seqOfShare, deal.body.paid);            
        } else revert("BOIK.TD: wrong state");
    }


    function payOffApprovedDeal(
        address ia,
        uint seqOfDeal,
        uint msgValue,
        uint caller
    ) external onlyDK {
        
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);

        DealsRepo.Deal memory deal = 
            _ia.getDeal(seqOfDeal);

        _vrAndSHACheck(_ia, deal.head.seqOfDeal, deal.head.seqOfShare != 0);

        require((deal.body.paid * deal.head.priceOfPaid + 
            (deal.body.par - deal.body.paid) * deal.head.priceOfPar) * 
            _gk.getCentPrice() / 100 <= msgValue, "ROAK.payApprDeal: insufficient msgValue");

        if (_ia.payOffApprovedDeal(seqOfDeal, msgValue, caller)) 
            _gk.getROA().execFile(ia);

        if (deal.head.seqOfShare > 0) {
            _gk.saveToCoffer(deal.head.seller, msgValue);
            _shareTransfer(_ia, deal.head.seqOfDeal);
        } else {
            _issueNewShare(_ia, deal.head.seqOfDeal);
        }
    }
    
}
