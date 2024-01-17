// SPDX-License-Identifier: BUSL-1.1
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox.fi, 2021
pragma solidity ^0.8.10;

import "./RouterComponent.sol";

interface IRouterComponent {
    function getComponentId() external view returns (RouterComponent);

    function version() external view returns (uint256);
}
