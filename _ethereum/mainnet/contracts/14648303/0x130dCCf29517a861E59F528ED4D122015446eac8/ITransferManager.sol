//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./LibOrder.sol";
import "./ITransferExecutor.sol";

abstract contract ITransferManager is ITransferExecutor{
    function doTransfers(
        LibOrder.Order calldata buy,
        LibOrder.Order calldata sell
    ) internal virtual;
}
