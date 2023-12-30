pragma solidity ^0.5.16;

import "./IAssetVotingWeightProvider.sol";
import "./IERC20.sol";

interface IGovernanceParamsProvider {
    function setPropositionPowerThreshold(uint256 _propositionPowerThreshold) external;
    function setPropositionPower(IERC20 _propositionPower) external;
    function setAssetVotingWeightProvider(IAssetVotingWeightProvider _assetVotingWeightProvider) external;
    function getPropositionPower() external view returns(IERC20);
    function getPropositionPowerThreshold() external view returns(uint256);
    function getAssetVotingWeightProvider() external view returns(IAssetVotingWeightProvider);
}