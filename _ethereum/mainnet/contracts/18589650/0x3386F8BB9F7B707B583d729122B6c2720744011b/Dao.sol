//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DaoAbstract.sol";
 
contract Dao is OwnableUpgradeable, DaoStorageV1, DaoEvents {
    mapping(uint256 => Judgement) public judgements; // record of all judgements ever created
    mapping(uint256 => uint) private _blacklistedPirate; // is pirate blacklisted
    mapping(uint256 => Proposal) public proposals; // record of all proposals ever proposed
    mapping(uint256 => uint) proposalActive; // active proposalId of corresponding pirate
    mapping(uint256 => uint) waitingTime; // time left to unlock pirate, or to create new proposals

    modifier onlyAdmin() {
        require(msg.sender == admin, "Unauthorised!");
        _;
    }

    modifier onlyAdminOrNft() {
        require(
            msg.sender == admin || msg.sender == address(nft),
            "Unauthorised!"
        );
        _;
    }

    modifier onlyPirate(uint _pirateId) {
        require(_blacklistedPirate[_pirateId] == 0, "Unauthorised:: blacklisted pirate");
        require(nft.ownerOf(_pirateId) == msg.sender, "Unauthorised:: caller not pirateOwner");
        _;
    }

    modifier onlyValidProposalId(uint _proposalId) {
        require(
            _proposalId > 0 && _proposalId <= proposalCount, "validPID:: Proposal Id doesn't exist!"
        );
        _;
    }

    function initialize() external initializer {
        __Ownable_init_unchained();
        minVotingTime = 172800;  // 2 days
        maxVotingTime = 1209600; // 14 days
        minProposalThreshold = 2 ether;
        maxProposalThreshold = 15 ether;
        maxRefundTime = 2629743; // 1 month
        unlockTime = 604800;    // 
        maxLengthTitle = 32;
        maxLengthLink = 100;
        maxLengthDesc = 200;
        name = "Pirate Dao";
        DOMAIN_TYPEHASH =  keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
        VOTE_PROPOSAL_TYPEHASH = keccak256("VoteProposal(uint256 proposalId,bool voteFor)");
        VOTE_JUDGEMENT_TYPEHASH =  keccak256("VoteJudgement(uint256 judgementId,bool favourJudgment)");
    }

    function setContractAddresses(
        IAddressContract _contractFactory
    ) external onlyOwner {
        bounty = IBOUNTY(_contractFactory.getBounty());
        nft = IERC721Upgradeable(_contractFactory.getPirateNFT());
        treasury = _contractFactory.getTreasury();
    }

    function changeAdmin(address _newAdmin) external onlyOwner {
        address currentAdmin = admin;
        admin = _newAdmin;
        emit AdminChanged(currentAdmin, _newAdmin);
    }

    function setMaxProposalThreshold(uint256 _eth) external onlyAdmin {
        maxProposalThreshold = _eth;
    }

    function setMinxProposalThreshold(uint256 _eth) external onlyAdmin {
        minProposalThreshold = _eth;
    }

    function setMinVotingTime(uint256 _minTime) external onlyAdmin {
        minVotingTime = _minTime;
    }

    function setMaxVotingTime(uint256 _maxTime) external onlyAdmin {
        maxVotingTime = _maxTime;
    }

    function setMaxRefundTime(uint256 _maxRefundTime) external onlyAdmin {
        maxRefundTime = _maxRefundTime;
    }

    function setPirateUnlockTime(uint _unlockTime) external onlyAdmin {
        unlockTime = _unlockTime;
    }

    function setMaxCharacterLength(uint _titleLength, uint _linkLength, uint _descLength) external onlyAdmin {
        maxLengthTitle = _titleLength;
        maxLengthLink = _linkLength;
        maxLengthDesc = _descLength;
    }

    function unlockBlacklistPirate(uint _pirateId) external onlyAdminOrNft {
        _blacklistedPirate[_pirateId] = 0;
        emit UnlockBlacklistPirate(_pirateId, msg.sender);
    }


    function createProposal(
        uint256 pirateId,
        address payable recipient,
        uint256 value,
        uint256 refundTime,
        uint startTime,
        uint endTime,
        ProposalDetails calldata _proposalDetials
    ) external onlyPirate(pirateId) returns (uint256) {
        require(proposalActive[pirateId] == 0, "createProposal:: already active proposal!");
        require(
            waitingTime[pirateId] < block.timestamp,
            "createProposal:: waiting time not ended"
        );

        require(value >= minProposalThreshold, "createProposal:: proposal value too low");
        require(value <= maxProposalThreshold, "createProposal:: proposal value too high");

        uint votingTime = endTime - startTime;

        require(
            minVotingTime <= votingTime && maxVotingTime >= votingTime,
            "createProposal:: invalid voting time"
        );
        require(maxRefundTime >= refundTime, "createProposal:: invalid refund Time");
        require(
            bytes(_proposalDetials.title).length <= maxLengthTitle &&
                bytes(_proposalDetials.description).length <= maxLengthDesc &&
                bytes(_proposalDetials.socialLink).length <= maxLengthLink &&
                bytes(_proposalDetials.docLink).length <= maxLengthLink,
            "createProposal:: title, description, socialLink or docLink len exceed"
        );

        proposalCount++;
        uint proposalId = proposalCount;
        Proposal storage _proposal = proposals[proposalId];
        _proposal.id = proposalId;
        _proposal.pirateId = pirateId;
        _proposal.recipient = recipient;
        _proposal.value = value;
        _proposal.refundTime = refundTime;
        _proposal.startTimestamp = block.timestamp + startTime;
        _proposal.endTimestamp = block.timestamp + endTime;
        _proposal.proposalDetails = _proposalDetials;

        emit NewProposal(proposalId);
        proposalActive[pirateId] = proposalId;
        waitingTime[pirateId] = 0;
        return proposalId;
    }

    function castVote(uint256 proposalId, bool voteFor) external {
        _vote(msg.sender, proposalId, voteFor);
    }

    function castVoteBySig(
        uint256 proposalId,
        bool voteFor,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainIdInternal(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(VOTE_PROPOSAL_TYPEHASH, proposalId, voteFor)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "castVoteBySig:: invalid signature"
        );
        _vote(signatory, proposalId, voteFor);
    }

    function cancelProposal(uint256 _proposalId) external onlyValidProposalId(_proposalId) {
    
        Proposal storage _proposal = proposals[_proposalId];
        uint pirateId = _proposal.pirateId;

        require(!_proposal.executed, "cancelProposal:: proposal already executed");
        require(!_proposal.cancelled, "cancelProposal:: proposal already cancelled");

        require(nft.ownerOf(pirateId) == msg.sender, "cancelProposal:: Unauthorized");

        _proposal.cancelled = true;

        proposalActive[pirateId] = 0;
        waitingTime[pirateId] = 0;
        emit ProposalCancelled(_proposalId);
    }

    function executeProposal(uint256 _proposalId) external onlyValidProposalId(_proposalId) {

        Proposal storage _proposal = proposals[_proposalId];

        require(block.timestamp >= _proposal.endTimestamp, "executeProposal:: voting is still ongoing");
        require(!_proposal.executed, "executeProposal:: proposal already executed");     
        require(!_proposal.cancelled, "executeProposal:: proposal already cancelled"); 

        if (_proposal.votesFor > _proposal.votesAgainst) {
            (bool success, ) = address(treasury).call(
                abi.encodeWithSignature(
                    "fundTransfer(uint256,address,uint256)",
                    _proposalId,
                    _proposal.recipient,
                    _proposal.value
                )
            );
            require(
                success,
                "executeProposal:: Treasury fund transfer failed"
            );
            _proposal.expectedsettlementTime = block.timestamp + _proposal.refundTime;
        } else {
            // proposal executed and closed (settled)
            proposalActive[_proposal.pirateId] = 0;
            RefundDetials storage refunddetails = _proposal.refundDetails;
            refunddetails.settled = true;
        }

        _proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    function refund(uint _proposalId, bool lastPayment) external payable onlyValidProposalId(_proposalId) {

        Proposal storage proposal = proposals[_proposalId];
        require(proposal.executed, "refund:: proposal not executed yet");

        // check whether judgement is raised or not
        Judgement storage _judgement = judgements[
            _proposalId
        ];
        if (_judgement.isSuspected) {
            revert("refund:: no refund time");
        }

        RefundDetials storage refunddetails = proposal.refundDetails;
        require(!refunddetails.settled, "refund:: proposal already settled");

        refunddetails.amount += msg.value;
        refunddetails.lastrefundTime = block.timestamp;

        emit Refund(_proposalId, msg.value);

        if (lastPayment) {
            uint totalrefundValue = refunddetails.amount;
            uint pirateId = proposal.pirateId;
            require(
                nft.ownerOf(pirateId) == msg.sender,
                "refund:: settlement: not pirate"
            );
            refunddetails.settled = true;
            waitingTime[pirateId] = block.timestamp + unlockTime;
            proposalActive[pirateId] = 0;
            (bool success, ) = address(treasury).call{value: totalrefundValue}(
                abi.encodeWithSignature(
                    "distributeProfit(uint256,uint256,uint256,uint256)",
                    _proposalId,
                    proposal.pirateId,
                    proposal.value,
                    totalrefundValue
                )
            );
            require(success, "refund:: settlement failed");

            emit ProposalSettled(_proposalId, totalrefundValue);
        }
    }

    function raiseJudgment(
        uint256 _proposalId,
        uint _pirateId,
        uint256 _value,
        uint votingTime,
        string calldata allegation,
        string calldata allegationDocLink
    ) external onlyPirate(_pirateId) onlyValidProposalId(_proposalId) {

        require(
            minVotingTime < votingTime && maxVotingTime > votingTime,
            "raiseJudgment:: invalid voting time"
        );

        Judgement storage _judgement = judgements[
            _proposalId
        ];
        Proposal storage _suspectedProposal = proposals[_proposalId];

        // check necessary conditions before open any judgement
        require(
            _suspectedProposal.executed,
            "raiseJudgment:: proposal not executed yet"
        );
        require(
            _suspectedProposal.expectedsettlementTime < block.timestamp,
            "raiseJudgment:: wait until expectedsettlementTime"
        );

        // require(_value > _suspectedProposal.value, "raiseJudgment:: judgement amount must be greater than proposal amount");

        uint proposerpirateId = _suspectedProposal.pirateId;
        uint currentActiveProposalId = proposalActive[proposerpirateId];

        if (currentActiveProposalId != 0) {
            require(
                currentActiveProposalId == _proposalId,
                "raiseJudgment:: wrong proposal id"
            );
            require(
                waitingTime[_suspectedProposal.pirateId] == 0,
                "raiseJudgment:: something wrong"
            );
        } else {
            require(
                waitingTime[proposerpirateId] > block.timestamp,
                "raiseJudgment:: judgement creation time over"
            );
        }

        require(proposerpirateId != _pirateId, "raiseJudgment:: proposee can't raise judgement");
        require(
            !_judgement.isSuspected,
            "raiseJudgment:: judgement alreadycreated"
        );

        require(bytes(allegation).length <= maxLengthDesc &&
                bytes(allegationDocLink).length <= maxLengthLink,
            "raiseJudgment:: title, description len exceed"
        );

        _judgement.author = _pirateId;
        _judgement.value = _value;
        _judgement.proposalId = _proposalId;
        _judgement.startTimestamp = block.timestamp;
        _judgement.endTimestamp = block.timestamp + votingTime;
        _judgement.isSuspected = true;
        _judgement.judgementDetails.allegation = allegation;
        _judgement.judgementDetails.allegationDocLink = allegationDocLink;

        proposalActive[_suspectedProposal.pirateId] = _proposalId;

        emit JudgmentProposed(
            _pirateId,
            proposerpirateId,
            _proposalId
        );
    }

    function explainJudgment(
        uint _proposalId,
        string calldata _explanation,
        string calldata _explanationLink
    ) external onlyValidProposalId(_proposalId) {
       
        Proposal storage proposal = proposals[_proposalId];
        Judgement storage _judgement = judgements[
            _proposalId
        ];

        require(_judgement.isSuspected, "explainJudgment:: pirate not suspected!");
        uint pirateId = proposal.pirateId;
        require(nft.ownerOf(pirateId) == msg.sender, "explainJudgment:: caller not proposer");
        require(
            block.timestamp < _judgement.endTimestamp,
            "explainJudgment:: explaination time over"
        );

        require(bytes(_explanation).length <= maxLengthDesc &&
                bytes(_explanationLink).length <= maxLengthLink,
            "explainJudgment:: title, description len exceed"
        );

        _judgement.judgementDetails.explanation = _explanation;
        _judgement.judgementDetails.explanationLink = _explanationLink;

        emit explainJudgement(_proposalId);
    }

    function castVoteJudgement(
        uint256 _proposalId,
        bool favourJudment
    ) external {
        _voteJudgment(msg.sender, _proposalId, favourJudment);
    }

    function castVoteJudgementBySig(
        uint256 _proposalId,
        bool favourJudment,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainIdInternal(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(VOTE_JUDGEMENT_TYPEHASH, _proposalId, favourJudment)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "castVoteJudgementBySig: invalid signature"
        );
        _voteJudgment(signatory, _proposalId, favourJudment);
    }

    function processJudgment(uint256 _proposalId) external onlyValidProposalId(_proposalId) {

        Judgement storage _judgement = judgements[_proposalId];

        require(
            _judgement.endTimestamp < block.timestamp,
            "processJudgment:: voting live"
        );
        require(_judgement.isSuspected, "processJudgment:: pirateId is not suspected!");
        require(
            !_judgement.isJudgementProcessed,
            "processJudgment:: judgement already processed"
        );

        Proposal storage _proposal = proposals[_proposalId];

        if (
            _judgement.votesForJudgement >=
            _judgement.votesAgainstJudgement
        ) {
            _judgement.isPiratePunished = true;
            _blacklistedPirate[_proposal.pirateId] = _proposalId;
        }
        
        RefundDetials storage _refunddetails = _proposal.refundDetails;
        
        if (!_refunddetails.settled) {
            uint totalrefundValue = _refunddetails.amount;
            _refunddetails.settled = true;
            (bool success, ) = address(treasury).call{value: totalrefundValue}(
                abi.encodeWithSignature(
                    "distributeProfit(uint256,uint256,uint256,uint256)",
                    _proposalId,
                    _proposal.pirateId,
                    _proposal.value,   
                    totalrefundValue 
                ) 
            );
            require(success, "processJudgment:: settlement failed");
            emit ProposalSettled(_proposalId,totalrefundValue);
        } 

        _judgement.isJudgementProcessed = true;

        // close proposal
        uint pirateId = _proposal.pirateId;
        proposalActive[pirateId] = 0;
        waitingTime[pirateId] = block.timestamp;
        emit JudgmentProcessed(_proposalId);
    }

    function getBlackistedProposal(uint _pirateId) external view returns (uint) {
        return _blacklistedPirate[_pirateId];
    }

    function getActiveProposal(uint _pirateId) external view returns (uint) {
        return proposalActive[_pirateId];
    }

    function getPirateWaitingTime(uint _pirateId) external view returns (uint) {
        return waitingTime[_pirateId];
    }

    function getProposalExecuted(
        uint256 proposalId
    ) external view returns (bool) {
        return proposals[proposalId].executed;
    }

    function getJudgementProcessed(
        uint256 proposalId
    ) external view returns (bool) {
        return judgements[proposalId].isJudgementProcessed;
    }

    function getVoteReceipit(
        address _voter,
        uint256 _proposalId
    ) external view returns (Receipt memory) {
        Proposal storage _proposal = proposals[_proposalId];
        Receipt memory receipt = _proposal.receipts[_voter];
        return receipt;
    }

    function getJudgementVoteReceipit(
        address _voter,
        uint256 _proposalId
    ) external view returns (Receipt memory) {
        Judgement storage _judgement = judgements[_proposalId];
        Receipt memory receipt = _judgement.receipts[_voter];
        return receipt;
    }

    function getRefundDetails(
        uint256 _proposalId
    ) external view returns (RefundDetials memory) {
    
        Proposal storage proposal = proposals[_proposalId];
        RefundDetials memory refunddetails = proposal.refundDetails;
        return refunddetails;
    }

    function getProposalDetails(
        uint256 _proposalId
    ) external view returns (ProposalDetails memory) {
        Proposal storage proposal = proposals[_proposalId];
        return proposal.proposalDetails;
    }

    function getJudgementDetails(
        uint256 _proposalId
    ) external view returns (JudgementDetails memory) {
        Judgement storage _judgement = judgements[_proposalId];
        return _judgement.judgementDetails;
    }

    function getProposalAmount(uint proposalId) external view returns (uint) {
        return proposals[proposalId].value;
    }

    function getRefundAmount(uint proposalId) external view returns (uint) {
       return proposals[proposalId].refundDetails.amount;
    }

    function getJudgementAmount(uint proposalId) external view returns (uint) {
       return judgements[proposalId].value;
    }

    function isJudgementRaised(uint proposalId) external view returns (bool) {

        Judgement storage _judgement = judgements[
            proposalId
        ];
        return _judgement.isSuspected; 
    }

    function canRaiseJudgement(uint proposalId) external view returns (bool) {

        Proposal storage _suspectedProposal = proposals[proposalId];

        if (!_suspectedProposal.executed) {
            return false;
        }

        if (_suspectedProposal.expectedsettlementTime > block.timestamp) {
            return false;
        }

        uint proposerpirateId = _suspectedProposal.pirateId;
        uint currentActiveProposalId = proposalActive[proposerpirateId];
        uint waitingTimePirate = waitingTime[proposerpirateId];

        if (currentActiveProposalId != 0) {
            if (currentActiveProposalId != proposalId) {
                return false;
            }
            if (waitingTimePirate != 0) {
                return false;
            }

        } else {
            if (waitingTimePirate < block.timestamp) {
                return false;
            }
        }

        return true;
    }

    function getProposalState(
        uint proposalId
    ) public view returns (ProposalState) {
        require(
            proposalId > 0 && proposalId <= proposalCount,
            "Proposal Id doesn't exist!"
        );
        Proposal storage proposal = proposals[proposalId];
        if (proposal.cancelled) {
            return ProposalState.Canceled;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp <= proposal.startTimestamp) {
            return ProposalState.Pending;
        } else if (block.timestamp <= proposal.endTimestamp) {
            return ProposalState.Active;
        } 
        else {
            return ProposalState.Expired;
        }
    }

    function _vote(address voter, uint256 _proposalId, bool voteFor) internal onlyValidProposalId(_proposalId) {

        require(
            getProposalState(_proposalId) == ProposalState.Active,
            "_vote:: voting not live"
        );
        Proposal storage proposal = proposals[_proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(
            !receipt.hasVoted,
            "_vote:: voter already voted"
        );
       
        uint256 votes = bounty.getPastVotes(voter, proposal.startTimestamp);

        if (voteFor) {
            proposal.votesFor = proposal.votesFor + votes;
        } else {
            proposal.votesAgainst = proposal.votesAgainst + votes;
        }

        receipt.hasVoted = true;
        receipt.support = voteFor;
        receipt.votes = votes;

        emit Vote(_proposalId, voter, voteFor);
    }

    function _voteJudgment(
        address voter,
        uint _proposalId,
        bool favourJudment
    ) internal onlyValidProposalId(_proposalId) {

        Judgement storage _judgement = judgements[
            _proposalId
        ];

        uint256 votes = bounty.getPastVotes(
            voter,
            _judgement.startTimestamp
        );

        Receipt storage receipt = _judgement.receipts[voter];
        require(
            !receipt.hasVoted,
            "_voteJudgment:: voter already voted"
        );

        require(_judgement.isSuspected, "_voteJudgment:: pirate is not suspected!");
        require(
            _judgement.startTimestamp < block.timestamp &&
                _judgement.endTimestamp > block.timestamp,
            "_voteJudgment:: voting not live"
        );

        if (favourJudment) {
            _judgement.votesForJudgement =
                _judgement.votesForJudgement +
                votes;
        } else {
            _judgement.votesAgainstJudgement =
                _judgement.votesAgainstJudgement +
                votes;
        }

        receipt.hasVoted = true;
        receipt.support = favourJudment;
        receipt.votes = votes;
        emit JudgmentVoted(_proposalId, voter, favourJudment, votes);
    }

    function getChainIdInternal() internal view returns (uint) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
