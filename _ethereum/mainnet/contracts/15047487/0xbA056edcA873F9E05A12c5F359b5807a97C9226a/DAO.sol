// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Auction.sol";


contract DAO is Auction {
    struct Vote {
        address author;
        string comment;
        uint256 createdTime;
        uint256 upVotes;
        uint256 downVotes;
    }

    struct Compatibility {
        string trait;
        string value;
        string variation;
        string baseTrait;
        string baseValue;
        string baseVariation;
        bool compatsEnabled;
        bool compatible;
    }

    struct Proposal {
        address author;
        string proposal;
        uint256 amount;
        uint256 createdTime;
        uint256 commentsCount;
        uint256 compatsCount;
        uint256 votersCount;
        uint256 upVotes;
        uint256 downVotes;
        uint256 endTime;
        bool finished;
    }

    uint256 public proposalDuration;
    uint256 public minBalanceForProposalCreation;
    uint256 public minBalanceForVoting;

    Proposal[] public proposals;
    Compatibility[][] public compatibilities;
    Vote[][] public comments;
    address[][] public voters;
    mapping(address => Vote)[] public votes;

    uint256 public proposalsCount;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 mutagenFrequency_,
        uint256 autoMintInterval_,
        uint256 creatorRoyalty_,
        uint256 treasureRoyalty_,
        uint256 proposalDuration_,
        uint256 minBalanceForProposalCreation_,
        uint256 minBalanceForVoting_
    ) Auction(name_, symbol_, baseURI_, mutagenFrequency_, autoMintInterval_, creatorRoyalty_, treasureRoyalty_) {
        proposalDuration = proposalDuration_;
        minBalanceForProposalCreation = minBalanceForProposalCreation_;
        minBalanceForVoting = minBalanceForVoting_;
    }

    function createProposal(
        string memory proposal,
        uint256 amount,
        Compatibility[] memory compats
    ) public virtual {
        require(owner() == _msgSender() || balanceOf(_msgSender()) >= minBalanceForProposalCreation, "D1");

        for (uint256 i = 0; i < proposals.length; i++) {
            if (!proposals[i].finished && block.timestamp >= proposals[i].endTime) {
                finishProposal(i);
            }
        }

        proposals.push();
        compatibilities.push();
        comments.push();
        votes.push();
        voters.push();

        Proposal storage p = proposals[proposalsCount];
        p.author = _msgSender();
        p.proposal = proposal;
        p.amount = amount;
        p.createdTime = block.timestamp;
        p.endTime = block.timestamp + proposalDuration;
        p.compatsCount = compats.length;

        for (uint256 i = 0; i < compats.length; i++) {
            compatibilities[proposalsCount].push(compats[i]);
        }

        proposalsCount += 1;
    }

    function _validProposalIdx(uint256 proposalIdx) internal virtual {
        require(proposalIdx < proposalsCount, "D2");
    }

    modifier validProposalIdx(uint256 proposalIdx) virtual {
        _validProposalIdx(proposalIdx);
        _;
    }

    modifier proposalNotFinished(uint256 proposalIdx) virtual {
        require(!proposals[proposalIdx].finished, "D3");
        _;
    }

    function vote(
        uint256 proposalIdx,
        string memory comment,
        bool value
    ) public virtual validProposalIdx(proposalIdx) proposalNotFinished(proposalIdx) {
        uint256 _votes = balanceOf(_msgSender());

        Proposal storage p = proposals[proposalIdx];

        require(block.timestamp < p.endTime, "D7");
        require(owner() == _msgSender() || _votes >= minBalanceForVoting, "D4");

        Vote storage v = votes[proposalIdx][_msgSender()];

        require(v.author == address(0), "D5");

        if (_votes == 0 && owner() == _msgSender()) {
            _votes = 1;
        }

        if (value) {
            p.upVotes += _votes;
            v.upVotes = _votes;
        } else {
            p.downVotes += _votes;
            v.downVotes = _votes;
        }

        voters[proposalIdx].push(_msgSender());

        p.votersCount++;

        v.author = _msgSender();
        v.comment = comment;
        v.createdTime = block.timestamp;

        if (bytes(comment).length > 0) {
            comments[proposalIdx].push(v);
            p.commentsCount += 1;
        }

        // Add long term randomness
        _randint(block.timestamp);
    }

    function finishProposal(uint256 proposalIdx) public virtual validProposalIdx(proposalIdx) proposalNotFinished(proposalIdx) {
        Proposal storage p = proposals[proposalIdx];
        require((owner() == _msgSender() && p.amount == 0) || block.timestamp >= p.endTime, "D6");
        p.finished = true;

        if (p.downVotes >= p.upVotes) {
            return;
        }

        Compatibility[] storage compats = compatibilities[proposalIdx];
        for (uint256 i = 0; i < compats.length; i++) {
            Compatibility storage c = compats[i];
            if (bytes(c.baseTrait).length > 0 && bytes(c.baseValue).length > 0 && bytes(c.baseVariation).length > 0) {
                _ensureVariation(c.baseTrait, c.baseValue, c.baseVariation);
            }
            if (bytes(c.trait).length > 0 && bytes(c.value).length > 0 && bytes(c.variation).length > 0) {
                _ensureVariation(c.trait, c.value, c.variation);
                if (bytes(c.baseTrait).length > 0) {
                    _setCompatibility(c.trait, c.value, c.variation, c.baseTrait, c.baseValue, c.baseVariation, c.compatsEnabled, c.compatible);
                }
            }
        }

        if (p.amount > treasureAmount) {
            balances[p.author] += treasureAmount;
            treasureAmount = 0;
        } else {
            balances[p.author] += p.amount;
            treasureAmount -= p.amount;
        }

        if (_nfts.length == 0) {
            _genTraits(true, 0, 0);
        }
    }
}
