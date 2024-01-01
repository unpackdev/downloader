// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IOracle.sol";
import "./IPermissionsFacet.sol";
import "./ITokensManagementFacet.sol";

import "./LpToken.sol";

interface IVaultFacet {
    struct Storage {
        bytes securityParams;
        IOracle oracle;
        address[] tokens;
        uint256 proxyTokensMask;
    }

    function initializeVaultFacet(
        address[] memory tokensInOrderOfDifficulty_,
        uint256 proxyTokensMask_,
        IOracle oracle_,
        bytes[] calldata securityParams
    ) external;

    function updateSecurityParams(bytes[] calldata securityParams) external;

    function updateOracle(IOracle newOracle) external;

    function tvl() external view returns (uint256);

    function quote(address[] memory, uint256[] memory) external view returns (uint256);

    function tokens() external view returns (address[] memory);

    function proxyTokensMask() external view returns (uint256);

    function getTokensAndAmounts() external view returns (address[] memory, uint256[] memory);

    function oracle() external view returns (IOracle);

    function securityParams() external view returns (bytes[] memory);

    function vaultInitialized() external view returns (bool);

    function vaultSelectors() external view returns (bytes4[] memory selectors_);
}
