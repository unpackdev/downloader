// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                      _'                    AAA                                                                                            //
//                    !jz_                   A:::A                                                                                           //
//                 ;Lzzzz-                  A:::::A                                                                                          //
//              '1zzzzxzz'                 A:::::::A                                                                                         //
//            !xzzzzzzi~                  A:::::::::A             ssssssssss   ppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn        //
//         ;izzzzzzj^`                   A:::::A:::::A          ss::::::::::s  p::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn      //
//              `;^.`````               A:::::A A:::::A       ss:::::::::::::s p:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn     //
//              -;;;;;;;-              A:::::A   A:::::A      s::::::ssss:::::spp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n    //
//           .;;;;;;;_                A:::::A     A:::::A      s:::::s  ssssss  p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n    //
//         ;;;;;;;;`                 A:::::AAAAAAAAA:::::A       s::::::s       p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n    //
//      _;;;;;;;'                   A:::::::::::::::::::::A         s::::::s    p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n    //
//            ;{jjjjjjjjj          A:::::AAAAAAAAAAAAA:::::A  ssssss   s:::::s  p:::::p    p::::::pe:::::::e             n::::n    n::::n    //
//         `+IIIVVVVVVVVI`        A:::::A             A:::::A s:::::ssss::::::s p:::::ppppp:::::::pe::::::::e            n::::n    n::::n    //
//       ^sIVVVVVVVVVVVVI`       A:::::A               A:::::As::::::::::::::s  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n    //
//    ~xIIIVVVVVVVVVVVVVI`      A:::::A                 A:::::As:::::::::::ss   p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n    //
//  -~~~;;;;;;;;;;;;;;;;;      AAAAAAA                   AAAAAAAsssssssssss     p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                              p:::::p                                                      //
//                                                                              p:::::p                                                      //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             ppppppppp                                                     //
//                                                                                                                                           //
//  Website: https://aspenft.io/                                                                                                             //
//  Twitter: https://twitter.com/aspenft                                                                                                     //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/// ========== External imports ==========
import "./AccessControlUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";

import "./ITermsErrors.sol";
import "./IAgreementsNotary.sol";

/// @title AgreementsNotary
/// @notice This smart contract acts as a notary for accepting terms of use. It is responsible for keeping track of
///         terms acceptance made by subscribers by emitting an event when terms for an ERC721/ERC1155 are accepted.
contract AgreementsNotary is ContextUpgradeable, AccessControlUpgradeable, EIP712Upgradeable, IAgreementsNotaryV0 {
    bytes32 public constant MESSAGE_HASH = keccak256("AgreementsNotary.AcceptTerms(address acceptor,string termsURI)");

    struct AcceptTerms {
        address acceptor;
        string termsURI;
    }

    function __AgreementsNotary_init() internal onlyInitializing {
        __AgreementsNotary_init_unchained();
    }

    function __AgreementsNotary_init_unchained() internal onlyInitializing {
        __EIP712_init("AgreementsNotary", "1.0.0");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice By signing this transaction, you are confirming that you have read and agreed to the terms of use at `termsUrl`
    function acceptTerms(string calldata _termsURI) external {
        _acceptTerms(_termsURI, _msgSender(), bytes(""));
    }

    /// @notice By signing this transaction, you are confirming that you have read and agreed to the terms of
    ///     use at the list terms Urls provided (`_termsURIs`).
    function batchAcceptTerms(string[] calldata _termsURIs) external {
        for (uint256 i = 0; i < _termsURIs.length; i++) {
            _acceptTerms(_termsURIs[i], _msgSender(), bytes(""));
        }
    }

    /// @notice Allows an admin to accept terms on behalf of a user
    function acceptTerms(string calldata _termsURI, address _acceptor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _acceptTerms(_termsURI, _acceptor, bytes(""));
    }

    /// @notice Allows an admin to accept terms on behalf of a list of users for a list of terms uris
    function batchAcceptTerms(
        string[] calldata _termsURIs,
        address[] calldata _acceptors
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_termsURIs.length != _acceptors.length) revert IAgreementsNotaryErrorsV0.BatchAcceptArrayMismatch();
        for (uint256 i = 0; i < _acceptors.length; i++) {
            _acceptTerms(_termsURIs[i], _acceptors[i], bytes(""));
        }
    }

    /// @notice Allows anyone to accept terms on behalf of a user, as long as they provide a valid signature
    function acceptTerms(string calldata _termsURI, address _acceptor, bytes calldata _signature) external {
        if (!_verifySignature(_termsURI, _acceptor, _signature))
            revert IAgreementsNotaryErrorsV0.SignatureVerificationFailed();
        _acceptTerms(_termsURI, _acceptor, _signature);
    }

    /// @notice Allows anyone to accept terms on behalf of a list of users for a list of terms uris, as long
    //      as they provide a list withvalid signature
    function batchAcceptTerms(
        string[] calldata _termsURIs,
        address[] calldata _acceptors,
        bytes[] calldata _signatures
    ) external {
        if (_termsURIs.length != _acceptors.length || _acceptors.length != _signatures.length)
            revert IAgreementsNotaryErrorsV0.BatchAcceptArrayMismatch();
        for (uint256 i = 0; i < _acceptors.length; i++) {
            if (!_verifySignature(_termsURIs[i], _acceptors[i], _signatures[i]))
                revert IAgreementsNotaryErrorsV0.SignatureVerificationFailed();
            _acceptTerms(_termsURIs[i], _acceptors[i], _signatures[i]);
        }
    }

    /// ===================================
    /// ======== Internal Methods =========
    /// ===================================

    /// @notice Emits an event that terms on specific termsUIR for a specific address and a specific signature (optional)
    ///         are accepted
    function _acceptTerms(string calldata _termsURI, address _acceptor, bytes memory _signature) internal {
        emit TermsAccepted(_termsURI, _acceptor, _signature);
    }

    /// @notice verifies a signature
    /// @dev this function takes the signers address and the signature signed with their private key.
    ///     ECDSA checks whether a hash of the message was signed by the user's private key.
    ////    If yes, the _to address == ECDSA's returned address
    function _verifySignature(
        string calldata _termsURI,
        address _acceptor,
        bytes memory _signature
    ) internal view returns (bool) {
        if (_signature.length == 0) return false;
        bytes32 hash = _hashMessage(_termsURI, _acceptor);
        address signer = ECDSAUpgradeable.recover(hash, _signature);
        return signer == _acceptor;
    }

    /// @dev This function hashes the terms url and message
    function _hashMessage(string calldata _termsURI, address _acceptor) private view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(MESSAGE_HASH, _acceptor, keccak256(bytes(_termsURI)))));
    }
}
