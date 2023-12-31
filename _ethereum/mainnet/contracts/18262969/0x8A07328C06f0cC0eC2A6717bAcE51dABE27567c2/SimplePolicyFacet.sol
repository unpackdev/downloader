// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Modifiers.sol";
import "./AppStorage.sol";
import "./LibObject.sol";
import "./LibHelpers.sol";
import "./LibSimplePolicy.sol";
import "./LibFeeRouter.sol";
import "./ISimplePolicyFacet.sol";
import "./LibConstants.sol";
import "./LibAdmin.sol";

/**
 * @title Simple Policies
 * @notice Facet for working with Simple Policies
 * @dev Simple Policy facet
 */
contract SimplePolicyFacet is ISimplePolicyFacet, Modifiers {
    /**
     * @dev Pay a premium of `_amount` on simple policy
     * @param _policyId Id of the simple policy
     * @param _amount Amount of the premium
     */
    function paySimplePremium(bytes32 _policyId, uint256 _amount) external notLocked(msg.sig) assertPrivilege(_policyId, LC.GROUP_PAY_SIMPLE_PREMIUM) {
        bytes32 senderId = LibHelpers._getIdForAddress(msg.sender);
        bytes32 payerEntityId = LibObject._getParent(senderId);

        LibSimplePolicy._payPremium(payerEntityId, _policyId, _amount);
    }

    /**
     * @dev Pay a claim of `_amount` for simple policy
     * @param _claimId Id of the simple policy claim
     * @param _policyId Id of the simple policy
     * @param _insuredId Id of the insured party
     * @param _amount Amount of the claim
     */
    function paySimpleClaim(
        bytes32 _claimId,
        bytes32 _policyId,
        bytes32 _insuredId,
        uint256 _amount
    ) external notLocked(msg.sig) assertPrivilege(LibObject._getParentFromAddress(msg.sender), LC.GROUP_PAY_SIMPLE_CLAIM) {
        LibSimplePolicy._payClaim(_claimId, _policyId, _insuredId, _amount);
    }

    /**
     * @dev Get simple policy info
     * @param _policyId Id of the simple policy
     * @return Simple policy metadata
     */
    function getSimplePolicyInfo(bytes32 _policyId) external view returns (SimplePolicyInfo memory) {
        return
            SimplePolicyInfo({
                startDate: LibSimplePolicy._getSimplePolicyInfo(_policyId).startDate,
                maturationDate: LibSimplePolicy._getSimplePolicyInfo(_policyId).maturationDate,
                asset: LibSimplePolicy._getSimplePolicyInfo(_policyId).asset,
                limit: LibSimplePolicy._getSimplePolicyInfo(_policyId).limit,
                fundsLocked: LibSimplePolicy._getSimplePolicyInfo(_policyId).fundsLocked,
                cancelled: LibSimplePolicy._getSimplePolicyInfo(_policyId).cancelled,
                claimsPaid: LibSimplePolicy._getSimplePolicyInfo(_policyId).claimsPaid,
                premiumsPaid: LibSimplePolicy._getSimplePolicyInfo(_policyId).premiumsPaid
            });
    }

    /**
     * @dev Get the list of commission receivers
     * @param _id Id of the simple policy
     * @return commissionReceivers
     */
    function getPolicyCommissionReceivers(bytes32 _id) external view returns (bytes32[] memory commissionReceivers) {
        return LibSimplePolicy._getSimplePolicyInfo(_id).commissionReceivers;
    }

    /**
     * @dev Check and update simple policy state
     * @param _policyId Id of the simple policy
     */
    function checkAndUpdateSimplePolicyState(bytes32 _policyId) external notLocked(msg.sig) {
        LibSimplePolicy._checkAndUpdateState(_policyId);
    }

    /**
     * @dev Cancel a simple policy
     * @param _policyId Id of the simple policy
     */
    function cancelSimplePolicy(bytes32 _policyId) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_UNDERWRITERS) {
        LibSimplePolicy._cancel(_policyId);
    }

    /**
     * @dev Generate a simple policy hash for singing by the stakeholders
     * @param _startDate Date when policy becomes active
     * @param _maturationDate Date after which policy becomes matured
     * @param _asset ID of the underlying asset, used as collateral and to pay out claims
     * @param _limit Policy coverage limit
     * @param _offchainDataHash Hash of all the important policy data stored offchain
     * @return signingHash_ hash for signing
     */
    function getSigningHash(
        uint256 _startDate,
        uint256 _maturationDate,
        bytes32 _asset,
        uint256 _limit,
        bytes32 _offchainDataHash
    ) external view returns (bytes32 signingHash_) {
        signingHash_ = LibSimplePolicy._getSigningHash(_startDate, _maturationDate, _asset, _limit, _offchainDataHash);
    }

    /**
     * @dev Calculate the policy premium fees based on a buy amount.
     * @param _premiumPaid The amount that the fees payments are calculated from.
     * @return cf CalculatedFees struct
     */
    function calculatePremiumFees(bytes32 _policyId, uint256 _premiumPaid) external view returns (CalculatedFees memory cf) {
        cf = LibFeeRouter._calculatePremiumFees(_policyId, _premiumPaid);
    }
}
