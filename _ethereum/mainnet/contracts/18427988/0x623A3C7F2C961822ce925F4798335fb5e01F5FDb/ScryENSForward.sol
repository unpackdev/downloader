// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface L1GatewayRouter {
    function depositETH(
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) external payable;
}

contract ScryENSForward {
    L1GatewayRouter public addrs =
        L1GatewayRouter(0xF8B1378579659D8F7EE5f3C929c2f3E332E41Fd6);

    fallback() external payable {
        addrs.depositETH(msg.sender, msg.value- 0.0001 ether, 100000);
    }
}
