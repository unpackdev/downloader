// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./OpynVault.sol";

interface IGammaOperator {
    function isValidVaultId(address _owner, uint256 _vaultId)
        external
        view
        returns (bool);

    function getExcessCollateral(
        MarginVault.Vault memory _vault,
        uint256 _typeVault
    ) external view returns (uint256, bool);

    function getVaultOtoken(MarginVault.Vault memory _vault)
        external
        pure
        returns (address);

    function getVaultWithDetails(address _owner, uint256 _vaultId)
        external
        view
        returns (
            MarginVault.Vault memory,
            uint256,
            uint256
        );

    function isSettlementAllowed(address _otoken) external view returns (bool);

    function isOperatorOf(address _owner) external view returns (bool);

    function hasExpiredAndSettlementAllowed(address _otoken)
        external
        view
        returns (bool);
}
