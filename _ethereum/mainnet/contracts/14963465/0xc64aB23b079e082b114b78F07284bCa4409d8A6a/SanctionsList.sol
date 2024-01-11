pragma solidity ^0.8.14;

/// Integrating Chainalysis sanction list https://go.chainalysis.com/chainalysis-oracle-docs.html
interface SanctionsList {
    function isSanctioned(address _addr) external view returns (bool);
}