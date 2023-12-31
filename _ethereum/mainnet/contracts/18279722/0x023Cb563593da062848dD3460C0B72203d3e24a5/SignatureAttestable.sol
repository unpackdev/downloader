// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAttestable.sol";
import "./SignatureChecker.sol";

contract SignatureAttestable is IAttestable {
    using ECDSA for bytes32;
    using SignatureChecker for address;

    address private _signer;

    event SignerUpdated(address indexed signer);

    modifier onlyValidSignature(bytes32 hashedData, bytes calldata signature) {
        _validateSignature(hashedData, signature);
        _;
    }

    constructor(address signerAddress) {
        _setSigner(signerAddress);
    }

    function signer() public view virtual returns (address signerAddress) {
        signerAddress = _signer;
    }

    function _setSigner(address signerAddress) internal virtual {
        _signer = signerAddress;
        emit SignerUpdated(signerAddress);
    }

    function _validateSignature(
        bytes32 hashedData,
        bytes calldata signature
    ) internal view {
        if (
            !signer().isValidSignatureNow(
                hashedData.toEthSignedMessageHash(),
                signature
            )
        ) {
            revert InvalidAttestation();
        }
    }
}
