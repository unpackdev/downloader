//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./BaseConfig.sol";
import "./LibGas.sol";

abstract contract GasTank is BaseConfig {
    using LibGas for Types.GasBalances;

    //========== VIEWS =============/
    function availableGasForWithdraw(address owner) external view returns (uint256) {
        return LibStorage.getGasStorage().availableForWithdraw(owner);
    }

    function totalGasDeposited(address owner) external view returns (uint256) {
        return LibStorage.getGasStorage().total(owner);
    }

    function totalGasLocked(address owner) external view returns (uint256) {
        return LibStorage.getGasStorage().lockedFunds(owner);
    }


    // @dev check whether the given holder has enough gas to pay the bill
    function hasEnoughGas(address holder, uint256 due) external view returns (bool) {
        return LibStorage.getGasStorage().total(holder) >= due;
    }


    // ========= MUTATIONS =============/
    function depositGas() external payable {
        require(msg.value > 0, "No funds provided for gas deposit");
        LibStorage.getGasStorage().deposit(_msgSender(), uint112(msg.value));
    }

    function requestWithdrawGas(uint112 amount) external {
        require(amount > 0, "Cannot withdraw 0 amount");
        LibStorage.getGasStorage().lock(_msgSender(),amount);
    }

    function withdrawGas(uint112 amount) external nonReentrant {
        require(amount > 0, "Cannot withdraw 0 amount");
        LibStorage.getGasStorage().withdraw(_msgSender(), amount);
        _msgSender().transfer(amount);
    }

    function deduct(address trader, uint112 amount) internal {
        LibStorage.getGasStorage().deduct(trader, amount);
    }
}