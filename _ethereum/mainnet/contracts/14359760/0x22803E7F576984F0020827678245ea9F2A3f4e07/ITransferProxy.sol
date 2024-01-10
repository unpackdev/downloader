// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./LibAsset.sol";

interface ITransferProxy {
    function transfer(LibAsset.Asset calldata asset, address from, address to) external;
}
