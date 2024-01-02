// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20.sol";

contract NpLiquidityHolder is UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    address public token;

    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init(_msgSender());
    }

    function setToken(address _t) external onlyOwner {
        token = _t;
    }

    function getToken(address target, uint256 amount) external {
        require(msg.sender == token || msg.sender == owner(), "NpLiquidityHolder: no perm");
        IERC20(target).safeTransfer(msg.sender, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}