// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IVault {
    function getBeneficiary() external view returns (address);

    function mintKey(uint256 keyId) external;

    function vaultKeyId() external view returns (uint256);
}
