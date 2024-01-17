/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IERC20.sol";

import "./ITradeExecutor.sol";
import "./IVault.sol";

abstract contract BaseTradeExecutor is ITradeExecutor {
    uint256 internal constant MAX_INT = type(uint256).max;

    address public override vault;

    constructor(address _vault) {
        vault = _vault;
        IERC20(vaultWantToken()).approve(vault, MAX_INT);
    }

    function vaultWantToken() public view returns (address) {
        return IVault(vault).wantToken();
    }

    function governance() public view returns (address) {
        return IVault(vault).governance();
    }

    function keeper() public view returns (address) {
        return IVault(vault).keeper();
    }

    /// @notice restrict access to only governance
    modifier onlyGovernance() {
        require(msg.sender == governance(), "ONLY_GOV");
        _;
    }

    /// @notice restrict access to only keeper
    modifier onlyKeeper() {
        require(msg.sender == keeper(), "ONLY_KEEPER");
        _;
    }

    /// @notice restrict access to only vault
    modifier onlyVault() {
        require(msg.sender == vault, "ONLY_VAULT");
        _;
    }

    modifier keeperOrGovernance() {
        require(
            msg.sender == keeper() || msg.sender == governance(),
            "ONLY_KEEPER_OR_GOVERNANCE"
        );
        _;
    }

    function sweep(address _token) public onlyGovernance {
        IERC20(_token).transfer(
            governance(),
            IERC20(_token).balanceOf(address(this))
        );
    }


}
