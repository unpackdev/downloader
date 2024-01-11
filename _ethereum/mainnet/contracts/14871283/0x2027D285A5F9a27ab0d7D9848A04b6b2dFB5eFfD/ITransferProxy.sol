// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AssetLib.sol";

interface ITransferProxy {
    function transfer(
        AssetLib.AssetData calldata asset,
        address from,
        address to
    ) external;
}
