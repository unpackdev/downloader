// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";

contract Token is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant GOV_MANAGER = keccak256("GOV_MANAGER");

    event EmergencyWithdraw(
        address indexed by,
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    modifier onlyGovManager() {
        require(
            hasRole(GOV_MANAGER, _msgSender()),
            "Token.onlyGovManager: only Gov Manager"
        );
        _;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function emergencyWithdraw(
        address _token,
        address _receiver,
        uint256 _amount
    ) external onlyGovManager {
        IERC20(_token).safeTransfer(_receiver, _amount);
        emit EmergencyWithdraw(_msgSender(), _receiver, _token, _amount);
    }
}
