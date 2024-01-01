// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IPermissionsFacet.sol";
import "./LpToken.sol";

interface ILpTokenFacet {
    struct Storage {
        LpToken lpToken;
    }

    function initializeLpTokenFacet(LpToken singleton, string memory name, string memory symbol) external;

    function lpToken() external view returns (LpToken);

    function lpTokenInitialized() external view returns (bool);

    function lpTokenSelectors() external view returns (bytes4[] memory selectors_);
}
