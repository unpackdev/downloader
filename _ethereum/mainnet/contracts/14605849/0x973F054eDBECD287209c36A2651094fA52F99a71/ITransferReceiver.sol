//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITransferReceiver {
    function onTokenTransfer(
        address,
        uint256,
        bytes calldata
    ) external returns (bool);
}
