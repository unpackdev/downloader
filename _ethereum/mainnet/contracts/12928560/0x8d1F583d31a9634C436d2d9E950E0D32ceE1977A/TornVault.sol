// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";

/// @title Vault which holds user funds
contract TornVault {
    using SafeERC20 for IERC20;

    address public governance =
        address(0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce);
    address public constant tornTokenAddress =
        address(0x77777FeDdddFfC19Ff86DB637967013e6C6A116C);

    /// @notice withdraws TORN from the contract
    /// @param amount amount to withdraw
    /// @return returns true on success
    function withdrawTorn(uint256 amount) external returns (bool) {
        require(msg.sender == governance, "only gov");
        IERC20(tornTokenAddress).safeTransfer(governance, amount);
        return true;
    }

    /// @notice upgrades contract governance address
    /// @dev upgradeability function just-in-case of a governance proxy switch if there ever will be one
    /// @param _governance new governance address
    /// @return true on success of setting new governance
    function setGovernance(address _governance) external returns (bool) {
        require(msg.sender == governance, "only gov");
        governance = _governance;
        return true;
    }
}
