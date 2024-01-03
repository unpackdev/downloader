// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./FMaker.sol";

contract MakerResolver {
    /// @dev Return Debt in wad of the vault associated to the vaultId.
    function getMakerVaultDebt(uint256 _vaultId) public view returns (uint256) {
        return _getMakerRawVaultDebt(_vaultId);
    }

    /// @dev Return Collateral in wad of the vault associated to the vaultId.
    function getMakerVaultCollateralBalance(uint256 _vaultId)
        public
        view
        returns (uint256)
    {
        return _getMakerVaultCollateralBalance(_vaultId);
    }
}
