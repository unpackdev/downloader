// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRealtMediator {
    function setToken(address localToken, address remoteToken)
        external
        returns (bool);
}
