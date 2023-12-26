// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IEigenPodManager.sol";

interface IRestakerFacets {
    error ZeroAddress();

    enum FuncTarget {
        POD,
        POD_MANAGER,
        DELEGATION_MANAGER
    }

    function selectorToTarget(bytes4 sig) external view returns (address);

    function getEigenPodManager() external view returns (IEigenPodManager);
}
