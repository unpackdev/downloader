// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

import "./WithMilestones.sol";
import "./EIP712.sol";

abstract contract WithPreSignedMilestones is WithMilestones {
    using EIP712 for address;

    string private constant ERROR_INVALID_SIGNATURE = "Invalid signature";
    string private constant ERROR_RELEASED = "Invalid release amount";

    /// @dev Value returned by a call to `_isPreApprovedMilestoneRelease` if the check
    /// was successful. The value is defined as:
    /// bytes4(keccak256("_isPreApprovedMilestoneRelease(bytes32,uint16,uint256,address,bytes32,bytes)"))
    bytes4 private constant MAGICVALUE = 0x8a9db909;
    /// bytes4(keccak256("_isSignedContractTerms(bytes32,bytes32,address,bytes32,bytes)"))
    bytes4 private constant SIGNED_CONTRACT_MAGICVALUE = 0xda041b1b;

    /// @dev The EIP-712 domain type hash used for computing the domain
    /// separator.
    /// keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 internal constant MILESTONE_DOMAIN_TYPE_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev The EIP-712 domain name used for computing the domain separator.
    /// keccak256("ReleasedMilestone");
    bytes32 internal constant MILESTONE_RELEASE_DOMAIN_NAME = 0xf7a7a250652776e79083ebf7548d7f678c46dd027033d24129ec9e00e571ea9b;
    /// keccak256("RefundedMilestone");
    bytes32 internal constant MILESTONE_REFUND_DOMAIN_NAME = 0x5dac513728b4cea6b6904b8f3b5f9c178f0cf83a3ecf4e94ad498e7cc75192ec;
    /// keccak256("SignedContract");
    bytes32 internal constant SIGNED_CONTRACT_DOMAIN_NAME = 0x288d28d1a9a71cba45c3234f023dd66e1f027ac6e031e2d93e302aea3277fb64;

    /// @dev The EIP-712 domain version used for computing the domain separator.
    /// keccak256("v1");
    bytes32 internal constant DOMAIN_VERSION = 0x0984d5efd47d99151ae1be065a709e56c602102f24c1abc4008eb3f815a8d217;

    /// @dev The domain separator used for signing orders that gets mixed in
    /// making signatures for different domains incompatible. This domain
    /// separator is computed following the EIP-712 standard and has replay
    /// protection mixed in so that signed orders are only valid for specific
    /// contracts.
    bytes32 public immutable MILESTONE_RELEASE_DOMAIN_SEPARATOR;
    bytes32 public immutable MILESTONE_REFUND_DOMAIN_SEPARATOR;
    bytes32 public immutable SIGNED_CONTRACT_DOMAIN_SEPARATOR;

    // solhint-ignore-contructors
    constructor() {
        // NOTE: Currently, the only way to get the chain ID in solidity is
        // using assembly.
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        MILESTONE_RELEASE_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                MILESTONE_DOMAIN_TYPE_HASH,
                MILESTONE_RELEASE_DOMAIN_NAME,
                DOMAIN_VERSION,
                chainId,
                address(this)
            )
        );

        MILESTONE_REFUND_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                MILESTONE_DOMAIN_TYPE_HASH,
                MILESTONE_REFUND_DOMAIN_NAME,
                DOMAIN_VERSION,
                chainId,
                address(this)
            )
        );

        SIGNED_CONTRACT_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                MILESTONE_DOMAIN_TYPE_HASH,
                SIGNED_CONTRACT_DOMAIN_NAME,
                DOMAIN_VERSION,
                chainId,
                address(this)
            )
        );
    }

    /**
     * @dev Get domain separator in scope of EIP-712.
     *
     * @return EIP-712 domain.
     */
    function getMilestoneReleaseDomainSeparator() public virtual view returns(bytes32) {
        return MILESTONE_RELEASE_DOMAIN_SEPARATOR;
    }

    /**
     * @dev Get domain separator in scope of EIP-712.
     *
     * @return EIP-712 domain.
     */
    function getMilestoneRefundDomainSeparator() public virtual view returns(bytes32) {
        return MILESTONE_REFUND_DOMAIN_SEPARATOR;
    }

    /**
     * @dev Get domain separator in scope of EIP-712.
     *
     * @return EIP-712 domain.
     */
    function getSignedContractDomainSeparator() public virtual view returns(bytes32) {
        return SIGNED_CONTRACT_DOMAIN_SEPARATOR;
    }

    /**
     * @dev Withdraw payment token amount released by payer.
     *
     * Works only for the full milestone amount,
     * partial withdrawals with off-chain signatures are currently not supported.
     *
     * Can be called by anyone, as recipient is static,
     * can be potenatially used to sponsor gas fees by payer.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _amount Amount to withdraw.
     * @param _payerDelegateSignature Signed digest for release of amount.
     */
    function withdrawPreApprovedMilestone(
        bytes32 _cid,
        uint16 _index,
        uint _amount,
        bytes calldata _payerDelegateSignature
    ) public nonReentrant {
        address _payerDelegate = contracts[_cid].payerDelegate;
        bytes32 _mid = EscrowUtilsLib.genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        require(_m.amount == _amount, ERROR_RELEASED);
        require(_amount > 0 && _m.fundedAmount >= _m.claimedAmount + _amount, ERROR_RELEASED);
        require(_isPreApprovedMilestoneRelease(
            _cid,
            _index,
            _amount,
            _payerDelegate,
            getMilestoneReleaseDomainSeparator(),
            _payerDelegateSignature
        ) == MAGICVALUE, ERROR_INVALID_SIGNATURE);
        
        _m.releasedAmount += _amount;
        _releaseMilestone(_mid, _m.releasedAmount, _amount, _payerDelegate);

        milestones[_mid].releasedAmount = 0;
        uint _withdrawn = _withdrawMilestone(_cid, _mid, _m, _m.payeeAccount, _m.releasedAmount);
        emit WithdrawnMilestone(_mid, _m.payeeAccount, _withdrawn); 
    }

    /**
     * @dev Withdraw payment token amount refunded by payee.
     *
     * Works only for the full milestone amount,
     * partial withdrawals with off-chain signatures are currently not supported.
     *
     * Can be called by anyone, as recipient is static,
     * can be potenatially used to sponsor gas fees by payer.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _amount Amount to refund.
     * @param _payeeDelegateSignature Signed digest for release of amount.
     */
    function refundPreApprovedMilestone(
        bytes32 _cid,
        uint16 _index,
        uint _amount,
        bytes calldata _payeeDelegateSignature
    ) public nonReentrant {
        address _payeeDelegate = contracts[_cid].payeeDelegate;
        bytes32 _mid = EscrowUtilsLib.genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        require(_m.amount == _amount, ERROR_RELEASED);
        require(_amount > 0 && _m.fundedAmount >= _m.claimedAmount + _amount, ERROR_RELEASED);
        require(_isPreApprovedMilestoneRelease(
            _cid,
            _index,
            _amount,
            _payeeDelegate,
            getMilestoneRefundDomainSeparator(),
            _payeeDelegateSignature
        ) == MAGICVALUE, ERROR_INVALID_SIGNATURE);
        
        _m.refundedAmount += _amount;
        _cancelMilestone(_mid, _m.refundedAmount, _amount, _payeeDelegate);

        milestones[_mid].refundedAmount = 0;
        uint _withdrawn = _withdrawMilestone(_cid, _mid, _m, _m.refundAccount, _m.refundedAmount);
        emit RefundedMilestone(_mid, _m.refundAccount, _withdrawn);
    }

    /**
     * @dev If payee has signed contract off-chain, allow funding with payee signature as a proof
     * that he has agreed the terms.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _termsCid Contract IPFS cid signed by payee.
     * @param _amountToFund Amount to fund.
     * @param _payeeSignature Signed digest of terms cid by payee.
     * @param _payerSignature Signed digest of terms cid by payer, can be bytes32(0) if caller is payer.
     */
    function _signAndFundMilestone(
        bytes32 _cid,
        uint16 _index,
        bytes32 _termsCid,
        uint _amountToFund,
        bytes calldata _payeeSignature,
        bytes calldata _payerSignature
    ) internal {
        address _payer = contracts[_cid].payer;
        require(msg.sender == _payer || _isSignedContractTerms(
            _cid,
            _termsCid,
            _payer,
            getSignedContractDomainSeparator(),
            _payerSignature
        ) == SIGNED_CONTRACT_MAGICVALUE, ERROR_INVALID_SIGNATURE);
        require(_isSignedContractTerms(
            _cid,
            _termsCid,
            contracts[_cid].payee,
            getSignedContractDomainSeparator(),
            _payeeSignature
        ) == SIGNED_CONTRACT_MAGICVALUE, ERROR_INVALID_SIGNATURE);

        _fundMilestone(_cid, _index, _amountToFund);
    }

    /**
     * @dev Check if milestone release was pre-approved.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Index of milestone in scope of contract.
     * @param _amount Amount of payment token to release.
     * @param _validator Address of opposite party which approval is needed.
     * @param _domain EIP-712 domain.
     * @param _callData Digest of milestone data.
     * @return MAGICVALUE for success 0x00000000 for failure.
     */
    function _isPreApprovedMilestoneRelease(
        bytes32 _cid,
        uint16 _index,
        uint256 _amount,
        address _validator,
        bytes32 _domain,
        bytes calldata _callData
    ) internal pure returns (bytes4) {
        return EIP712._isValidEIP712Signature(
            _validator,
            MAGICVALUE,
            abi.encode(_domain, _cid, _index, _amount),
            _callData
        );
    }

    /**
     * @dev Check if contract terms were signed by all parties.
     *
     * @param _cid Contract's IPFS cid.
     * @param _termsCid Specific version of contract cid which was signed, can be the same as _cid
     * @param _validator Address of opposite party which approval is needed.
     * @param _domain EIP-712 domain.
     * @param _callData Digest of contract data in scope of milestone.
     * @return SIGNED_CONTRACT_MAGICVALUE for success 0x00000000 for failure.
     */
    function _isSignedContractTerms(
        bytes32 _cid,
        bytes32 _termsCid,
        address _validator,
        bytes32 _domain,
        bytes calldata _callData
    ) internal pure returns (bytes4) {
        return EIP712._isValidEIP712Signature(
            _validator,
            SIGNED_CONTRACT_MAGICVALUE,
            abi.encode(_domain, _cid, _termsCid),
            _callData
        );
    }
}