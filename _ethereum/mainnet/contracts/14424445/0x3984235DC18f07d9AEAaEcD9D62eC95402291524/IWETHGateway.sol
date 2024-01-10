// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IWETHGateway {
    function depositETH(address onBehalfOf, uint16 referralCode)
        external
        payable;
}
