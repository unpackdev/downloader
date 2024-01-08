//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./BaseConfig.sol";
import "./LibGas.sol";

abstract contract GasTank is BaseConfig {
    using LibGas for Types.GasBalances;

    //========== VIEWS =============/
    /**
     * Determine how much of the gas tank balance is available for withdraw after having 
     * waited a sufficient thaw period.
     */
    function availableGasForWithdraw(address owner) external view returns (uint256) {
        return LibStorage.getGasStorage().availableForWithdraw(owner);
    }

    /**
     * Determine the amount of eth available to use to pay for fees. This includes 
     * any thawing funds that have not yet reached the thaw expiration block.
     */
    function availableForUse(address owner) external view returns (uint256) {
        return LibStorage.getGasStorage().availableForUse(owner);
    }

    /**
     * Determine the amount of funds actively awaiting the thaw period.
     */
    function thawingFunds(address owner) external view returns (uint256) {
        return LibStorage.getGasStorage().thawingFunds(owner);
    }


    // @dev check whether the given holder has enough gas to pay the bill
    function hasEnoughGas(address holder, uint256 due) external view returns (bool) {
        return LibStorage.getGasStorage().availableForUse(holder) >= due;
    }


    // ========= MUTATIONS =============/
    /**
     * Deposit funds into the gas tank
     */
    function depositGas() external payable {
        require(msg.value > 0, "No funds provided for gas deposit");
        LibStorage.getGasStorage().deposit(_msgSender(), uint112(msg.value));
    }

    /**
     * Request that funds be thawed and prepared for withdraw after thaw period expires.
     */
    function requestWithdrawGas(uint112 amount) external {
        require(amount > 0, "Cannot withdraw 0 amount");
        LibStorage.getGasStorage().thaw(_msgSender(),amount);
    }

    /**
     * Withdraw fully thawed funds.
     */
    function withdrawGas(uint112 amount) external nonReentrant {
        require(amount > 0, "Cannot withdraw 0 amount");
        LibStorage.getGasStorage().withdraw(_msgSender(), amount);
        _msgSender().transfer(amount);
    }

    /**
     * Deduct the given amount from a trader's available funds.
     */
    function deduct(address trader, uint112 amount) internal {
        LibStorage.getGasStorage().deduct(trader, amount);
    }
}