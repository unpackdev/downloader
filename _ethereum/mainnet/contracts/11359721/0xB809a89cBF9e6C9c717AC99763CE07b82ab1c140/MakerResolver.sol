// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./FMaker.sol";

contract MakerResolver {
    /// @dev Return Debt in wad of the vault associated to the vaultId.
    function getMakerVaultRawDebt(uint256 _vaultId)
        public
        view
        returns (uint256)
    {
        return _getMakerRawVaultDebt(_vaultId);
    }

    function getMakerVaultDebt(uint256 _vaultId) public view returns (uint256) {
        return _getMakerVaultDebt(_vaultId);
    }

    /// @dev Return Collateral in wad of the vault associated to the vaultId.
    function getMakerVaultCollateralBalance(uint256 _vaultId)
        public
        view
        returns (uint256)
    {
        return _getMakerVaultCollateralBalance(_vaultId);
    }

    function vaultWillBeSafe(
        uint256 _vaultId,
        uint256 _amtToBorrow,
        uint256 _colToDeposit
    ) public view returns (bool) {
        return _vaultWillBeSafe(_vaultId, _amtToBorrow, _colToDeposit);
    }

    function newVaultWillBeSafe(
        string memory _colType,
        uint256 _amtToBorrow,
        uint256 _colToDeposit
    ) public view returns (bool) {
        return _newVaultWillBeSafe(_colType, _amtToBorrow, _colToDeposit);
    }
}
