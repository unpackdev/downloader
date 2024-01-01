// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "EnumerableSet.sol";
import "IERC20.sol";
import "SafeERC20.sol";

import "IReserve.sol";
import "EnumerableExtensions.sol";
import "GovernableUpgradeable.sol";

/// @notice all the Gyroscope reserve funds are stored in this address
contract Reserve is IReserve, GovernableUpgradeable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _managers;

    modifier managerOnly() {
        require(_managers.contains(msg.sender), Errors.NOT_AUTHORIZED);
        _;
    }

    /// @inheritdoc IReserve
    function addManager(address manager) external override governanceOnly {
        require(_managers.add(manager), Errors.INVALID_ARGUMENT);
        emit ManagerAdded(manager);
    }

    /// @inheritdoc IReserve
    function removeManager(address manager) external override governanceOnly {
        require(_managers.remove(manager), Errors.INVALID_ARGUMENT);
        emit ManagerRemoved(manager);
    }

    /// @inheritdoc IReserve
    function managers() external view returns (address[] memory) {
        return _managers.values();
    }

    /// @inheritdoc IReserve
    function depositToken(address token, uint256 amount) external override {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, token, amount);
    }

    /// @inheritdoc IReserve
    function withdrawToken(address token, uint256 amount) external override managerOnly {
        IERC20(token).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, token, amount);
    }
}
