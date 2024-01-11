//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

abstract contract ITransferExecutor {
    function transfer(
        address token,
        address from,
        address to,
        uint value
    ) internal virtual;
}
