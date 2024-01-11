//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./CountersUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract XanaliaTreasury is Initializable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize (
    ) public initializer {
        __AccessControl_init_unchained();
        // set admin role
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not admin");
    }

    function withdraw(address token, uint256 amount) external restricted {
        uint256 balance = token == address(0x00)
            ? address(this).balance
            : IERC20Upgradeable(token).balanceOf(address(this));
        require(amount <= balance, "Invalid amount");
        if (token == address(0x00)) {
            (bool sent, ) = msg.sender.call{value: amount}("");
            require(sent, "Failed to send Ether");
        } else {
            IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
        }
    }
}
