// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

interface IEscrowDisputeManager {
    function proposeSettlement(
        bytes32 _cid,
        uint16 _index,
        address _plaintiff,
        address _payer,
        address _payee,
        uint _refundedPercent,
        uint _releasedPercent,
        bytes32 _statement
    ) external;

    function acceptSettlement(bytes32 _cid, uint16 _index, uint256 _ruling) external;

    function disputeSettlement(
        address _feePayer,
        bytes32 _cid,
        uint16 _index,
        bytes32 _termsCid,
        bool _ignoreCoverage,
        bool _multiMilestone
    ) external;

    function executeSettlement(bytes32 _cid, uint16 _index, bytes32 _mid) external returns(uint256, uint256, uint256);
    function getSettlementByRuling(bytes32 _mid, uint256 _ruling) external returns(uint256, uint256, uint256); 

    function submitEvidence(address _from, string memory _label, bytes32 _cid, uint16 _index, bytes calldata _evidence) external;
    function ruleDispute(bytes32 _cid, uint16 _index, bytes32 _mid) external returns(uint256);
    
    function resolutions(bytes32 _mid) external view returns(uint256);
    function hasSettlementDispute(bytes32 _mid) external view returns(bool);
    function ARBITER() external view returns(address);
}