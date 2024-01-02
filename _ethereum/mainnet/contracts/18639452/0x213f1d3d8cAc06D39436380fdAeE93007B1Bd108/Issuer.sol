pragma solidity ^0.8.20;

interface Issuer {
    function collateralisationRatio(address issuer) external view returns (uint);

    function debtBalanceOf(address _issuer, bytes32 currencyKey) external view returns (uint256);

    function maxIssuableSynths(address _issuer) external view returns (uint);
}