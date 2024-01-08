// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

import "./IRegistry.sol";
import "./IAragonCourt.sol";
import "./IInsurance.sol";
import "./AragonCourtMetadataLib.sol";
import "./SafeERC20.sol";

contract AragonCourtDisputerV1 {
    using SafeERC20 for IERC20;

    string private constant ERROR_NOT_VALIDATOR = "Not a validator";
    string private constant ERROR_NOT_DISPUTER = "Not a disputer";
    string private constant ERROR_IN_DISPUTE = "In dispute";
    string private constant ERROR_NOT_IN_DISPUTE = "Not in dispute";
    string private constant ERROR_NOT_READY = "Not ready for dispute";
    string private constant ERROR_ALREADY_RESOLVED = "Resolution applied";
    string private constant ERROR_INVALID_RULING = "Invalid ruling";

    IRegistry public immutable TRUSTED_REGISTRY;
    IAragonCourt public immutable ARBITER;

    uint256 public immutable SETTLEMENT_DELAY;

    uint256 private constant EMPTY_INT = 0;
    uint256 private constant RULE_LEAKED = 1;
    uint256 private constant RULE_IGNORED = 2;
    uint256 private constant RULE_PAYEE_WON = 3;
    uint256 private constant RULE_PAYER_WON = 4;

    string private constant PAYER_STATEMENT_LABEL = "Statement (Payer)";
    string private constant PAYEE_STATEMENT_LABEL = "Statement (Payee)";

    bytes32 private constant EMPTY_BYTES32 = bytes32(0);

    using AragonCourtMetadataLib for AragonCourtMetadataLib.EnforceableSettlement;

    mapping (bytes32 => uint256) public resolutions;
    mapping (bytes32 => AragonCourtMetadataLib.EnforceableSettlement) public enforceableSettlements;

    event UsedInsurance(
        bytes32 indexed cid,
        uint16 indexed index,
        address indexed feeToken,
        uint256 covered,
        uint256 notCovered
    );

    event SettlementProposed(
        bytes32 indexed cid,
        uint16 indexed index,
        address indexed plaintiff,
        uint256 refundedPercent,
        uint256 releasedPercent,
        uint256 fillingStartsAt,
        bytes32 statement
    );

    event DisputeStarted(
        bytes32 indexed cid,
        uint16 indexed index,
        address indexed plaintiff,
        uint256 did,
        bool ignoreCoverage
    );

    event DisputeWitnessed(
        bytes32 indexed cid,
        uint16 indexed index,
        address indexed witness,
        uint256 did,
        bytes evidence
    );

    event DisputeConcluded(
        bytes32 indexed cid,
        uint16 indexed index,
        uint256 indexed rule,
        uint256 did
    );

    /**
     * @dev Can only be an escrow contract registered in Greet registry.
     */
    modifier isEscrow() {
        require(TRUSTED_REGISTRY.escrowContracts(msg.sender), ERROR_NOT_DISPUTER);
        _;
    }

    /**
     * @dev Dispute manager for Aragon Court.
     *
     * @param _registry Address of universal registry of all contracts.
     * @param _arbiter Address of Aragon Court subjective oracle.
     * @param _settlementDelay Seconds for second party to customise dispute proposal.
     */
    constructor(address _registry, address _arbiter, uint256 _settlementDelay) {
        TRUSTED_REGISTRY = IRegistry(_registry);
        ARBITER = IAragonCourt(_arbiter);
        SETTLEMENT_DELAY = _settlementDelay;
    }

    /**
     * @dev Can only be an escrow contract which initiated settlement.
     *
     * @param _mid Milestone index.
     */
    function _requireDisputedEscrow(bytes32 _mid) internal view {
        require(msg.sender == enforceableSettlements[_mid].escrowContract, ERROR_NOT_VALIDATOR);
    }

    /**
     * @dev Checks if milestone has ongoing settlement dispute.
     *
     * @param _mid Milestone uid.
     * @return true if there is ongoing settlement process.
     */
    function hasSettlementDispute(bytes32 _mid) public view returns (bool) {
        return enforceableSettlements[_mid].fillingStartsAt > 0;
    }

    /**
     * @dev Checks if milestone has ongoing settlement dispute.
     *
     * @param _mid Milestone uid.
     * @param _ruling Aragon Court dispute resolution.
     * @return ruling, refunded percent, released percent.
     */
    function getSettlementByRuling(bytes32 _mid, uint256 _ruling) public view returns (uint256, uint256, uint256) {
        if (_ruling == RULE_PAYEE_WON) {
            AragonCourtMetadataLib.Claim memory _claim = enforceableSettlements[_mid].payeeClaim;
            return (_ruling, _claim.refundedPercent, _claim.releasedPercent);
        } else if (_ruling == RULE_PAYER_WON) {
            AragonCourtMetadataLib.Claim memory _claim = enforceableSettlements[_mid].payerClaim;
            return (_ruling, _claim.refundedPercent, _claim.releasedPercent);
        } else {
            return (_ruling, 0, 0);
        }
    }

    /**
     * @dev Propose settlement enforceable in court.
     * We automatically fill the best outcome for opponent's proposal,
     * he has 1 week time to propose alternative distribution which he considers fair.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone to amend.
     * @param _plaintiff Payer or Payee address who sends settlement for enforcement.
     * @param _payer Payer address.
     * @param _payee Payee address.
     * @param _refundedPercent Amount to refund (in percents).
     * @param _releasedPercent Amount to release (in percents).
     * @param _statement IPFS cid for statement.
     */
    function proposeSettlement(
        bytes32 _cid,
        uint16 _index,
        address _plaintiff,
        address _payer,
        address _payee,
        uint _refundedPercent,
        uint _releasedPercent,
        bytes32 _statement
    ) external isEscrow {
        bytes32 _mid = _genMid(_cid, _index);
        require(enforceableSettlements[_mid].did == EMPTY_INT, ERROR_IN_DISPUTE);
        uint256 _resolution = resolutions[_mid];
        require(_resolution != RULE_PAYEE_WON && _resolution != RULE_PAYER_WON, ERROR_ALREADY_RESOLVED);

        AragonCourtMetadataLib.Claim memory _proposal = AragonCourtMetadataLib.Claim({
            refundedPercent: _refundedPercent,
            releasedPercent: _releasedPercent,
            statement: _statement
        });

        uint256 _fillingStartsAt = enforceableSettlements[_mid].fillingStartsAt; 
        if (_plaintiff == _payer) {
            enforceableSettlements[_mid].payerClaim = _proposal;
            if (_fillingStartsAt == 0) {
                _fillingStartsAt = block.timestamp + SETTLEMENT_DELAY;
                enforceableSettlements[_mid].fillingStartsAt = _fillingStartsAt;
                enforceableSettlements[_mid].payeeClaim = AragonCourtMetadataLib.defaultPayeeClaim();
                enforceableSettlements[_mid].escrowContract = msg.sender;
            }
        } else if (_plaintiff == _payee) {
            enforceableSettlements[_mid].payeeClaim = _proposal;
            if (_fillingStartsAt == 0) {
                _fillingStartsAt = block.timestamp + SETTLEMENT_DELAY;
                enforceableSettlements[_mid].fillingStartsAt = _fillingStartsAt;
                enforceableSettlements[_mid].payerClaim = AragonCourtMetadataLib.defaultPayerClaim();
                enforceableSettlements[_mid].escrowContract = msg.sender;
            }
        } else {
            revert();
        }
        emit SettlementProposed(_cid, _index, _plaintiff, _refundedPercent, _releasedPercent, _fillingStartsAt, _statement);
    }

    /**
     * @dev Payee accepts Payer settlement without going to Aragon court.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone challenged.
     */
    function acceptSettlement(
        bytes32 _cid,
        uint16 _index,
        uint256 _ruling
    ) external {
        bytes32 _mid = _genMid(_cid, _index);
        _requireDisputedEscrow(_mid);
        require(_ruling == RULE_PAYER_WON || _ruling == RULE_PAYEE_WON, ERROR_INVALID_RULING);
        resolutions[_mid] = _ruling;
        emit DisputeConcluded(_cid, _index, _ruling, 0);
    }

    /**
     * @dev Send collected proposals for settlement to Aragon Court as arbiter.
     *
     * @param _feePayer Address which will pay a dispute fee (should approve this contract).
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone to amend.
     * @param _termsCid Latest approved contract's IPFS cid.
     * @param _ignoreCoverage Don't try to use insurance.
     * @param _multiMilestone More than one milestone in contract?
     */
    function disputeSettlement(
        address _feePayer,
        bytes32 _cid,
        uint16 _index,
        bytes32 _termsCid,
        bool _ignoreCoverage,
        bool _multiMilestone
    ) external returns (uint256) {
        bytes32 _mid = _genMid(_cid, _index);
        _requireDisputedEscrow(_mid);
        require(enforceableSettlements[_mid].did == EMPTY_INT, ERROR_IN_DISPUTE);
        uint256 _fillingStartsAt = enforceableSettlements[_mid].fillingStartsAt;
        require(_fillingStartsAt > 0 && _fillingStartsAt < block.timestamp, ERROR_NOT_READY);
        uint256 _resolution = resolutions[_mid];
        require(_resolution != RULE_PAYEE_WON && _resolution != RULE_PAYER_WON, ERROR_ALREADY_RESOLVED);

        _payDisputeFees(_feePayer, _cid, _index, _ignoreCoverage);

        AragonCourtMetadataLib.EnforceableSettlement memory _enforceableSettlement = enforceableSettlements[_mid];
        bytes memory _metadata = _enforceableSettlement.generatePayload(_termsCid, _feePayer, _index, _multiMilestone);
        uint256 _did = ARBITER.createDispute(2, _metadata);
        enforceableSettlements[_mid].did = _did;


        bytes32 __payerStatement = enforceableSettlements[_mid].payerClaim.statement;
        if (__payerStatement != EMPTY_BYTES32) {
            bytes memory _payerStatement = AragonCourtMetadataLib.toIpfsCid(__payerStatement);
            ARBITER.submitEvidence(_did, address(this), abi.encode(_payerStatement, PAYER_STATEMENT_LABEL));
        }

        bytes32 __payeeStatement = enforceableSettlements[_mid].payeeClaim.statement;
        if (__payeeStatement != EMPTY_BYTES32) {
            bytes memory _payeeStatement = AragonCourtMetadataLib.toIpfsCid(__payeeStatement);
            ARBITER.submitEvidence(_did, address(this), abi.encode(_payeeStatement, PAYEE_STATEMENT_LABEL));
        }

        emit DisputeStarted(_cid, _index, _feePayer, _did, _ignoreCoverage);
        return _did;
    }

    /**
     * @dev Execute settlement favored by Aragon Court as arbiter.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _mid Milestone key.
     * @return Ruling, refundedPercent, releasedPercent
     */
    function executeSettlement(bytes32 _cid, uint16 _index, bytes32 _mid) public returns(uint256, uint256, uint256) {
        uint256 _ruling = ruleDispute(_cid, _index, _mid);
        return getSettlementByRuling(_mid, _ruling);
    }

    /**
     * @dev Submit evidence to help dispute resolution.
     *
     * @param _from Address which submits evidence.
     * @param _label Label for address.
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _evidence Additonal evidence which should help to resolve the dispute.
     */
    function submitEvidence(address _from, string memory _label, bytes32 _cid, uint16 _index, bytes calldata _evidence) external isEscrow {
        bytes32 _mid = _genMid(_cid, _index);
        uint256 _did = enforceableSettlements[_mid].did;
        require(_did != EMPTY_INT, ERROR_NOT_IN_DISPUTE);
        ARBITER.submitEvidence(_did, _from, abi.encode(_evidence, _label));
        emit DisputeWitnessed(_cid, _index, _from, _did, _evidence);
    }

    /**
     * @dev Apply Aragon Court descision to milestone.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _mid Milestone key.
     * @return ruling of Aragon Court.
     */
    function ruleDispute(bytes32 _cid, uint16 _index, bytes32 _mid) public returns(uint256) {
        _requireDisputedEscrow(_mid);
        uint256 _resolved = resolutions[_mid];
        if (_resolved != EMPTY_INT && _resolved != RULE_IGNORED && _resolved != RULE_LEAKED) return _resolved;

        uint256 _did = enforceableSettlements[_mid].did;
        require(_did != EMPTY_INT || enforceableSettlements[_mid].did != EMPTY_INT, ERROR_NOT_IN_DISPUTE);

        (, uint256 _ruling) = ARBITER.rule(_did);
        resolutions[_mid] = _ruling;
        if (_ruling == RULE_IGNORED || _ruling == RULE_LEAKED) {
            // Allow to send the same case again after SETTLEMENT_DELAY period
            enforceableSettlements[_mid].fillingStartsAt = block.timestamp + SETTLEMENT_DELAY;
            delete enforceableSettlements[_mid].did;
        } else {
            if (_ruling != RULE_PAYER_WON && _ruling != RULE_PAYEE_WON) revert();
        }
        
        emit DisputeConcluded(_cid, _index, _ruling, _did);
        return _ruling;
    }

    /**
     * @dev Charge standard fees for dispute
     *
     * @param _feePayer Address which will pay a dispute fee (should approve this contract).
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _ignoreCoverage Don't try to use insurance
     */
    function _payDisputeFees(address _feePayer, bytes32 _cid, uint16 _index, bool _ignoreCoverage) private {
        (address _recipient, IERC20 _feeToken, uint256 _feeAmount) = ARBITER.getDisputeFees();
        if (!_ignoreCoverage) {
            IInsurance _insuranceManager = IInsurance(TRUSTED_REGISTRY.insuranceManager());
            (uint256 _notCovered, uint256 _covered) = _insuranceManager.getCoverage(_cid, address(_feeToken), _feeAmount);
            if (_notCovered > 0) _feeToken.safeTransferFrom(_feePayer, address(this), _notCovered);
            if (_covered > 0) require(_insuranceManager.useCoverage(_cid, address(_feeToken), _covered));
            emit UsedInsurance(_cid, _index, address(_feeToken), _covered, _notCovered);
        } else {
            _feeToken.safeTransferFrom(_feePayer, address(this), _feeAmount);
        }
        _feeToken.safeApprove(_recipient, _feeAmount);
    }

    /**
     * @dev Generate bytes32 uid for contract's milestone.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone (255 max).
     * @return milestone id (mid).
     */
    function _genMid(bytes32 _cid, uint16 _index) public pure returns(bytes32) {
        return keccak256(abi.encode(_cid, _index));
    }
} 