// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface IAgreementsNotaryV0 {
    /// @notice By signing this transaction, you are confirming that you have read and agreed to the terms of use at `termsUrl`
    function acceptTerms(string calldata _termsURI) external;

    /// @notice By signing this transaction, you are confirming that you have read and agreed to the terms of
    ///     use at the list terms Urls provided (`_termsURIs`).
    function batchAcceptTerms(string[] calldata _termsURIs) external;

    /// @notice Allows an admin to accept terms on behalf of a user
    function acceptTerms(string calldata _termsURI, address _acceptor) external;

    /// @notice Allows an admin to accept terms on behalf of a list of users for a list of terms uris
    function batchAcceptTerms(string[] calldata _termsURIs, address[] calldata _acceptors) external;

    /// @notice Allows anyone to accept terms on behalf of a user, as long as they provide a valid signature
    function acceptTerms(string calldata _termsURI, address _acceptor, bytes calldata _signature) external;

    /// @notice Allows anyone to accept terms on behalf of a list of users for a list of terms uris, as long
    //      as they provide a list withvalid signature
    function batchAcceptTerms(
        string[] calldata _termsURIs,
        address[] calldata _acceptors,
        bytes[] calldata _signatures
    ) external;

    event TermsAccepted(string termsURI, address acceptor, bytes signature);
}
