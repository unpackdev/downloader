// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title ProofOfHumanity proxy interface.
 * @dev See https://github.com/Proof-Of-Humanity/Proof-Of-Humanity/blob/master/contracts/ProofOfHumanity.sol
 * Proxy: https://github.com/Proof-Of-Humanity/Proof-Of-Humanity/blob/master/contracts/ProofOfHumanityProxy.sol
 * This will allow us to verify if an address is registered on Proof of Humanity.
 */
interface IProofOfHumanity {
    /**
     * @dev Return true if the submission is registered and not expired.
     * @param _submissionID The address of the submission.
     * @return Whether the submission is registered or not.
     */
    function isRegistered(address _submissionID) external view returns (bool);
}
