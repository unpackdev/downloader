// SPDX-License-Identifier: MIT
/* AlphaWallet 2021 - 2022 */

pragma solidity ^0.8.4;

interface IVerifyAttestation {
    function verifyTicketAttestation(bytes memory attestation) external view returns(address attestor, address ticketIssuer, address payable subject, bytes memory ticketId, bytes memory conferenceId, bool attestationValid);
    function verifyTicketAttestation(bytes memory attestation, address attestor, address ticketIssuer) external view returns(address subject, bytes memory ticketId, bytes memory conferenceId, bool attestationValid);
}
