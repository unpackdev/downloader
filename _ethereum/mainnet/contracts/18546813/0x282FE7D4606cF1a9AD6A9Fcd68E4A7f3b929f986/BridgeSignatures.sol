// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ECDSA.sol";
import "./draft-EIP712.sol";

import "./BridgeRoles.sol";

abstract contract BridgeSignatures is EIP712, BridgeRoles {
    struct SignatureWithDeadline {
        uint256 deadline;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    enum SigInvalidReason {
        None,
        Deadline,
        Recover,
        Signer
    }

    event InvalidSigDetected(uint256 id, SigInvalidReason reason);

    constructor(string memory name, string memory version) EIP712(name, version) {}

    /**
     * @dev Check sigantures for the bridge contract.
     * @param sigs The signatures of the backend signers.
     */
    function _checkSignatures(bytes32[] memory structHashes, SignatureWithDeadline[] memory sigs) internal {
        uint256 _requiredSignatures = requiredSignatures();

        // Check if the amount of signatures is enough (>= requiredSignatures)
        require(sigs.length >= _requiredSignatures, "Bridge: Not enough signatures");
        require(sigs.length <= signerCount, "Bridge: Too many signatures");

        // Instead of checking the signatures one by one, we check the amount of incorrect signatures.
        // In this way, we can save some gas if the signatures are incorrect.

        uint256 possibleIncorrectSignatures = sigs.length - _requiredSignatures;
        uint256 incorrectSignatures = 0;
        uint256 correctSignatures = 0;

        // This variable is used to check for unique signatures.
        // Check https://github.com/balancer-labs/balancer-v2-monorepo/blob/537076996a93d654b19e2074f1bd952b70fbfcd0/pkg/vault/contracts/FlashLoans.sol#L50 for more info.
        address _uniqueSigner = address(0);

        for (uint256 i = 0; i < sigs.length; i++) {
            SignatureWithDeadline memory info = sigs[i];

            // Check if the deadline has passed, if the signature is valid and if the signer has the claim signer role.

            bool validDeadline = _checkDeadline(info.deadline);

            if (!validDeadline) {
                incorrectSignatures++;
                emit InvalidSigDetected(i, SigInvalidReason.Deadline);
                _requireCorrectSigsAmount(incorrectSignatures, possibleIncorrectSignatures);
                continue;
            }

            address signer = _getSignerAddress(structHashes[i], sigs[i]);

            if (signer == address(0)) {
                incorrectSignatures++;
                emit InvalidSigDetected(i, SigInvalidReason.Recover);
                _requireCorrectSigsAmount(incorrectSignatures, possibleIncorrectSignatures);
                continue;
            }

            bool signerIsCorrect = hasSignerRole(signer);

            if (!signerIsCorrect) {
                incorrectSignatures++;
                emit InvalidSigDetected(i, SigInvalidReason.Signer);
                _requireCorrectSigsAmount(incorrectSignatures, possibleIncorrectSignatures);
                continue;
            }

            // Used to check for unique signatures.
            require(signer > _uniqueSigner, "Bridge: Signatures must be unique");

            _uniqueSigner = signer;
            correctSignatures++;
            if (correctSignatures == _requiredSignatures) {
                break;
            }
        }
    }

    function _requireCorrectSigsAmount(uint256 incorrectSignatures, uint256 possibleIncorrectSignatures) internal pure {
        require(incorrectSignatures <= possibleIncorrectSignatures, "Bridge: Too many incorrect signatures");
    }

    /**
     * @dev Checks if the deadline has passed.
     * @param deadline The deadline to check.
     */
    function _checkDeadline(uint256 deadline) internal view returns (bool) {
        return deadline >= block.timestamp;
    }

    /**
     * @dev Get signer address using ECDSA
     * @param digest Typed data hash
     * @param sig Signature provided for the hash
     */
    function _getSignerAddress(bytes32 digest, SignatureWithDeadline memory sig) internal pure returns (address) {
        (address signer, ) = ECDSA.tryRecover(digest, sig.v, sig.r, sig.s);

        return signer;
    }

    /**
     * @dev Required amount of signers is calculated as follows:
     *  0 -> Reverts
        1 -> 1
        2 -> 2
        3 -> 3
        4 -> 3
        5 -> 4
        6 -> 5
        7 -> 5
        ...
        14 -> 10
        15 -> 11
        ...
     */
    function requiredSignatures() public view returns (uint256) {
        uint256 totalSigners = signerCount;

        return (totalSigners * 2) / 3 + 1;
    }
}
