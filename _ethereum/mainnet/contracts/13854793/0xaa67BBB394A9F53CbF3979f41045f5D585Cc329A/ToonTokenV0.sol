/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./ERC20Upgradeable.sol";

import "./Calculator.sol";
import "./Elections.sol";
import "./ElectionsPrincipal.sol";
import "./Proposals.sol";

import "./InitializableUpgrades.sol";

import "./LUTs.sol";
import "./Voting.sol";
import "./ChainlinkETHUSD.sol";

// solhint-disable ordering
abstract contract ToonTokenV0 is
    ERC20Upgradeable,
    InitializableUpgrades,
    LUTs,
    Voting,
    ChainlinkETHUSD,
    ElectionsPrincipal
{
    uint256 public currentPricePerToken;

    bool public consensus;

    address public maintainer;

    address public maintainerWallet;

    address public bountyWallet;

    address payable public proposedDistributionAddress;

    uint256 public proposedDistributionAmount;

    uint256 public distributionProposedAt;

    address public proposedUpgradeImpl;

    uint256 public upgradeProposedAt;

    string private _overriddenName;

    event ConsensusChanged(bool newValue);

    event MaintainerChanged(address newValue);

    event MaintainerBonusWalletChanged(address nextMaintainerWallet);

    event BountyBonusWalletChanged(address nextBountyWallet);

    event DistributionProposed(
        address payable nextProposedDistributionAddress,
        uint256 nextProposedDistributionAmount
    );

    event UpgradeProposed(address nextProposedUpgradeImpl);

    event ProposedDistributionExecuted(uint256 amount, address recipient);

    event ProposedUpgradeExecuted(address newImplementation);

    function _onlyMaintainer() private view {
        require(_msgSender() == maintainer, "only maintainer");
    }

    modifier onlyMaintainer() {
        _onlyMaintainer();
        _;
    }

    function _hasConsensus() private view {
        require(consensus == true, "community must reach consensus");
    }

    modifier hasConsensus() {
        _hasConsensus();
        _;
    }

    function initialize()
        external
        virtual
        override
        initializer
        implementationInitializer
    {
        __ToonTokenV0_init();
    }

    // solhint-disable-next-line func-name-mixedcase
    function __ToonTokenV0_init()
        internal
        initializer
        implementationInitializer
    {
        __ERC20_init("Toon Token (ToonCoin)", "TOON");
        __ToonTokenV0_init_unchained();
    }

    // solhint-disable-next-line func-name-mixedcase
    function __ToonTokenV0_init_unchained()
        internal
        initializer
        implementationInitializer
    {
        consensus = true;
    }

    function name() public view virtual override returns (string memory) {
        if (bytes(_overriddenName).length == 0) return super.name();
        return _overriddenName;
    }

    function overrideName(string memory overriddenName_) external {
        require(
            address(0) == maintainer || _msgSender() == maintainer,
            "not authorized"
        );
        _overriddenName = overriddenName_;
    }

    function vote(address candidate) external {
        require(votesOf(_msgSender()) > 0, "voting for tokenholders");

        _vote(_msgSender(), candidate);
    }

    function candidateOf(address voter) public view override returns (address) {
        return _votersDecisions[voter];
    }

    function holdElectionsAndUpdate() external {
        (
            address winningCandidate,
            uint256 winningCandidateVotes,
            uint256 runnerUpCandidateVotes,
            uint256 totalVotes
        ) = Elections.findTop2(_voters, ElectionsPrincipal(this));

        bool newConsensus = Elections.calcConsensus(
            winningCandidateVotes,
            totalVotes
        );

        if (false == consensus && true == newConsensus) {
            require(
                msg.sender == winningCandidate,
                "only a winner can allow consensus to be restored"
            );
        }

        _finishElections(
            newConsensus,
            winningCandidate,
            runnerUpCandidateVotes,
            totalVotes
        );
    }

    function confirmConsensusAndUpdate(
        address winningCandidate,
        address[] memory voters,
        address[] memory abstainedVoters
    ) external {
        uint256 winningCandidateVotes = Elections.sumVotesFor(
            winningCandidate,
            voters,
            ElectionsPrincipal(this)
        );

        uint256 abstainedVotes = Elections.sumVotesFor(
            address(0),
            abstainedVoters,
            ElectionsPrincipal(this)
        );

        uint256 totalVotes = totalSupply() - abstainedVotes;

        if (Elections.calcConsensus(winningCandidateVotes, totalVotes)) {
            if (false == consensus) {
                require(
                    msg.sender == winningCandidate,
                    "only a winner can allow consensus to be restored"
                );
            }

            uint256 runnerUpCandidateVotes = totalVotes - winningCandidateVotes;
            _finishElections(
                true,
                winningCandidate,
                runnerUpCandidateVotes,
                totalVotes
            );
        }
    }

    function breakConsensus(
        address[] memory alternativeCandidateVoters,
        address[] memory abstainedVoters
    ) external hasConsensus {
        uint256 votes = Elections.sumVotesExceptZeroAnd(
            maintainer,
            alternativeCandidateVoters,
            ElectionsPrincipal(this)
        );

        uint256 abstainedVotes = Elections.sumVotesFor(
            address(0),
            abstainedVoters,
            ElectionsPrincipal(this)
        );

        uint256 totalVotes = totalSupply() - abstainedVotes;
        uint256 maintainerVotes = totalVotes - votes;

        if (!Elections.calcConsensus(maintainerVotes, totalVotes)) {
            _finishElections(false, maintainer, votes, totalVotes);
        }
    }

    function _finishElections(
        bool newConsensus,
        address winningCandidate,
        uint256 runnerUpCandidateVotes,
        uint256 totalVotes
    ) private {
        if (consensus != newConsensus) {
            consensus = newConsensus;
            emit ConsensusChanged(newConsensus);
        }

        if (maintainer != winningCandidate) {
            _dropProposals();
            maintainer = winningCandidate;
            emit MaintainerChanged(winningCandidate);
        }

        if (consensus) {
            _performProposedDistribution(runnerUpCandidateVotes, totalVotes);
            _performProposedUpgrade(runnerUpCandidateVotes, totalVotes);
        }
    }

    function _performProposedDistribution(
        uint256 runnerUpCandidateVotes,
        uint256 totalVotes
    ) private {
        if (
            consensus &&
            proposedDistributionAddress != address(0) &&
            Proposals.isExecutionAllowed(
                distributionProposedAt,
                runnerUpCandidateVotes,
                totalVotes
            )
        ) {
            address payable recipient = proposedDistributionAddress;
            uint256 amount = proposedDistributionAmount;

            proposedDistributionAddress = payable(0);
            proposedDistributionAmount = 0;

            (bool success, ) = recipient.call{value: amount}("");
            require(success, "proposed distribution failed");

            emit ProposedDistributionExecuted(amount, recipient);
        }
    }

    function _performProposedUpgrade(
        uint256 runnerUpCandidateVotes,
        uint256 totalVotes
    ) private {
        if (
            consensus &&
            proposedUpgradeImpl != address(0) &&
            Proposals.isExecutionAllowed(
                upgradeProposedAt,
                runnerUpCandidateVotes,
                totalVotes
            )
        ) {
            address impl = proposedUpgradeImpl;
            proposedUpgradeImpl = address(0);

            _upgradeTo(impl);
            emit ProposedUpgradeExecuted(impl);
        }
    }

    function setWallets(address nextMaintainerWallet, address nextBountyWallet)
        external
        onlyMaintainer
    {
        if (maintainerWallet != nextMaintainerWallet) {
            maintainerWallet = nextMaintainerWallet;
            emit MaintainerBonusWalletChanged(maintainerWallet);
        }

        if (bountyWallet != nextBountyWallet) {
            bountyWallet = nextBountyWallet;
            emit BountyBonusWalletChanged(bountyWallet);
        }
    }

    function proposeDistribution(
        address payable nextProposedDistributionAddress,
        uint256 nextProposedDistributionAmount
    ) external onlyMaintainer {
        require(
            address(this).balance >= nextProposedDistributionAmount,
            "too much"
        );

        proposedDistributionAddress = nextProposedDistributionAddress;
        proposedDistributionAmount = nextProposedDistributionAmount;
        distributionProposedAt = block.timestamp;

        emit DistributionProposed(
            proposedDistributionAddress,
            proposedDistributionAmount
        );
    }

    function proposeUpgrade(address nextProposedUpgradeImpl)
        external
        onlyMaintainer
    {
        proposedUpgradeImpl = nextProposedUpgradeImpl;
        upgradeProposedAt = block.timestamp;
        emit UpgradeProposed(proposedUpgradeImpl);
    }

    function _dropProposals() private {
        proposedDistributionAddress = payable(0);
        proposedUpgradeImpl = address(0);
    }

    function votesOf(address account) public view override returns (uint256) {
        return balanceOf(account);
    }

    receive() external payable hasConsensus {
        address buyer = _msgSender();
        _purchase(buyer, _convertEthToUsd(msg.value));

        if (
            candidateOf(buyer) == address(0) &&
            balanceOf(buyer) > (1000 * 10**decimals())
        ) {
            _vote(buyer, maintainer);
        }
    }

    function purchase() external payable hasConsensus {
        _purchase(_msgSender(), _convertEthToUsd(msg.value));
    }

    function purchaseAndVote(address candidate) external payable hasConsensus {
        _purchase(_msgSender(), _convertEthToUsd(msg.value));
        _vote(_msgSender(), candidate);
    }

    function _purchase(address account, uint256 usdAmount) internal {
        require(account != address(0), "purchase from the zero address");
        require(usdAmount > 0, "no funds");

        Calculator.Result memory r = Calculator.calcTokens(
            usdAmount,
            totalSupply(),
            _nodeId,
            address(0) == maintainerWallet,
            address(0) == bountyWallet,
            _supplyLUT,
            _priceLUT
        );

        _nodeId = r.nextNodeId;
        currentPricePerToken = r.nextPricePerToken;

        _mint(account, r.tokensAmount);

        if (r.maintainerBonusTokensAmount > 0)
            _mintMaintainerBonus(r.maintainerBonusTokensAmount);

        if (r.bountyBonusTokensAmount > 0)
            _mintBountyBonus(r.bountyBonusTokensAmount);
    }

    function _mintMaintainerBonus(uint256 amount) internal virtual;

    function _mintBountyBonus(uint256 amount) internal virtual;

    uint256[40] private __gap;
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode
