// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./Math.sol";

import "./AccessControlUpgradeable.sol";

import "./IFeeManager.sol";
import "./IPoolManager.sol";
import "./ISanToken.sol";
import "./IPerpetualManager.sol";
import "./IStableMaster.sol";
import "./IStrategy.sol";

import "./FunctionUtils.sol";

/// @title PoolManagerEvents
/// @author Angle Core Team
/// @notice The `PoolManager` contract corresponds to a collateral pool of the protocol for a stablecoin,
/// it manages a single ERC20 token. It is responsible for interacting with the strategies enabling the protocol
/// to get yield on its collateral
/// @dev This contract contains all the events of the `PoolManager` Contract
contract PoolManagerEvents {
    event FeesDistributed(uint256 amountDistributed);

    event Recovered(address indexed token, address indexed to, uint256 amount);

    event StrategyAdded(address indexed strategy, uint256 debtRatio);

    event StrategyRevoked(address indexed strategy);

    event StrategyReported(
        address indexed strategy,
        uint256 gain,
        uint256 loss,
        uint256 debtPayment,
        uint256 totalDebt
    );
}
