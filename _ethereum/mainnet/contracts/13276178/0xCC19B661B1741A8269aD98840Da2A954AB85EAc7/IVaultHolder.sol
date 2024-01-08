pragma solidity 0.8.4;

interface IVaultHolder {
    function harvest(uint256 vaultId) external;
    function vaultCount() external view returns (uint256);
    function getVaultAdapter(uint256 vaultId) external view returns (address);
    function getVaultTotalDeposited(uint256 vaultId) external view returns (uint256);
}