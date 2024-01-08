// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./Errors.sol";
import "./IOwnable.sol";
import "./IBentPool.sol";
import "./IBentPoolManager.sol";
import "./IConvexBooster.sol";
import "./IBaseRewardPool.sol";
import "./IConvexToken.sol";
import "./IVirtualBalanceRewardPool.sol";
import "./BentBasePoolUpgradeable.sol";

contract BentBasePool is BentBasePoolUpgradeable {
    constructor(
        address _poolManager,
        string memory _name,
        uint256 _cvxPoolId,
        address[] memory _extraRewardTokens,
        uint256 _windowLength // around 7 days
    ) {
        initialize(
            _poolManager,
            _name,
            _cvxPoolId,
            _extraRewardTokens,
            _windowLength
        );
    }
}
