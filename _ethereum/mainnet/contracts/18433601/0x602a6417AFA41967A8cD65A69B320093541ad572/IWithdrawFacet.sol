// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IPermissionsFacet.sol";
import "./IVaultFacet.sol";
import "./ILpTokenFacet.sol";
import "./ILockFacet.sol";

interface IWithdrawFacet {
    function withdraw(
        uint256 lpAmount,
        uint256[] memory minTokenAmounts
    ) external returns (uint256[] memory tokenAmounts);

    function withdrawInitialized() external view returns (bool);

    function withdrawSelectors() external view returns (bytes4[] memory selectors_);
}
