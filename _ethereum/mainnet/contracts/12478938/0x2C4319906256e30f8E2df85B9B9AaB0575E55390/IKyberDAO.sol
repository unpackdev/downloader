pragma solidity 0.6.2;

interface IKyberDAO {
    function submitVote(uint256 proposalId, uint256 optionBitMask) external;
}
