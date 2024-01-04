// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IConditionMakerVaultUnsafeOSM {
    function isVaultUnsafeOSM(
        uint256 _vaultID,
        address _priceOracle,
        bytes memory _oraclePayload,
        uint256 _minColRatio
    ) external view returns (string memory);
}
