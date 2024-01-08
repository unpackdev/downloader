// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

import "./EscrowContract.sol";
import "./WithPreSignedMilestones.sol";
import "./AmendablePreSigned.sol";
import "./IEscrowDisputeManager.sol";

contract EscrowV1 is EscrowContract, AmendablePreSigned, WithPreSignedMilestones {
    using Address for address;

    string private constant ERROR_INVALID_PARTIES = "Invalid parties";
    string private constant ERROR_NOT_DISPUTER = "Not a disputer";
    string private constant ERROR_NO_MONEY = "Nothing to withdraw";
    string private constant ERROR_NOT_APPROVED = "Not signed";
    string private constant ERROR_INVALID_SETTLEMENT = "100% required";
    string private constant ERROR_DISPUTE_PARENT = "Dispute parent";

    uint256 private constant RULE_PAYEE_WON = 3;
    uint256 private constant RULE_PAYER_WON = 4;

    string private constant PAYER_EVIDENCE_LABEL = "Evidence (Payer)";
    string private constant PAYEE_EVIDENCE_LABEL = "Evidence (Payee)";

    bytes32 private constant EMPTY_BYTES32 = bytes32(0);

    /**
     * @dev Can only be a contract party, either payer (or his delegate) or payee.
     *
     * @param _cid Contract's IPFS cid.
     */
    modifier isDisputer(bytes32 _cid) {
        _isParty(_cid);
        _;
    }

    /**
     * @dev Version of Escrow which uses Aragon Court dispute interfaces.
     *
     * @param _registry Address of universal registry of all contracts.
     */
    constructor(address _registry) EscrowContract(_registry) ReentrancyGuard() {
    }

    /**
     * @dev Can only be a contract party, either payer or payee (or their delegates).
     *
     * @param _cid Contract's IPFS cid.
     */
    function _isParty(bytes32 _cid) internal view {
        require(_isPayerParty(_cid) || _isPayeeParty(_cid), ERROR_NOT_DISPUTER);
    }

    /**
     * @dev Either payer or his delegate.
     *
     * @param _cid Contract's IPFS cid.
     */
    function _isPayerParty(bytes32 _cid) internal view returns (bool) {
        return msg.sender == contracts[_cid].payerDelegate || msg.sender == contracts[_cid].payer;
    }

    /**
     * @dev Either payee or his delegate.
     *
     * @param _cid Contract's IPFS cid.
     */
    function _isPayeeParty(bytes32 _cid) internal view returns (bool) {
        return msg.sender == contracts[_cid].payeeDelegate || msg.sender == contracts[_cid].payee;
    }

    /**
     * @dev Prepare contract between parties, with initial milestones.
     * Initial milestone term cid, will be the same as contract cid.
     *
     * @param _cid Contract's IPFS cid.
     * @param _payer Party which pays for the contract or on behalf of which the funding was done.
     * @param _payerDelegate Delegate who can release or dispute contract on behalf of payer.
     * @param _payee Party which recieves the payment.
     * @param _payeeDelegate Delegate who can refund or dispute contract on behalf of payee.
     * @param _milestones Delivery amounts and payment tokens.
     */
    function registerContract(
        bytes32 _cid,
        address _payer,
        address _payerDelegate,
        address _payee,
        address _payeeDelegate,
        EscrowUtilsLib.MilestoneParams[] calldata _milestones
    ) external {
        require(_payer != _payee && _payerDelegate != _payeeDelegate, ERROR_INVALID_PARTIES);
        _registerContract(_cid, _payer, _payerDelegate, _payee, _payeeDelegate);

        bytes32 _mid;
        EscrowUtilsLib.MilestoneParams calldata _mp;
        uint16 _index;
        uint16 _oldIndex;
        uint16 _subIndex = 1;
        for (uint16 _i=0; _i<_milestones.length; _i++) {
            _mp = _milestones[_i];
            if (_mp.parentIndex > 0) {
                _oldIndex = _index;
                _index = _mp.parentIndex * MILESTONE_INDEX_BASE + _subIndex;
                _subIndex += 1;
            } else {
                _index += 1;
            }

            _mid = EscrowUtilsLib.genMid(_cid, _index);
            _registerMilestoneStorage(
                _mid,
                _mp.paymentToken,
                _mp.treasury,
                _mp.payeeAccount,
                _mp.refundAccount,
                _mp.escrowDisputeManager,
                _mp.autoReleasedAt,
                _mp.amount
            );
            emit NewMilestone(_cid, _index, _mid, _mp.paymentToken, _mp.escrowDisputeManager, _mp.autoReleasedAt, _mp.amount);
            if (_mp.parentIndex > 0) {
                emit ChildMilestone(_cid, _index, _mp.parentIndex, _mid);
                _index = _oldIndex;
            }
        }
        lastMilestoneIndex[_cid] = _index;
    }

    /**
     * @dev Add new milestone for the existing contract with amendment to contract terms.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone (100 max, higher than 100 are child milestones, calculated by the following formula: parent index * 100 + index of child).
     * @param _paymentToken Payment token for amount.
     * @param _treasury Address where the escrow funds will be stored (farming?).
     * @param _payeeAccount Address where payment should be recieved, should be the same as payee or vesting contract address.
     * @param _refundAccount Address where payment should be refunded, should be the same as payer or sponsor.
     * @param _escrowDisputeManager Smart contract which implements disputes for the escrow.
     * @param _autoReleasedAt UNIX timestamp for delivery deadline, pass 0 if none.
     * @param _amount Amount to be paid in payment token for the milestone.
     * @param _amendmentCid Should be the same as _cid if no change in contract terms are needed.
     */
    function registerMilestone(
        bytes32 _cid,
        uint16 _index,
        address _paymentToken,
        address _treasury,
        address _payeeAccount,
        address _refundAccount,
        address _escrowDisputeManager,
        uint _autoReleasedAt,
        uint _amount,
        bytes32 _amendmentCid
    ) external {
        _registerMilestone(
            _cid,
            _index,
            _paymentToken,
            _treasury,
            _payeeAccount,
            _refundAccount,
            _escrowDisputeManager,
            _autoReleasedAt,
            _amount
        );

        // One amendment can cover terms for several milestones
        if (_cid != _amendmentCid && _amendmentCid != EMPTY_BYTES32 && _amendmentCid != getLatestApprovedContractVersion(_cid)) {
            _proposeAmendment(_cid, _amendmentCid, contracts[_cid].payer, contracts[_cid].payee);
        }

        if (_index < MILESTONE_INDEX_BASE) lastMilestoneIndex[_cid] = _index;
    }

    /**
     * @dev Stop auto-release of milestone funds.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     */
    function stopMilestoneAutoRelease(bytes32 _cid, uint16 _index) external isDisputer(_cid) {
        bytes32 _mid = EscrowUtilsLib.genMid(_cid, _index);
        milestones[_mid].autoReleasedAt = 0;
    }

    /**
     * @dev Fund milestone with payment token, partial funding is possible.
     * To increase the maximum funding amount, just add a new milestone.
     *
     * Anyone can fund milestone, payment token should be approved for this contract.
     *
     * Keep in mind that specific milestone terms can be not the final contract terms.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _amountToFund amount of payment token to fund the milestone.
     */
    function fundMilestone(bytes32 _cid, uint16 _index, uint _amountToFund) external {
        require(getLatestApprovedContractVersion(_cid) != EMPTY_BYTES32, ERROR_NOT_APPROVED);
        _fundMilestone(_cid, _index, _amountToFund);
    }

    /**
     * @dev If payee has signed contract off-chain, allow funding with payee signature as a proof
     * that he has agreed the terms.
     *
     * If contract is not approved by both parties, approve the signed terms cid.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _termsCid Contract IPFS cid signed by payee.
     * @param _amountToFund Amount to fund.
     * @param _payeeSignature Signed digest of terms cid by payee.
     * @param _payerSignature Signed digest of terms cid by payer, can be bytes32(0) if caller is payer.
     */
    function signAndFundMilestone(
        bytes32 _cid,
        uint16 _index,
        bytes32 _termsCid,
        uint _amountToFund,
        bytes calldata _payeeSignature,
        bytes calldata _payerSignature
    ) external {
        _signAndFundMilestone(_cid, _index, _termsCid, _amountToFund, _payeeSignature, _payerSignature);

        if (contractVersions[_cid].cid == EMPTY_BYTES32) {
            bytes32 _key = EscrowUtilsLib.genTermsKey(_cid, _termsCid);
            _approveAmendment(_cid, _termsCid, _key);
        }
    }

    /**
     * @dev Same as signAndProposeContractVersion amendment, but pre-approved with signature of non-sender party.
     *
     * @param _cid Contract's IPFS cid.
     * @param _amendmentCid New version of contract's IPFS cid.
     * @param _payeeSignature Signed digest of amendment cid by payee, can be bytes(0) if payee is msg.sender.
     * @param _payerSignature Signed digest of amendment cid by payer, can be bytes(0) if payer is msg.sender.
     */
    function preApprovedAmendment(
        bytes32 _cid,
        bytes32 _amendmentCid,
        bytes calldata _payeeSignature,
        bytes calldata _payerSignature
    ) external {
        address _payee = contracts[_cid].payee;
        require(msg.sender == _payee || isPreApprovedAmendment(_cid, _amendmentCid, _payee, _payeeSignature), ERROR_NOT_DISPUTER);
        address _payer = contracts[_cid].payer;
        require(msg.sender == _payer || isPreApprovedAmendment(_cid, _amendmentCid, _payer, _payerSignature), ERROR_NOT_DISPUTER);
        
        bytes32 _key = EscrowUtilsLib.genTermsKey(_cid, _amendmentCid);
        _approveAmendment(_cid, _amendmentCid, _key);
    }

    /**
     * @dev Initiate a disputed settlement for a milestone and plead to Aragon Court as arbiter.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _refundedPercent Amount to refund (in percents).
     * @param _releasedPercent Amount to release (in percents).
     * @param _statement IPFS cid for statement.
     */
    function proposeSettlement(
        bytes32 _cid,
        uint16 _index,
        uint256 _refundedPercent,
        uint256 _releasedPercent,
        bytes32 _statement
    ) external {
        require(_index < MILESTONE_INDEX_BASE, ERROR_DISPUTE_PARENT);
        require(_refundedPercent + _releasedPercent == 100, ERROR_INVALID_SETTLEMENT);

        EscrowUtilsLib.Contract memory _c = contracts[_cid];
        address _plaintiff;
        if (msg.sender == _c.payeeDelegate || msg.sender == _c.payee) {
            _plaintiff = _c.payee;
        } else if (msg.sender == _c.payerDelegate || msg.sender == _c.payer) {
            _plaintiff = _c.payer;
        } else {
            revert(ERROR_NOT_DISPUTER);
        }
        
        bytes32 _mid = EscrowUtilsLib.genMid(_cid, _index);
        milestones[_mid].escrowDisputeManager.proposeSettlement(
            _cid,
            _index,
            _plaintiff,
            _c.payer,
            _c.payee,
            _refundedPercent,
            _releasedPercent,
            _statement
        );
    }

    /**
     * @dev Accept the resolution suggested by an opposite party.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     */
    function acceptSettlement(bytes32 _cid, uint16 _index) external {
        bytes32 _mid = EscrowUtilsLib.genMid(_cid, _index);
        if (_isPayerParty(_cid)) {
            milestones[_mid].escrowDisputeManager.acceptSettlement(_cid, _index, RULE_PAYEE_WON);
        } else if (_isPayeeParty(_cid)) {
            milestones[_mid].escrowDisputeManager.acceptSettlement(_cid, _index, RULE_PAYER_WON);
        } else {
            revert();
        }
    }

    /**
     * @dev When settlement proposals are gathered, send final proposals to arbiter for resolution.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _ignoreCoverage Don't try to use insurance
     */
    function disputeSettlement(bytes32 _cid, uint16 _index, bool _ignoreCoverage) external isDisputer(_cid) {
        bytes32 _termsCid = getLatestApprovedContractVersion(_cid);
        bytes32 _mid = EscrowUtilsLib.genMid(_cid, _index);
        milestones[_mid].escrowDisputeManager.disputeSettlement(
            msg.sender,
            _cid,
            _index,
            _termsCid,
            _ignoreCoverage,
            lastMilestoneIndex[_cid] > 1
        );
    }

    /**
     * @dev Apply Aragon Court decision to milestone.
     *
     * Can be called by anyone, as ruling is static.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone in dispute.
     */
    function executeSettlement(bytes32 _cid, uint16 _index) external nonReentrant {
        bytes32 _mid = EscrowUtilsLib.genMid(_cid, _index);
        uint256 _ruling;
        uint256 _refundedPercent;
        uint256 _releasedPercent;
        IEscrowDisputeManager _disputer;

        if (_index > MILESTONE_INDEX_BASE) {
            uint16 _parentIndex = _index / MILESTONE_INDEX_BASE; // Integer division will floor the result
            bytes32 _parentMid = EscrowUtilsLib.genMid(_cid, _parentIndex);
            _disputer = milestones[_parentMid].escrowDisputeManager;
            _ruling = _disputer.resolutions(_parentMid);
            require(_ruling != 0, ERROR_DISPUTE_PARENT);
            (, uint256 __refundedPercent, uint256 __releasedPercent) = _disputer.getSettlementByRuling(_parentMid, _ruling);
            _refundedPercent = __refundedPercent;
            _releasedPercent = __releasedPercent;
        } else {
            _disputer = milestones[_mid].escrowDisputeManager;
            (uint256 __ruling, uint256 __refundedPercent, uint256 __releasedPercent) = _disputer.executeSettlement(_cid, _index, _mid);
            _ruling = __ruling;
            _refundedPercent = __refundedPercent;
            _releasedPercent = __releasedPercent;
        }

        if (_ruling == RULE_PAYER_WON || _ruling == RULE_PAYEE_WON) {
            require(_refundedPercent + _releasedPercent == 100, ERROR_INVALID_SETTLEMENT);
            Milestone memory _m = milestones[_mid];
            uint _available = _m.fundedAmount - _m.claimedAmount - _m.refundedAmount - _m.releasedAmount;
            require(_available > 0, ERROR_NO_MONEY);

            uint256 _refundedAmount = _available / 100 * _refundedPercent;
            uint256 _releasedAmount = _available / 100 * _releasedPercent;

            address _arbiter = _disputer.ARBITER();
            if (_refundedAmount > 0) _cancelMilestone(_mid, _refundedAmount + _m.refundedAmount, _refundedAmount, _arbiter);
            if (_releasedAmount > 0) _releaseMilestone(_mid, _releasedAmount + _m.releasedAmount, _releasedAmount, _arbiter);
        }
    }

    /**
     * @dev Submit evidence to help dispute resolution.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _evidence Additonal evidence which should help to resolve the dispute.
     */
    function submitEvidence(bytes32 _cid, uint16 _index, bytes calldata _evidence) external {
        string memory _label;
        if (_isPayerParty(_cid)) {
            _label = PAYER_EVIDENCE_LABEL;
        } else if (_isPayeeParty(_cid)) {
            _label = PAYEE_EVIDENCE_LABEL;
        } else {
            revert(ERROR_NOT_DISPUTER);
        }

        bytes32 _mid = EscrowUtilsLib.genMid(_cid, _index);
        milestones[_mid].escrowDisputeManager.submitEvidence(msg.sender, _label, _cid, _index, _evidence);
    }

    /**
     * @dev Receives and executes a batch of function calls on this contract (taken from OZ).
     * @param data ABI encoded function calls for this contract.
     * @return results Array with execution results.
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}