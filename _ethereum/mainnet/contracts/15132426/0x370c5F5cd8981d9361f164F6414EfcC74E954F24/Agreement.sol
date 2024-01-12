// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SignatureVerifier.sol";

contract Agreement is Ownable {
    string public userAgreement;
    mapping(address => bool) termsAccepted;
    bool public termsActivated;
    SignatureVerifier public verifier;
    string public ownerDomain;

    event TermsActive(bool status);
    event AcceptTerms(string userAgreement, address user);

    constructor(string memory _userAgreement, address _signatureVerifier) {
        userAgreement = _userAgreement;
        verifier = SignatureVerifier(_signatureVerifier);
    }

    /// @notice activates the terms
    /// @dev this function activates the user terms
    function setTermsStatus(bool _status) external virtual onlyOwner {
        termsActivated = _status;
        emit TermsActive(_status);
    }

    /// @notice by signing this transaction, you are confirming that you have read and agreed to the terms of use at `ownerDomain`
    /// @dev this function is called by token receivers to accept the terms before token transfer. The contract stores their acceptance
    function acceptTerms() external {
        require(termsActivated, "ERC721Cedar: terms not activated");
        termsAccepted[_msgSender()] = true;
        emit AcceptTerms(userAgreement, _msgSender());
    }

    /// @notice stores terms accepted from a signed message
    /// @dev this function is for acceptors that have signed a message offchain to accept the terms. The function calls the verifier contract to valid the signature before storing acceptance.
    function storeTermsAccepted(address _acceptor, bytes calldata _signature) external virtual onlyOwner {
        require(termsActivated, "ERC721Cedar: terms not activated");
        require(verifier.verifySignature(_acceptor, _signature), "ERC721Cedar: signature cannot be verified");
        termsAccepted[_acceptor] = true;
        emit AcceptTerms(userAgreement, _acceptor);
    }

    /// @notice checks whether an account signed the terms
    /// @dev this function calls the signature verifier to check whether the terms were accepted by an EOA.
    function checkSignature(address _account, bytes calldata _signature) external view returns (bool) {
        return verifier.verifySignature(_account, _signature);
    }

    /// @notice returns true / false for whether the account owner accepted terms
    /// @dev this function returns true / false for whether the account accepted the terms.
    function getAgreementStatus(address _address) external view returns (bool sig) {
        return termsAccepted[_address];
    }

    function setOwnerDomain(string calldata _ownerDomain) external virtual onlyOwner {
        ownerDomain = _ownerDomain;
    }
}
