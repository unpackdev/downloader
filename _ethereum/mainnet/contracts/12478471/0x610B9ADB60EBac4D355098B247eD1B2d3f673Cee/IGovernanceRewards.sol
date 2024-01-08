pragma solidity 0.6.2;

// https://etherscan.io/address/0x0f85a912448279111694f4ba4f85dc641c54b594#writeContract
interface IGovernanceRewards {
    function getReward() external;
    function earned(address account) external view returns (uint256);
}