// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

import "./ContractContext.sol";
import "./MilestoneContext.sol";
import "./IEscrowDisputeManager.sol";

abstract contract Amendable is ContractContext, MilestoneContext {
    string private constant ERROR_NOT_PARTY = "Not a payer or payee";
    string private constant ERROR_EMPTY = "Empty amendment";
    string private constant ERROR_AMENDMENT_EXIST = "Amendment exist";
    string private constant ERROR_NOT_VALIDATOR = "Not a validator";
    string private constant ERROR_EARLIER_AMENDMENT = "Not final amendment";
    string private constant ERROR_OVERFUNDED = "Overfunded milestone";

    bytes32 private constant EMPTY_BYTES32 = bytes32(0);
    address private constant EMPTY_ADDRESS = address(0);

    struct Amendment{
        bytes32 cid;
        uint256 timestamp;
    }

    struct AmendmentProposal {
        bytes32 termsCid;
        address validator;
        uint256 timestamp;
    }

    struct SettlementParams {
        bytes32 termsCid;
        address payeeAccount;
        address refundAccount;
        address escrowDisputeManager;
        uint autoReleasedAt;
        uint amount;
        uint refundedAmount;
        uint releasedAmount;
    }

    struct SettlementProposal {
        SettlementParams params;
        address validator;
        uint256 timestamp;
    }

    mapping (bytes32 => Amendment) public contractVersions;
    mapping (bytes32 => bool) public contractVersionApprovals;
    mapping (bytes32 => AmendmentProposal) public contractVersionProposals;
    mapping (bytes32 => SettlementProposal) public settlementProposals;

    event NewContractVersion(
        bytes32 indexed cid,
        bytes32 indexed amendmentCid,
        address indexed validator,
        bytes32 key
    );

    event NewSettlement(
        bytes32 indexed cid,
        uint16 indexed index,
        uint8 revision,
        address indexed validator,
        bytes32 key,
        SettlementParams data
    );

    event ApprovedSettlement(
        bytes32 indexed cid,
        uint16 indexed index,
        uint8 revision,
        bytes32 indexed key,
        address validator
    );

    /**
     * @dev Return IPFS cid of a latest approved contract version.
     *
     * @param _cid Contract's IPFS cid.
     * @return IPFS cid in hex form for a final approved version of a contract or
     * bytes32(0) if no version was approved by both parties.
     */
    function getLatestApprovedContractVersion(bytes32 _cid) public view returns (bytes32) {
        return contractVersions[_cid].cid;
    }

    /**
     * @dev Check if specific contract version was approved by both parties.
     *
     * @param _cid Contract's IPFS cid.
     * @param _termsCid cid of suggested contract version.
     * @return approval by both parties.
     */
    function isApprovedContractVersion(bytes32 _cid, bytes32 _termsCid) public view returns (bool) {
        bytes32 _key = EscrowUtilsLib.genTermsKey(_cid, _termsCid);
        return contractVersionApprovals[_key];
    }

    /**
     * @dev Propose change for the current contract terms.
     *
     * @param _cid Contract's IPFS cid.
     * @param _termsCid New version of contract's IPFS cid.
     */
    function signAndProposeContractVersion(bytes32 _cid, bytes32 _termsCid) external {
        address _payer = contracts[_cid].payer;
        address _payee = contracts[_cid].payee;
        require(msg.sender == _payee || msg.sender == _payer, ERROR_NOT_PARTY);
        _proposeAmendment(_cid, _termsCid, _payee, _payer);
    }

    /**
     * @dev Validate contract version by the opposite party.
     *
     * @param _cid Contract's IPFS cid.
     * @param _termsCid Amendment IPFS cid for approval.
     */
    function signAndApproveContractVersion(bytes32 _cid, bytes32 _termsCid) public {
        bytes32 _key = EscrowUtilsLib.genTermsKey(_cid, _termsCid);
        require(_termsCid != EMPTY_BYTES32, ERROR_EMPTY);
        require(!contractVersionApprovals[_key], ERROR_AMENDMENT_EXIST);
        require(contractVersionProposals[_key].validator == msg.sender, ERROR_NOT_VALIDATOR);
        require(contractVersionProposals[_key].timestamp > contractVersions[_cid].timestamp, ERROR_EARLIER_AMENDMENT);

        _approveAmendment(_cid, contractVersionProposals[_key].termsCid, _key);
        
        // Gas refund
        delete contractVersionProposals[_key];
    }

    /**
     * @dev Propose change to milestone on-chain data.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone to amend.
     * @param _termsCid New version of contract's IPFS cid, pass bytes32(0) to leave old terms.
     * @param _payeeAccount Change address for withdrawals, pass address(0) to leave the old one.
     * @param _refundAccount Change address for refunds, pass address(0) to leave the old one.
     * @param _escrowDisputeManager Smart contract which implements disputes for the escrow, pass address(0) to leave the old one.
     * @param _autoReleasedAt UNIX timestamp for delivery deadline, pass 0 if none.
     * @param _amount Change total size of milestone, may require refund or release.
     * @param _refundedAmount Amount to refund, should't be more than current fundedAmount - claimedAmount - releasedAmount.
     * @param _releasedAmount Amount to release, should't be more than current fundedAmount - claimedAmount - refundedAmount.
     */
    function signAndProposeMilestoneSettlement(
        bytes32 _cid,
        uint16 _index,
        bytes32 _termsCid,
        address _payeeAccount,
        address _refundAccount,
        address _escrowDisputeManager,
        uint _autoReleasedAt,
        uint _amount,
        uint _refundedAmount,
        uint _releasedAmount
    ) external returns (bytes32) {
        address _payer = contracts[_cid].payer;
        address _payee = contracts[_cid].payee;
        require(msg.sender == _payee || msg.sender == _payer, ERROR_NOT_PARTY);

        SettlementParams memory _sp = SettlementParams({
            termsCid: _termsCid,
            payeeAccount: _payeeAccount,
            refundAccount: _refundAccount,
            escrowDisputeManager: _escrowDisputeManager,
            autoReleasedAt: _autoReleasedAt,
            amount: _amount,
            refundedAmount: _refundedAmount,
            releasedAmount: _releasedAmount
        });
        
        return _proposeMilestoneSettlement(
            _cid,
            _index,
            _sp,
            _payer,
            _payee
        );
    }

    /**
     * @dev Save new approved contract version.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone index.
     * @param _revision Current version of milestone extended terms.
     */
    function signApproveAndExecuteMilestoneSettlement(bytes32 _cid, uint16 _index, uint8 _revision) public {
        bytes32 _key = EscrowUtilsLib.genSettlementKey(_cid, _index, _revision);
        require(settlementProposals[_key].validator == msg.sender, ERROR_NOT_VALIDATOR);
        _approveAndExecuteMilestoneSettlement(_cid, _index, _revision);
        
        // Gas refund
        delete settlementProposals[_key];
    }

    /**
     * @dev Proposals are saved in a temporary dictionary until they are approved to contractVersions mapping.
     *
     * It's possible to override existing proposal with a same key, for instance to increase timestamp.
     *
     * @param _cid Contract's IPFS cid.
     * @param _termsCid New version of contract's IPFS cid, pass bytes32(0) to leave old terms.
     * @param _party1 Address of first party (e.g. payer).
     * @param _party2 Address of second party (e.g. payee).
     * @return key for amendment.
     */
    function _proposeAmendment(
        bytes32 _cid,
        bytes32 _termsCid,
        address _party1,
        address _party2
    ) internal returns (bytes32) {
        bytes32 _key = EscrowUtilsLib.genTermsKey(_cid, _termsCid);
        require(_termsCid != EMPTY_BYTES32, ERROR_EMPTY);

        address _validator = _party1;
        if (msg.sender == _party1) _validator = _party2;
        contractVersionProposals[_key] = AmendmentProposal({
            termsCid: _termsCid,
            validator: _validator,
            timestamp: block.timestamp
        });
        emit NewContractVersion(_cid, _termsCid, _validator, _key);
        return _key;
    }

    /**
     * @dev Save new approved contract version.
     *
     * @param _cid Contract's IPFS cid.
     * @param _termsCid New version of contract's IPFS cid.
     */
    function _approveAmendment(bytes32 _cid, bytes32 _termsCid, bytes32 _key) internal {
        contractVersionApprovals[_key] = true;
        contractVersions[_cid] = Amendment({ cid: _termsCid, timestamp: block.timestamp });
        emit ApprovedContractVersion(_cid, _termsCid, _key);
    }

    /**
     * @dev Proposals are saved in a temporary dictionary until they are approved to contractVersions mapping.
     *
     * It's possible to override unapproved settlement proposal with a new one.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone to amend.
     * @param _settlementParams Settlement data, see signAndProposeMilestoneSettlement.
     * @param _party1 Address of first party (e.g. payer).
     * @param _party2 Address of second party (e.g. payee).
     * @return key for settlement.
     */
    function _proposeMilestoneSettlement(
        bytes32 _cid,
        uint16 _index,
        SettlementParams memory _settlementParams,
        address _party1,
        address _party2
    ) internal returns (bytes32) {
        uint8 _revision = milestones[EscrowUtilsLib.genMid(_cid, _index)].revision + 1;
        bytes32 _key = EscrowUtilsLib.genSettlementKey(_cid, _index, _revision);

        address _validator = _party1;
        if (msg.sender == _party1) _validator = _party2;
        settlementProposals[_key] = SettlementProposal({
            params: _settlementParams,
            validator: _validator,
            timestamp: block.timestamp
        });
        emit NewSettlement(
            _cid,
            _index,
            _revision,
            _validator,
            _key,
            _settlementParams
        );
        return _key;
    }

    /**
     * @dev Save new approved contract version.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone index.
     * @param _revision Current version of milestone extended terms.
     */
    function _approveAndExecuteMilestoneSettlement(bytes32 _cid, uint16 _index, uint8 _revision) internal {
        bytes32 _key = EscrowUtilsLib.genSettlementKey(_cid, _index, _revision);
        SettlementProposal memory _sp = settlementProposals[_key];
        bytes32 _mid = EscrowUtilsLib.genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        require(_revision > _m.revision, ERROR_EARLIER_AMENDMENT);

        uint _leftAmount = _m.fundedAmount - _m.claimedAmount;
        if (_sp.params.amount < _leftAmount) {
            uint _overfundedAmount = _leftAmount - _sp.params.amount;
            require(_sp.params.refundedAmount + _sp.params.releasedAmount >= _overfundedAmount, ERROR_OVERFUNDED);
        }

        // Maybe approve new milestone terms
        if (_sp.params.termsCid != EMPTY_BYTES32) {
            require(_sp.timestamp > contractVersions[_cid].timestamp, ERROR_EARLIER_AMENDMENT);
            bytes32 _termsKey = EscrowUtilsLib.genTermsKey(_cid, _sp.params.termsCid);
            // Can be double approval, but will override the current contract version
            _approveAmendment(_cid, _sp.params.termsCid, _termsKey);
        }

        milestones[_mid].revision += 1;
        milestones[_mid].amount = _sp.params.amount;

        if (_sp.params.refundedAmount != _m.refundedAmount) {
            milestones[_mid].refundedAmount = _sp.params.refundedAmount;
        }
        if (_sp.params.releasedAmount != _m.releasedAmount) {
            milestones[_mid].releasedAmount = _sp.params.releasedAmount;
        }

        if (_sp.params.payeeAccount != EMPTY_ADDRESS) milestones[_mid].payeeAccount = _sp.params.payeeAccount;
        if (_sp.params.refundAccount != EMPTY_ADDRESS) milestones[_mid].refundAccount = _sp.params.refundAccount;
        if (_sp.params.escrowDisputeManager != EMPTY_ADDRESS) milestones[_mid].escrowDisputeManager = IEscrowDisputeManager(_sp.params.escrowDisputeManager);
        if (_sp.params.autoReleasedAt != _m.autoReleasedAt) milestones[_mid].autoReleasedAt = _sp.params.autoReleasedAt;

        emit ApprovedSettlement(_cid, _index, _revision, _key, msg.sender);
    }
}
