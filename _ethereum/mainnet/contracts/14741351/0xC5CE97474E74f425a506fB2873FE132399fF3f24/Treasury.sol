// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./Context.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IManager.sol";

import "./TransferHelper.sol";

contract Treasury is Context {
    IManager public manager;

    modifier onlyAdmin() {
        require(manager.isAdmin(_msgSender()), "Pool::onlyAdmin");
        _;
    }

    modifier onlyGovernance() {
        require(manager.isGorvernance(_msgSender()), "Pool::onlyGovernance");
        _;
    }

    constructor(address _manager) {
        manager = IManager(_manager);
    }

    function transfer(
        address token,
        address to,
        uint256 amount
    ) public onlyAdmin {
        TransferHelper.safeTransfer(token, to, amount);
    }

    function transferNative(address to, uint256 value) public onlyAdmin {
        TransferHelper.safeTransferNative(to, value);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}
