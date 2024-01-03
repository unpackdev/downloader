// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IStrategy.sol";

/*
This is a "placeholder" strategy used during emergency shutdown
*/
contract StrategyNoOp is IStrategy {
    using SafeERC20 for IERC20;

    address public override admin;
    address public override controller;
    address public override vault;
    address public override underlying;

    uint public override totalDebt;
    uint public override performanceFee;

    mapping(address => bool) public override assets;

    constructor(
        address _controller,
        address _vault,
        address _underlying
    ) public {
        require(_controller != address(0), "controller = zero address");
        require(_vault != address(0), "vault = zero address");
        require(_underlying != address(0), "underlying = zero address");

        admin = msg.sender;
        controller = _controller;
        vault = _vault;
        underlying = _underlying;

        assets[underlying] = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "!admin");
        _;
    }

    function setAdmin(address _admin) external override onlyAdmin {
        require(_admin != address(0), "admin = zero address");
        admin = _admin;
    }

    // @dev variable name is removed to silence compiler warning
    function setController(address) external override {
        revert("no-op");
    }

    // @dev variable name is removed to silence compiler warning
    function setPerformanceFee(uint) external override {
        revert("no-op");
    }

    function totalAssets() external view override returns (uint) {
        return 0;
    }

    // @dev variable name is removed to silence compiler warning
    function deposit(uint) external override {
        revert("no-op");
    }

    // @dev variable name is removed to silence compiler warning
    function withdraw(uint) external override {
        revert("no-op");
    }

    function withdrawAll() external override {
        revert("no-op");
    }

    function harvest() external override {
        revert("no-op");
    }

    function skim() external override {
        revert("no-op");
    }

    function exit() external override {
        // left as blank so that Vault can call exit() during Vault.setStrategy()
    }

    function sweep(address _token) external override onlyAdmin {
        require(!assets[_token], "asset");
        IERC20(_token).safeTransfer(admin, IERC20(_token).balanceOf(address(this)));
    }
}
