// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./IDCSEntry.sol";
import "./ITreasury.sol";

contract RevertingDepositor {
    IDCSEntry public dcsEntry;

    constructor(IDCSEntry _dcsEntry) {
        dcsEntry = _dcsEntry;
    }

    receive() external payable {
        revert("Receive disabled");
    }

    function deposit(uint32 productId, uint128 amount) external payable {
        dcsEntry.dcsAddToDepositQueue{ value: msg.value }(
            productId,
            amount,
            address(this)
        );
    }

    function withdraw(
        address vault,
        uint128 sharesAmount,
        uint32 nextProductId
    ) external {
        dcsEntry.dcsAddToWithdrawalQueue(vault, sharesAmount, nextProductId);
    }

    function withdrawStuckAssets(
        ITreasury treasury,
        address receiver
    ) external {
        treasury.withdrawStuckAssets(address(0), receiver);
    }
}
