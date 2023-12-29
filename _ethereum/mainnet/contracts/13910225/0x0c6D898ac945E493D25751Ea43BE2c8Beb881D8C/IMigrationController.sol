//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

import "./IStrategy.sol";
import "./IStrategyRouter.sol";
import "./IAdapter.sol";
import "./SafeERC20Transfer.sol";

interface IMigrationController {
    function migrate(
        IStrategy strategy,
        IStrategyRouter genericRouter,
        IERC20 lpToken,
        IAdapter adapter,
        uint256 amount
    ) external;

    function initialized(address strategy) external view returns (bool);
}
