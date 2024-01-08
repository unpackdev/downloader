// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IResetAccountConnector.sol";
import "./FoldingAccountStorage.sol";
import "./StopLossStorage.sol";

contract ResetAccountConnector is IResetAccountConnector, FoldingAccountStorage, StopLossStorage {
    function resetAccount(
        address oldOwner,
        address newOwner,
        uint256
    ) external override onlyNFTContract {
        emit OwnerChanged(aStore().owner, newOwner);
        aStore().owner = newOwner;
        if (oldOwner != address(0)) {
            StopLossStore storage store = stopLossStore();
            store.unwindFactor = 0;
            store.slippageIncentive = 0;
            store.collateralUsageLimit = 0;
        }
    }
}
