pragma solidity ^0.6.12;

interface IObelixFarming {
    function estimateOBELIXProvidedWithStartTimestamp(address _staker) external view returns (uint256, uint256);
}
