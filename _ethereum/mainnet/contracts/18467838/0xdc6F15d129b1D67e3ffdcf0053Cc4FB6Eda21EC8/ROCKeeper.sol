// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./AccessControl.sol";

import "./IROCKeeper.sol";

contract ROCKeeper is IROCKeeper, AccessControl {
    using RulesParser for bytes32;
    
    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyPartyOf(address body, uint256 caller) {
        require(ISigPage(body).isParty(caller), "NOT Party of Doc");
        _;
    }

    // #############
    // ##   SHA   ##
    // #############

    function createSHA(
        uint version, 
        address primeKeyOfCaller, 
        uint caller
    ) external onlyDK {

        require(_gk.getROM().isMember(caller), "not MEMBER");

        bytes32 snOfDoc = bytes32((uint256(uint8(IRegCenter.TypeOfDoc.SHA)) << 224) +
            uint224(version << 192)); 

        DocsRepo.Doc memory doc = _rc.createDoc(snOfDoc, primeKeyOfCaller);

        IAccessControl(doc.body).init(
            primeKeyOfCaller,
            address(this),
            address(_rc),
            address(_gk)
        );

        IShareholdersAgreement(doc.body).initDefaultRules();

        _gk.getROC().regFile(DocsRepo.codifyHead(doc.head), doc.body);
    }

    function circulateSHA(
        address sha,
        bytes32 docUrl,
        bytes32 docHash,
        uint256 caller
    ) external onlyDK onlyPartyOf(sha, caller) {
        require(IAccessControl(sha).isFinalized(), 
            "BOHK.CSHA: SHA not finalized");

        
        IShareholdersAgreement _sha = IShareholdersAgreement(sha);

        _sha.circulateDoc();

        uint16 signingDays = _sha.getSigningDays();
        uint16 closingDays = _sha.getClosingDays();

        RulesParser.VotingRule memory vr = address(_gk.getSHA()) == address(0) 
            ? _sha.getRule(8).votingRuleParser()
            : _gk.getSHA().getRule(8).votingRuleParser();

        _gk.getROC().circulateFile(sha, signingDays, closingDays, vr, docUrl, docHash);
    }

    // ======== Sign SHA ========

    function signSHA(
        address sha,
        bytes32 sigHash,
        uint256 caller
    ) external onlyDK onlyPartyOf(sha, caller) {

        require(
            _gk.getROC().getHeadOfFile(sha).state == uint8(FilesRepo.StateOfFile.Circulated),
            "SHA not in Circulated State"
        );

        ISigPage(sha).signDoc(true, caller, sigHash);
    }

    function activateSHA(address sha, uint256 caller)
        external onlyDK onlyPartyOf(sha, caller)
    {
        
        IRegisterOfConstitution _roc = _gk.getROC();
        IRegisterOfMembers _rom = _gk.getROM();

        require(sha != address(0), "ROCK.actSHA: zero sha");
        IShareholdersAgreement _sha = IShareholdersAgreement(sha);

        if (address(_gk.getSHA()) == address(0)) {
            uint[] memory members = _rom.membersList();
            for (uint i; i<members.length; i++)
                require (_sha.isSigner(members[i]), 
                    "ROCK.actSHA: member not sign");
            _roc.setStateOfFile(sha, uint8(FilesRepo.StateOfFile.Closed));
        } else {
            _gk.getGMM().execResolution(
                _roc.getHeadOfFile(sha).seqOfMotion,
                uint(uint160(sha)),
                caller
            );
            _roc.execFile(sha);
        }

        _roc.changePointer(sha);

        RulesParser.GovernanceRule memory gr = 
            _sha.getRule(0).governanceRuleParser();

        if (_rom.maxQtyOfMembers() != gr.maxQtyOfMembers)
            _rom.setMaxQtyOfMembers(gr.maxQtyOfMembers);

        _rom.setVoteBase(gr.basedOnPar);

        if (_rom.minVoteRatioOnChain() != gr.minVoteRatioOnChain)
            _rom.setMinVoteRatioOnChain(gr.minVoteRatioOnChain);
        
        if (_sha.hasTitle(uint8(IShareholdersAgreement.TitleOfTerm.Options))) 
            _regOptionTerms(_sha);

        _updatePositionSetting(_sha);
        _updateGrouping(_sha);
    }

    function _regOptionTerms(IShareholdersAgreement _sha) private {
        address opts = _sha.getTerm(uint8(IShareholdersAgreement.TitleOfTerm.Options));
        _gk.getROO().regOptionTerms(opts);
    }

    function _updatePositionSetting(IShareholdersAgreement _sha) private {
        IRegisterOfDirectors _rod = _gk.getROD();

        uint256 len = _sha.getRule(256).positionAllocateRuleParser().qtyOfSubRule;
        uint256 i;
        while (i < len) {
            RulesParser.PositionAllocateRule memory rule = 
                _sha.getRule(256+i).positionAllocateRuleParser();

            if (rule.removePos) {
                _rod.removePosition(rule.seqOfPos);
            } else {
                OfficersRepo.Position memory pos = _rod.getPosition(rule.seqOfPos);
                pos = OfficersRepo.Position({
                    title: rule.titleOfPos,
                    seqOfPos: rule.seqOfPos,
                    acct: pos.acct,
                    nominator: rule.nominator,
                    startDate: pos.startDate,
                    endDate: rule.endDate,
                    seqOfVR: rule.seqOfVR,
                    titleOfNominator: rule.titleOfNominator,
                    argu: rule.argu
                });
                
                _rod.updatePosition(pos);
            }

            i++;
        }                
    }


    function _updateGrouping(IShareholdersAgreement _sha) private {
        IRegisterOfMembers _rom = _gk.getROM();

        uint256 len = _sha.getRule(768).groupUpdateOrderParser().qtyOfSubRule;
        uint256 i;

        while (i < len) {
            RulesParser.GroupUpdateOrder memory order = 
                _sha.getRule(768+i).groupUpdateOrderParser();

            uint256 j;        
            if (order.addMember) {
                while (j < 4) {
                    if (order.members[j] > 0)
                        _rom.addMemberToGroup(order.members[j], order.groupRep);
                    j++;
                }
            } else {
                while (j < 4) {
                    if (order.members[j] > 0)
                        _rom.removeMemberFromGroup(order.members[j]);
                    j++;
                }
            }

            i++;
        }        
    }

    function acceptSHA(bytes32 sigHash, uint256 caller) external onlyDK {
        IShareholdersAgreement _sha = _gk.getSHA();
        _sha.addBlank(false, true, 1, caller);
        _sha.signDoc(false, caller, sigHash);
    }
}
