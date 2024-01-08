// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@hbarcelos]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.7.6;
import "./IRealitio.sol";

/**
 *  @title IRealitioArbitrator
 *  @dev Based on https://github.com/realitio/realitio-dapp/blob/1860548a51f52eba4930baad051f811e9f7adaee/docs/arbitrators.rst
 */
interface IRealitioArbitrator {
    /** @dev Returns Realitio implementation instance.
     */
    function realitio() external view returns (IRealitio);

    /** @dev Provides a string of json-encoded metadata. The following properties are scheduled for implementation in the Reality.eth dapp:
        tos: A URI representing the location of a terms-of-service document for the arbitrator.
        template_hashes: An array of hashes of templates supported by the arbitrator. If you have a numerical ID for a template registered with Reality.eth, you can look up this hash by calling the Reality.eth template_hashes() function.
     */
    function metadata() external view returns (string calldata);

    /** @dev Returns arbitrators fee for arbitrating this question.
     */
    function getDisputeFee(bytes32 questionID) external view returns (uint256);
}
