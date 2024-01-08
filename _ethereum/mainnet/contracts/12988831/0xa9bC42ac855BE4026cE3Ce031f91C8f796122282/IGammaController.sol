// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./OpynActions.sol";
import "./OpynVault.sol";

interface IGammaController {
    function operate(Actions.ActionArgs[] memory _actions) external;

    function isSettlementAllowed(address _otoken) external view returns (bool);

    function isOperator(address _owner, address _operator)
        external
        view
        returns (bool);

    function getPayout(address _otoken, uint256 _amount)
        external
        view
        returns (uint256);

    function getVaultWithDetails(address _owner, uint256 _vaultId)
        external
        view
        returns (
            MarginVault.Vault memory,
            uint256,
            uint256
        );

    function getAccountVaultCounter(address _accountOwner)
        external
        view
        returns (uint256);
}
