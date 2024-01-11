// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "./AccessControlUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract Margin is AccessControlUpgradeable{
    mapping(string=>address) public orderId;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(address admin) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function deposit(address fromAddr, uint fromAmount) public{
        IERC20Upgradeable(fromAddr).safeTransferFrom(msg.sender,address(this),fromAmount);
    }

    function withdraw(string memory _orderId, address userAddr, address tokenAddr, uint amount) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(orderId[_orderId] == address(0x00), "orderId_repeated");
        IERC20Upgradeable(tokenAddr).safeTransfer(userAddr,amount);
        orderId[_orderId] = userAddr;
    }
}

