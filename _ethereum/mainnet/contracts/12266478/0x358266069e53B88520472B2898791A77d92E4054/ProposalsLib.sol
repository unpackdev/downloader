// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IControllable.sol";
import "./IProposalFactory.sol";
import "./IProposal.sol";
import "./INFTGemGovernor.sol";
import "./INFTGemFeeManager.sol";
import "./INFTGemPoolData.sol";
import "./INFTGemFeeManager.sol";

import "./ChangeFeeProposalData.sol";
import "./CreatePoolProposalData.sol";
import "./FundProjectProposalData.sol";
import "./UpdateAllowlistProposalData.sol";

import "./GovernanceLib.sol";

library ProposalsLib {
    event GovernanceTokenIssued(address indexed receiver, uint256 amount);
    event FeeUpdated(address indexed proposal, address indexed token, uint256 newFee);
    event AllowList(address indexed proposal, address indexed pool, address indexed token, bool isBanned);
    event ProjectFunded(address indexed proposal, address indexed receiver, uint256 received);

    // create a proposal and associate it with passed-in proposal data
    function associateProposal(
        address governor,
        address multitoken,
        address proposalFactory,
        address submitter,
        IProposal.ProposalType propType,
        string memory title,
        address data
    ) internal returns (address p) {
        p = IProposalFactory(proposalFactory).createProposal(submitter, title, data, propType);
        IProposal(p).setMultiToken(multitoken);
        IProposal(p).setGovernor(governor);
        IControllable(multitoken).addController(p);
        IControllable(governor).addController(p);
    }

    // create a new pool proposal
    function createNewPoolProposal(
        string memory symbol,
        string memory name,

        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffStep,
        uint256 maxClaims,

        address allowedToken
    ) public returns (address) {
        return
            address(
                new CreatePoolProposalData(
                    symbol,
                    name,

                    ethPrice,
                    minTime,
                    maxTime,
                    diffStep,
                    maxClaims,

                    allowedToken
                )
            );
    }

    // create a fee change proposal
    function createChangeFeeProposal(
        address token,
        address pool,
        uint256 feeDivisor
    ) public returns (address) {
        return address(
            new ChangeFeeProposalData(
                token,
                pool,
                feeDivisor));
    }

    // create a project funding proposal
    function createFundProjectProposal(
        address receiver,
        string memory descriptionUrl,
        uint256 ethAmount
    ) public returns (address) {
        return address(new FundProjectProposalData(
            receiver,
            descriptionUrl,
            ethAmount));
    }

    // create an allowlist modify proposal
    function createUpdateAllowlistProposal(
        address token,
        address pool,
        bool newStatus
    ) public returns (address) {
        return address(new UpdateAllowlistProposalData(token, pool, newStatus));
    }

    /**
     * @dev execute this proposal if it is in the right state. Anyone can execute a proposal
     */
    function executeProposal(
        address multitoken,
        address factory,
        address governor,
        address feeTracker,
        address swapHelper,
        address proposalAddress
    ) external {
        require(proposalAddress != address(0), "INVALID_PROPOSAL");
        require(IProposal(proposalAddress).status() == IProposal.ProposalStatus.PASSED, "PROPOSAL_NOT_PASSED");
        address prop = IProposal(proposalAddress).proposalData();
        require(prop != address(0), "INVALID_PROPOSAL_DATA");

        // craete a new NFT mining pool
        if (IProposal(proposalAddress).proposalType() == IProposal.ProposalType.CREATE_POOL) {
            address pool = GovernanceLib.execute(factory, proposalAddress);
            IControllable(multitoken).addController(pool);
            IControllable(governor).addController(pool);
            INFTGemPool(pool).setMultiToken(multitoken);
            INFTGemPool(pool).setSwapHelper(swapHelper);
            INFTGemPool(pool).setGovernor(address(this));
            INFTGemPool(pool).setFeeTracker(feeTracker);
            INFTGemPool(pool).mintGenesisGems(IProposal(proposalAddress).creator(), IProposal(proposalAddress).funder());
        }
        // fund a project
        else if (IProposal(proposalAddress).proposalType() == IProposal.ProposalType.FUND_PROJECT) {
            (address receiver, , uint256 amount) = IFundProjectProposalData(prop).data();
            INFTGemFeeManager(feeTracker).transferEth(payable(receiver), amount);
            emit ProjectFunded(address(proposalAddress), address(receiver), amount);
        }
        // change a fee
        else if (IProposal(proposalAddress).proposalType() == IProposal.ProposalType.CHANGE_FEE) {
            require(prop != address(0), "INVALID_PROPOSAL_DATA");
            address proposalData = IProposal(proposalAddress).proposalData();
            (address token, address pool, uint256 feeDiv) = IChangeFeeProposalData(proposalData).data();
            require(feeDiv != 0, "INVALID_FEE");
            if (token != address(0)) INFTGemFeeManager(feeTracker).setFeeDivisor(token, feeDiv);
            if (pool != address(0)) INFTGemFeeManager(feeTracker).setFeeDivisor(pool, feeDiv);
            if (token == address(0) && pool == address(0)) {
                INFTGemFeeManager(feeTracker).setDefaultFeeDivisor(feeDiv);
            }
        }
        // modify the allowlist
        else if (IProposal(proposalAddress).proposalType() == IProposal.ProposalType.UPDATE_ALLOWLIST) {
            address proposalData = IProposal(proposalAddress).proposalData();
            (address token, address pool, bool isAllowed) = IUpdateAllowlistProposalData(proposalData).data();
            require(token != address(0), "INVALID_TOKEN");
            if (isAllowed) {
                INFTGemPoolData(pool).addAllowedToken(token);
                emit AllowList(proposalAddress, pool, token, isAllowed);
            } else {
                INFTGemPoolData(pool).removeAllowedToken(token);
            }
        }
    }
}
