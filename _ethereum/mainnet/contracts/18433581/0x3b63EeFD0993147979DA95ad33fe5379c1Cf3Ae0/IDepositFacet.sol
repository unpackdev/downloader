// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeERC20.sol";

import "./ILockFacet.sol";
import "./IVaultFacet.sol";
import "./ILpTokenFacet.sol";
import "./ITokensManagementFacet.sol";

interface IDepositFacet {
    function deposit(
        uint256[] calldata tokenAmounts,
        uint256 minLpAmount
    ) external returns (uint256 lpAmount, uint256[] memory actualTokenAmounts);

    function depositInitialized() external pure returns (bool);

    function depositSelectors() external pure returns (bytes4[] memory selectors_);
}
