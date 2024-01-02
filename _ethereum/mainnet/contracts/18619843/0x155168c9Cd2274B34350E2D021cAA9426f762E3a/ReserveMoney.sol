// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./AccessControlEnumerable.sol";

contract ReserveMoney is AccessControlEnumerable {
    // 7b765e0e932d348852a6f810bfa1ab891e259123f02db8cdcde614c570223357
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    uint256 public strictTill;

    event StrictTillSet(uint256 strictTill);
    event TransferETH(address indexed to, uint256 amount);
    event DepositETH(uint256 amount);

    constructor () {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTROLLER_ROLE, msg.sender);
    }

    receive() external payable {
        emit DepositETH(msg.value);
    }

    modifier onlyControllerOrAdmin() {
        require((
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
            ||
            (block.timestamp > strictTill && hasRole(CONTROLLER_ROLE, msg.sender))
        ),
            "Access denied");
        _;
    }

    function setStrictTill(uint256 _strictTill) external onlyControllerOrAdmin {
        require(_strictTill > block.timestamp, "Strict till must be in the future");
        require(_strictTill < block.timestamp + 365 days, "Strict till must be less than 1 year");
        strictTill = _strictTill;
        emit StrictTillSet(_strictTill);
    }

    function transferETH(address payable to, uint256 amount) external onlyControllerOrAdmin {
        to.transfer(amount);
        emit TransferETH(to, amount);
    }

    function transferERC20(address token, address to, uint256 amount) external onlyControllerOrAdmin {
        IERC20(token).transfer(to, amount);
    }

    function anyCall(address payable to, uint256 value, bytes calldata data) external onlyControllerOrAdmin {
        (bool success, ) = to.call{value: value}(data);
        require(success, "Call failed");
    }
}