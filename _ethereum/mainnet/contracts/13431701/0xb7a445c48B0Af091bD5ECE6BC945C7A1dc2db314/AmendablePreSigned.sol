// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

import "./Amendable.sol";
import "./EIP712.sol";

abstract contract AmendablePreSigned is Amendable {
    using EIP712 for address;

    /// @dev Value returned by a call to `_isPreApprovedAmendment` if the check
    /// was successful. The value is defined as:
    /// bytes4(keccak256("_isPreApprovedAmendment(address,bytes)"))
    bytes4 private constant MAGICVALUE = 0xe3f756de;

    /// @dev The EIP-712 domain type hash used for computing the domain
    /// separator.
    bytes32 internal constant AMENDMENT_DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @dev The EIP-712 domain name used for computing the domain separator.
    bytes32 internal constant AMENDMENT_DOMAIN_NAME = keccak256("ApprovedAmendment");

    /// @dev The EIP-712 domain version used for computing the domain separator.
    bytes32 internal constant AMENDMENT_DOMAIN_VERSION = keccak256("v1");

    /// @dev The domain separator used for signing orders that gets mixed in
    /// making signatures for different domains incompatible. This domain
    /// separator is computed following the EIP-712 standard and has replay
    /// protection mixed in so that signed orders are only valid for specific
    /// contracts.
    bytes32 public immutable AMENDMENT_DOMAIN_SEPARATOR;

    constructor() {
        // NOTE: Currently, the only way to get the chain ID in solidity is
        // using assembly.
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        AMENDMENT_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                AMENDMENT_DOMAIN_TYPE_HASH,
                AMENDMENT_DOMAIN_NAME,
                AMENDMENT_DOMAIN_VERSION,
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
    function getAmendmentDomainSeparator() public virtual view returns(bytes32) {
        return AMENDMENT_DOMAIN_SEPARATOR;
    }

    /**
     * @dev Check if amendment was pre-approved.
     *
     * @param _cid Contract's IPFS cid.
     * @param _amendmentCid New version of contract's IPFS cid.
     * @param _validator Address of opposite party which approval is needed.
     * @param _signature Digest of amendment cid.
     * @return true or false.
     */
    function isPreApprovedAmendment(
        bytes32 _cid,
        bytes32 _amendmentCid,
        address _validator,
        bytes calldata _signature
    ) internal view returns (bool) {
        bytes32 _currentCid = getLatestApprovedContractVersion(_cid);
        return _isPreApprovedAmendment(
            _cid,
            _currentCid,
            _amendmentCid,
            _validator,
            getAmendmentDomainSeparator(),
            _signature
        ) == MAGICVALUE;
    }

    /**
     * @dev Check if amendment was pre-approved, EIP-712
     *
     * @param _cid Contract's IPFS cid.
     * @param _currentCid Cid of last proposed contract version.
     * @param _amendmentCid New version of contract's IPFS cid.
     * @param _validator Address of opposite party which approval is needed.
     * @param _domain EIP-712 domain.
     * @param _callData Digest of amendment cid.
     * @return 0xe3f756de for success 0x00000000 for failure.
     */
    function _isPreApprovedAmendment(
        bytes32 _cid,
        bytes32 _currentCid,
        bytes32 _amendmentCid,
        address _validator,
        bytes32 _domain,
        bytes calldata _callData
    ) internal pure returns (bytes4) {
        return EIP712._isValidEIP712Signature(
            _validator,
            MAGICVALUE,
            abi.encode(_domain, _cid, _currentCid, _amendmentCid),
            _callData
        );
    }
}
