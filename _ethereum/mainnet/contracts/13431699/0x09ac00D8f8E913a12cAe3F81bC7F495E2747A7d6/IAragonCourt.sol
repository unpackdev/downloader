// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

import "./IERC20.sol";

interface IAragonCourt {
    function createDispute(uint256 _possibleRulings, bytes calldata _metadata) external returns (uint256);
    function submitEvidence(uint256 _disputeId, address _submitter, bytes calldata _evidence) external;
    function rule(uint256 _disputeId) external returns (address subject, uint256 ruling);
    function getDisputeFees() external view returns (address recipient, IERC20 feeToken, uint256 feeAmount);
    function closeEvidencePeriod(uint256 _disputeId) external;
}