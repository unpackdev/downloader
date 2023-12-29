// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

interface IMinterProxy {
    error InvalidMinter();
    error MinterAlreadyRegistered();
    error MinterNotRegistered(uint32 color);
    error HashExists();
    error HashNotExists();

    event RegisteredMinter(address minter, uint32 color);
    event UnregisteredMinter(address minter, uint32 color);
    event SetToSTBTLp(address toSTBTLp);
    event AddedMinterCodeHash(uint hash);
    event RemovedMinterCodeHash(uint hash);

    function isRegistered(address _addr) external view returns (bool);

    function toSTBTLp() external view returns (address);

    function usdv() external view returns (address);
}
